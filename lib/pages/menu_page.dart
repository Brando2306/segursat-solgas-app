import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/features/route/presentation/providers/route_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/menu_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/providers/route.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/shared/loading_item_widget.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    await menuProvider.init();

    if (!mounted) return;

    if (menuProvider.hasPendingRoute && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showRecoverRouteDialog(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    final inspectionEnabled = menuProvider.buttonInspectionEnabled;
    final rootEnabled = menuProvider.buttonRootEnabled;
    final isLoading = inspectionEnabled == null || rootEnabled == null;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? LoadingItem(height: getHeight(context, 7))
                  : _buildMenuButton(
                      context,
                      'Inspección de unidad',
                      '/inspection/question',
                      inspectionEnabled,
                    ),
              SizedBox(height: getHeight(context, 3)),
              isLoading
                  ? LoadingItem(height: getHeight(context, 7))
                  : _buildMenuButton(
                      context,
                      'Iniciar una ruta',
                      '/root/selectSource',
                      rootEnabled,
                    ),
              SizedBox(height: getHeight(context, 3)),
              isLoading
                  ? LoadingItem(height: getHeight(context, 7))
                  : _buildMenuButton(
                      context,
                      'Registrar mantenimiento',
                      '/maintance/odometer',
                      true,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecoverRouteDialog(BuildContext context) {
    notificationInfoWithoutWillPopScope(
      context: context,
      onWillPop: true,
      barrierDismissible: true,
      content: 'Tienes una ruta activa en curso.\n¿Deseas recuperar la ruta?',
      callBack: () async {
        final navigatorContext = Navigator.of(context).context;
        if (mounted) {
          Provider.of<MenuProvider>(navigatorContext, listen: false)
              .clearPendingRoute();

          bool validation = await checkGps();

          if (validation) {
            await writeStorage('personal.pushRouteSpeedometer', true);
            await _resumeRouteFlow(navigatorContext);
          } else {
            await writeStorage('sesionPageValidation', true);
            // Mostrar diálogo de ubicación usando navigatorContext
          }
        }
      },
    );
  }

  Future<void> _resumeRouteFlow(BuildContext context) async {
    try {
      EasyLoading.show(status: 'Verificando GPS...');
      final validationGps = await checkGps();
      EasyLoading.dismiss();

      if (!validationGps) {
        await writeStorage('sesionPageValidation', true);
        // Mostrar diálogo para activar ubicación
        // Puedes mostrar un diálogo para activar ubicación aquí si lo deseas
        return;
      }

      EasyLoading.show(status: 'Redireccionando...');

      // 1. Primero intentar con el backend si hay lastRoute
      final lastRoute = readStorage('personal.lastRoute');
      if (lastRoute != null) {
        try {
          // Debes tener una función getRoute similar a la de RouteProvider
          // final route = await getRoute(lastRoute);
          final routeProvider =
              Provider.of<RouteProvider>(context, listen: false);
          final route = await routeProvider.getRoute(
            lastRoute is int ? lastRoute : int.parse(lastRoute.toString()),
          );

          await _handleBackendRouteResponse(route);
          EasyLoading.dismiss();
          Navigator.pushNamed(context, '/root/speedometer');
          return;
        } catch (e) {
          // log('Error al recuperar ruta del backend: $e');
          EasyLoading.show(status: 'Modo offline activado');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // 2. Lógica offline
      final success = await _handleOfflineRoute();
      EasyLoading.dismiss();

      if (success) {
        Navigator.pushNamed(context, '/root/speedometer');
      } else {
        // await _showRouteRecoveryError(context);
        // cleanAll();
      }
    } catch (e) {
      // cleanAll();
      await _handleOfflineRoute();
      Navigator.pushNamed(context, '/menu');
    }
  }

  Future<void> _handleBackendRouteResponse(dynamic route) async {
    if (route['status'] == STATUSCODE.OK) {
      final positions = route['positions'];
      if (isNotEmptyString(positions)) {
        final lastObject = positions.last;
        await writeStorage('root.cronometer',
            isNotEmptyString(lastObject['angle']) ? lastObject['angle'] : 0);
      }

      if (isNotEmptyString(route['destination_latitude']) &&
          isNotEmptyString(route['destination_longitude'])) {
        await writeStorage(
            'root.finalPosition',
            json.encode({
              'latitude': route['destination_latitude'],
              'longitude': route['destination_longitude']
            }));
        await writeStorage('personal.pushRouteSpeedometer', null);
      }
    }
  }

  Future<bool> _handleOfflineRoute() async {
    try {
      // 1. Verificar posición final (obligatoria)
      final finalPos = readStorage('root.finalPosition');
      if (finalPos == null) {
        // log('No hay posición final guardada');
        return false;
      }

      // 2. Obtener posición actual (intentar GPS o usar última guardada)
      if (readStorage('root.currentPosition') == null) {
        try {
          final position = await Geolocator.getCurrentPosition();
          await writeStorage(
              'root.currentPosition',
              json.encode({
                'latitude': position.latitude,
                'longitude': position.longitude
              }));
        } catch (e) {
          // log('No se pudo obtener posición actual: $e');
          return false;
        }
      }

      var cronometer = readStorage('root.cronometer');
      log('Cronómetro inicial: $cronometer');

      // 3. Inicializar cronómetro si no existe
      if (readStorage('root.cronometer') == null) {
        await writeStorage('root.cronometer', '0');
      }

      // 4. Verificar si hay una ruta offline activa
      // final offlineRouteId = readStorage(StorageKeys.currentOfflineRouteId);
      // if (offlineRouteId == null) {
      //   // Crear nueva ruta offline si no existe
      //   await _createOfflineRoute();
      // }

      return true;
    } catch (e) {
      // log('Error en _handleOfflineRoute: $e');
      return false;
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(MENU.TEXT_HEADER, style: TextStyle(color: Colors.black)),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => _logout(context),
        icon: Icon(Icons.logout),
        color: Colors.black,
        tooltip: 'Salir de la sesión',
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/offlineOperations'),
          icon: Icon(Icons.wifi_off_outlined),
          color: Colors.black,
          tooltip: 'Operaciones Offline',
        ),
      ],
    );
  }

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    cleanAll();
    Navigator.pushNamed(context, '/sesion');
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    String route,
    bool enabled,
  ) {
    return Center(
      child: SizedBox(
        child: ButtonWidget(
          width: double.infinity,
          onPressed: enabled ? () => Navigator.pushNamed(context, route) : null,
          color: enabled ? CustomColors.primary : CustomColors.primaryOff,
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
