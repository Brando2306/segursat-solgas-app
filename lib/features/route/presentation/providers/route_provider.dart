import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart'
    as entity;
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
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
        return lastRoute.status == entity.RouteStatus.running;
      }
    } catch (e) {
      // 4. Verificar offline
      return await offlineRepo.hasPendingRouteOperation();
    }

    return false;
  }

  Future<entity.Route> resumeRoute(int routeId) async {
    try {
      final route = await routeRepository.resumeRoute(routeId);

      // Guardar datos necesarios para el speedometer
      await writeStorage('personal.pushRouteSpeedometer', true);
      await writeStorage('personal.lastRoute', routeId);

      return route;
    } catch (e) {
      // Guardar operación pendiente
      await offlineRepo.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeRecovery,
          data: {
            'routeId': routeId,
            'action': 'resume',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );
      rethrow;
    }
  }

  Future<void> tryResumePendingRoute(BuildContext context) async {
    final lastRouteId = readStorage('personal.lastRoute');
    if (lastRouteId == null) return;

    final hasInternet =
        await connectivity.checkConnectivity() != ConnectivityResult.none;

    try {
      EasyLoading.show(status: 'Recuperando ruta...');

      if (hasInternet) {
        await routeRepository.resumeRoute(int.parse(lastRouteId.toString()));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/root/speedometer');
        });
      } else {
        // Obtener datos de caché local para continuar offline
        final cachedRoute = await routeRepository.getLastActiveRoute();
        await writeStorage(
            'root.finalPosition',
            json.encode({
              'latitude': cachedRoute.destination.latitude,
              'longitude': cachedRoute.destination.longitude,
            }));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/root/speedometer');
        });
      }
    } catch (e) {
      EasyLoading.dismiss();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error al recuperar ruta'),
          content: Text('No se pudo recuperar la ruta. ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<int> createRoute(Map<String, dynamic> routeData) async {
    try {
      final hasConnection =
          await connectivity.checkConnectivity() != ConnectivityResult.none;
      if (!hasConnection) {
        await offlineRepo.saveOperation(OfflineOperation(
          type: OfflineOperationType.routeRecovery,
          data: {
            'action': 'create',
            'data': routeData,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
        throw 'No hay conexión. La ruta se guardó para intentar más tarde.';
      }

      return await routeRepository.createRoute(routeData);
    } catch (e) {
      await offlineRepo.saveOperation(OfflineOperation(
        type: OfflineOperationType.routeRecovery,
        data: {
          'action': 'create',
          'data': routeData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
      rethrow;
    }
  }

  Future<void> saveRoutePositions(List<Map<String, dynamic>> positions) async {
    try {
      final hasConnection =
          await connectivity.checkConnectivity() != ConnectivityResult.none;
      if (!hasConnection) {
        await offlineRepo.saveOperation(OfflineOperation(
          type: OfflineOperationType.routePositions,
          data: {
            'positions': positions,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
        return;
      }

      await routeRepository.saveRoutePositionsBatch(positions);
    } catch (e) {
      await offlineRepo.saveOperation(OfflineOperation(
        type: OfflineOperationType.routePositions,
        data: {
          'positions': positions,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
      rethrow;
    }
  }

  Future<void> finishRoute(int routeId) async {
    try {
      final hasConnection =
          await connectivity.checkConnectivity() != ConnectivityResult.none;
      if (!hasConnection) {
        await offlineRepo.saveOperation(OfflineOperation(
          type: OfflineOperationType.routeEvent,
          data: {
            'routeId': routeId,
            'eventType': 'finish',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
        throw 'No hay conexión. El evento se guardó para intentar más tarde.';
      }

      await routeRepository.finishRoute(routeId);
    } catch (e) {
      await offlineRepo.saveOperation(OfflineOperation(
        type: OfflineOperationType.routeEvent,
        data: {
          'routeId': routeId,
          'eventType': 'finish',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
      rethrow;
    }
  }

  Future<void> cancelRoute(int routeId) async {
    try {
      final hasConnection =
          await connectivity.checkConnectivity() != ConnectivityResult.none;
      if (!hasConnection) {
        await offlineRepo.saveOperation(OfflineOperation(
          type: OfflineOperationType.routeEvent,
          data: {
            'routeId': routeId,
            'eventType': 'cancel',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
        throw 'No hay conexión. El evento se guardó para intentar más tarde.';
      }

      await routeRepository.cancelRoute(routeId);
    } catch (e) {
      await offlineRepo.saveOperation(OfflineOperation(
        type: OfflineOperationType.routeEvent,
        data: {
          'routeId': routeId,
          'eventType': 'cancel',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
      rethrow;
    }
  }

  Future<void> reportSos(int routeId) async {
    try {
      final hasConnection =
          await connectivity.checkConnectivity() != ConnectivityResult.none;
      if (!hasConnection) {
        await offlineRepo.saveOperation(OfflineOperation(
          type: OfflineOperationType.routeEvent,
          data: {
            'routeId': routeId,
            'eventType': 'sos',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
        throw 'No hay conexión. El evento SOS se guardó para intentar más tarde.';
      }

      await routeRepository.reportSos(routeId);
    } catch (e) {
      await offlineRepo.saveOperation(OfflineOperation(
        type: OfflineOperationType.routeEvent,
        data: {
          'routeId': routeId,
          'eventType': 'sos',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
      rethrow;
    }
  }
}
