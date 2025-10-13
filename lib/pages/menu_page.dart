import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:safe_driving_app/shared/loading_item_widget.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/menu_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/speedometer_provider.dart';

enum MenuActionType { route, inspection, maintenance }

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

    // Snackbars.showSnackbarSuccess(
    //     '🔍 initState - hasPendingRoute: ${menuProvider.hasPendingRoute}, dialogShown: $_dialogShown');
    // log('======🔍 initState - hasPendingRoute: ${menuProvider.hasPendingRoute}, dialogShown: $_dialogShown');

    if (!mounted) return;

    if (menuProvider.hasPendingRoute && !_dialogShown) {
      _dialogShown = true;

      // Snackbars.showSnackbarSuccess(
      //     '🚨 CONDICIÓN CUMPLIDA - Mostrar modal de recuperar ruta');
      // log('======🚨 CONDICIÓN CUMPLIDA - Mostrar modal de recuperar ruta');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Snackbars.showSnackbarSuccess('🔄 PostFrameCallback ejecutado');
          // log('======🔄 PostFrameCallback ejecutado');

          _showRecoverRouteDialog(context);
        }
      });
    }
  }

  // Escuchar cambios en el contador
  void _setupProviderListener() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    menuProvider.addListener(_onMenuProviderChanged);
  }

  void _onMenuProviderChanged() {
    // El contador se actualiza automáticamente cuando el provider notifica cambios
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupProviderListener();
  }

  @override
  void dispose() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    menuProvider.removeListener(_onMenuProviderChanged);
    super.dispose();
  }

  Widget _buildOfflineOperationsButton() {
    final menuProvider = Provider.of<MenuProvider>(context);
    final pendingCount = menuProvider.pendingOperationsCount;

    return Stack(
      children: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/offlineOperations').then((_) {
              // Recargar contador al volver
              menuProvider.refreshPendingOperationsCount();
            });
          },
          icon: Icon(Icons.wifi_off_outlined),
          color: Colors.black,
          tooltip: pendingCount > 0
              ? '$pendingCount operaciones pendientes por sincronizar'
              : 'Operaciones Offline',
        ),
        if (pendingCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                pendingCount > 99 ? '99+' : '$pendingCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    final inspectionEnabled = menuProvider.buttonInspectionEnabled;
    final rootEnabled = menuProvider.buttonRootEnabled;
    final isLoading = inspectionEnabled == null || rootEnabled == null;

    return WillPopScope(
      onWillPop: (() async => false),
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
      onWillPop: false,
      barrierDismissible: false,
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
      callBackDont: () async {
        final navigatorContext = Navigator.of(context).context;

        try {
          EasyLoading.show(status: 'Finalizando ruta...');

          // Reutilizar finishRoute del SpeedometerProvider
          final speedometerProvider =
              Provider.of<SpeedometerProvider>(navigatorContext, listen: false);

          await speedometerProvider.finishRoute();

          EasyLoading.dismiss();

          final menuProvider =
              Provider.of<MenuProvider>(navigatorContext, listen: false);
          menuProvider.clearPendingRoute();

          // Mostrar confirmación
          Snackbars.showSnackbarSuccess('Ruta finalizada correctamente');
        } catch (e) {
          EasyLoading.dismiss();
          if (mounted) {
            notificationError(context, 'Error al finalizar ruta: $e');
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
          // final routeProvider =
          //     Provider.of<RouteProvider>(context, listen: false);
          // final route = await routeProvider.getRoute(
          //   lastRoute is int ? lastRoute : int.parse(lastRoute.toString()),
          // );

          // await _handleBackendRouteResponse(route);
          await writeStorage('personal.pushRouteSpeedometer', null);
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
      // log('Cronómetro inicial: $cronometer');

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
        // _buildOfflineOperationsButton(),
      ],
    );
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?\n'
            'Se eliminarán tus datos locales y deberás iniciar sesión nuevamente.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performLogout(context);
              },
              child: const Text('Sí, cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
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
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    return Center(
      child: SizedBox(
        child: ButtonWidget(
          width: double.infinity,
          onPressed: enabled
              ? () {
                  if (route == '/root/selectSource') {
                    _handleStartRoute(context, menuProvider);
                  } else if (route == '/inspection/question') {
                    _handleStartInspection(context, menuProvider);
                  } else if (route == '/maintance/odometer') {
                    _handleStartMaintenance(context, menuProvider);
                  } else {
                    Navigator.pushNamed(context, route);
                  }
                }
              : null,
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

  Future<bool> _checkInternetInRealTime(BuildContext context) async {
    try {
      EasyLoading.show(status: 'Verificando conexión...');

      // Verificar conectividad del dispositivo
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      if (!hasConnection) {
        EasyLoading.dismiss();
        return false;
      }

      // Verificar si realmente puede alcanzar internet (opcional pero recomendado)
      final canReachInternet = await _canReachInternet();

      EasyLoading.dismiss();
      return canReachInternet;
    } catch (e) {
      EasyLoading.dismiss();
      return false;
    }
  }

  Future<bool> _canReachInternet() async {
    try {
      // Intentar hacer un ping a un servidor confiable
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _handleStartRoute(
      BuildContext context, MenuProvider menuProvider) async {
    final hasInternet = await _checkInternetInRealTime(context);

    if (!hasInternet) {
      _showNoInternetDialog(context, MenuActionType.route);
      return;
    }

    if (!menuProvider.hasInternet) {
      _showNoInternetDialog(context, MenuActionType.route);
      return;
    }

    if (!menuProvider.hasValidInspection) {
      _showInspectionRequiredDialog(context);
      return;
    }

    // Auto-sync pending routes before continuing
    final success = await menuProvider.syncPendingRoutesAndContinue();

    if (success && context.mounted) {
      Navigator.pushNamed(context, '/root/selectSource');
    } else if (!success && context.mounted) {
      // Mostrar diálogo de error de sincronización
      _showSyncErrorDialog(context,
          'No se pudieron sincronizar todas las rutas pendientes. Puedes continuar, pero algunas operaciones quedarán pendientes.');
    }
  }

  void _handleStartInspection(
      BuildContext context, MenuProvider menuProvider) async {
    final hasInternet = await _checkInternetInRealTime(context);

    if (!hasInternet) {
      _showNoInternetDialog(context, MenuActionType.inspection);
      return;
    }

    if (!menuProvider.hasInternet) {
      _showNoInternetDialog(context, MenuActionType.inspection);
    } else {
      Navigator.pushNamed(context, '/inspection/question');
    }
  }

  void _handleStartMaintenance(
      BuildContext context, MenuProvider menuProvider) async {
    final hasInternet = await _checkInternetInRealTime(context);

    if (!hasInternet) {
      _showNoInternetDialog(context, MenuActionType.maintenance);
      return;
    }

    if (!menuProvider.hasInternet) {
      _showNoInternetDialog(context, MenuActionType.maintenance);
    } else {
      Navigator.pushNamed(context, '/maintance/odometer');
    }
  }

  // NUEVO: Diálogo de error de sincronización
  void _showSyncErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sync_problem, color: Colors.orange),
            SizedBox(width: 8),
            Text('Error en sincronización'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continuar de todas formas'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retrySync(context);
            },
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<void> _retrySync(BuildContext context) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final success = await menuProvider.syncPendingRoutesAndContinue();

    if (success && context.mounted) {
      Navigator.pushNamed(context, '/root/selectSource');
    }
  }

  void _showNoInternetDialog(BuildContext context, MenuActionType type) {
    String title = '';
    String requirementText = '';
    String description = '';
    String suggestion = '';

    switch (type) {
      case MenuActionType.route:
        title = 'Iniciar una ruta';
        requirementText = 'Para iniciar una ruta necesitas:';
        description =
            'Sin internet no podemos verificar si tu inspección está al día.';
        suggestion =
            'Conéctate a internet para validar tu inspección y poder iniciar rutas.';
        break;

      case MenuActionType.inspection:
        title = 'Realizar inspección';
        requirementText = 'Para realizar una inspección necesitas:';
        description =
            'Sin conexión a internet no podemos sincronizar tu inspección con el servidor.';
        suggestion =
            'Conéctate a internet para enviar tus resultados correctamente.';
        break;

      case MenuActionType.maintenance:
        title = 'Registrar mantenimiento';
        requirementText = 'Para registrar mantenimiento necesitas:';
        description =
            'Sin internet no podemos guardar tu registro de mantenimiento correctamente.';
        suggestion =
            'Conéctate a internet para validar y registrar el mantenimiento.';
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(requirementText),
            SizedBox(height: 12),
            Text('1. Conexión a internet',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text(suggestion,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryConnection(context, type);
            },
            child: Text('Verificar Ahora'),
          ),
        ],
      ),
    );
  }

  Future<void> _retryConnectionWithInspection(BuildContext context) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    EasyLoading.show(status: 'Verificando inspección...');

    try {
      await menuProvider.init();
      EasyLoading.dismiss();

      if (menuProvider.hasInternet && menuProvider.hasValidInspection) {
        // ¡Perfecto! Tiene internet Y inspección válida
        if (context.mounted) {
          Navigator.pushNamed(context, '/root/selectSource');
        }
      } else if (menuProvider.hasInternet && !menuProvider.hasValidInspection) {
        // Tiene internet pero NO tiene inspección válida
        if (context.mounted) {
          _showInspectionRequiredDialog(context);
        }
      } else {
        // Sigue sin internet
        if (context.mounted) {
          _showNoInternetDialog(context, MenuActionType.route);
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (context.mounted) {
        _showNoInternetDialog(context, MenuActionType.route);
      }
    }
  }

  Future<void> _retryConnection(
      BuildContext context, MenuActionType type) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    EasyLoading.show(status: 'Verificando conexión...');

    try {
      await menuProvider.init();
      EasyLoading.dismiss();

      // ⚠️ IMPORTANTE: verificar si el widget sigue montado antes de usar context
      if (!context.mounted) return;

      if (menuProvider.hasInternet) {
        switch (type) {
          case MenuActionType.route:
            if (menuProvider.hasValidInspection) {
              Navigator.pushNamed(context, '/root/selectSource');
            } else {
              _showInspectionRequiredDialog(context);
            }
            break;

          case MenuActionType.inspection:
            Navigator.pushNamed(context, '/inspection/question');
            break;

          case MenuActionType.maintenance:
            Navigator.pushNamed(context, '/maintance/odometer');
            break;
        }
      } else {
        // ⚠️ Mostrar el nuevo modal solo si sigue montado
        if (context.mounted) {
          _showNoInternetDialog(context, type);
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (context.mounted) {
        _showNoInternetDialog(context, type);
      }
    }
  }

  void _showInspectionRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.car_repair, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('Inspección Requerida'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Debes realizar la inspección diaria antes de iniciar una ruta.'),
            SizedBox(height: 12),
            Text(
              'Por favor, completa la inspección de unidad primero.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/inspection/question');
            },
            child: Text('Realizar Inspección'),
          ),
        ],
      ),
    );
  }
}
