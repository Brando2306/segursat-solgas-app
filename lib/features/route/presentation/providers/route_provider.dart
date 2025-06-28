import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/providers/route.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';

class RouteProvider with ChangeNotifier {
  final RouteRepository routeRepository;
  final OfflineOperationsRepository offlineRepo;
  final Connectivity connectivity;

  RouteProvider({
    required this.routeRepository,
    required this.offlineRepo,
    required this.connectivity,
  });

  Future<bool> checkPendingRoute() async {
    // 1. Verificar marca de recuperación en storage
    if (readStorage('personal.pushRouteSpeedometer') != null) return true;

    // 2. Verificar estado de última ruta
    final lastRouteStatus = readStorage('personal.lastRouteStatus');
    final lastRouteId = readStorage('personal.lastRoute');

    if (lastRouteStatus == 'running' && lastRouteId != null) {
      return true;
    }

    // 3. Verificar online
    try {
      final hasInternet =
          await connectivity.checkConnectivity() != ConnectivityResult.none;
      if (hasInternet) {
        final lastRoute = await routeRepository.getLastActiveRoute();
        return lastRoute.status == SESION.RUNNING;
      }
    } catch (e) {
      // 4. Verificar offline
      // return await offlineRepo.hasPendingRouteOperation();
    }

    return false;
  }

  Future<void> handleAppResumed(BuildContext context) async {
    if (readStorage('sesionPageValidation') != null) {
      await resumeRouteFlow(context);
    }
  }

  Future<void> resumeRouteFlow(BuildContext context) async {
    try {
      if (readStorage('personal.pushRouteSpeedometer') != null) {
        EasyLoading.show(status: 'Verificando GPS...');
        final validationGps = await checkGps();
        EasyLoading.dismiss();

        if (validationGps) {
          EasyLoading.show(status: 'Redireccionando...');
          final lastRoute = readStorage('personal.lastRoute');
          final route = await getRoute(lastRoute);

          if (route['status'] == STATUSCODE.OK) {
            final positions = route['positions'];
            if (isNotEmptyString(positions)) {
              final lastObject = positions.last;
              if (isNotEmptyString(lastObject) &&
                  isNotEmptyString(lastObject['angle'])) {
                await writeStorage('root.cronometer', lastObject['angle']);
              } else {
                await writeStorage('root.cronometer', 0);
              }
            }

            if (isNotEmptyString(route['destination_latitude']) &&
                isNotEmptyString(route['destination_longitude'])) {
              await writeStorage(
                'root.finalPosition',
                json.encode({
                  'latitude': route['destination_latitude'],
                  'longitude': route['destination_longitude']
                }),
              );
              await writeStorage('personal.pushRouteSpeedometer', null);

              EasyLoading.dismiss();
              Navigator.pushNamed(context, '/root/speedometer');
            } else {
              cleanResumeRoute(); // Debes inyectar/utilizar tu helper aquí
              Navigator.pushNamed(context, '/menu');
            }
          } else {
            cleanResumeRoute();
            Navigator.pushNamed(context, '/menu');
          }
          EasyLoading.dismiss();
        } else {
          await writeStorage('sesionPageValidation', true);
          showLocationSettingsDialog(
              context); // Debes inyectar/utilizar tu helper aquí
        }
      }
    } catch (e) {
      cleanResumeRoute();
      Navigator.pushNamed(context, '/menu');
    }
  }

  void showLocationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ubicación desactivada'),
          content:
              Text('Para usar esta función, necesitas activar la ubicación.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                cleanAll();

                await Navigator.pushNamed(context, '/sesion');
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Navigator.of(context).pop();

                await writeStorage('personal.pushRouteSpeedometer', true);
                await AppSettings.openAppSettings(
                    type: AppSettingsType.location);
              },
              child: Text('Abrir configuración'),
            ),
          ],
        );
      },
    );
  }
}
