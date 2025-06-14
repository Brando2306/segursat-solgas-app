import 'dart:convert';

import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_local_data_source.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_remote_data_source.dart';
import 'package:safe_driving_app/features/route/domain/entities/route.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/utils/storage.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDataSource remoteDataSource;
  final RouteLocalDataSource localDataSource;
  final OfflineOperationsRepository offlineOperationsRepository;

  RouteRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.offlineOperationsRepository,
  });

  @override
  Future<Route> getLastActiveRoute() async {
    try {
      // 1. Intentar obtener la última ruta activa del servidor
      final activeRoutes = await remoteDataSource.getActiveRoutes();
      if (activeRoutes.isNotEmpty) {
        final activeRoute = activeRoutes.first;
        await localDataSource.cacheRoute(activeRoute);
        return activeRoute;
      }

      // 2. Si no hay rutas activas, verificar si hay una en almacenamiento local
      final lastRouteId = readStorage('personal.lastRoute');
      if (lastRouteId != null) {
        final route = await remoteDataSource.getRoute(lastRouteId);
        if (route.toRoute().status == RouteStatus.running) {
          await localDataSource.cacheRoute(route.toRoute());
          return route.toRoute();
        }
      }

      // 3. Finalmente, verificar en caché local
      final cachedRoute = await localDataSource.getLastCachedRoute();
      if (cachedRoute != null && cachedRoute.status == RouteStatus.running) {
        return cachedRoute;
      }

      throw Exception('No active route found');
    } catch (e) {
      // En caso de error, intentar con la caché local
      final cachedRoute = await localDataSource.getLastCachedRoute();
      if (cachedRoute != null) return cachedRoute;
      rethrow;
    }
  }

  @override
  Future<Route> resumeRoute(int routeId) async {
    try {
      // 1. Obtener la ruta del servidor
      final route = await remoteDataSource.getRoute(routeId.toString());

      // 2. Actualizar almacenamiento local
      await writeStorage('personal.lastRoute', routeId);
      await writeStorage('root.createRoute.id', routeId);
      await writeStorage('personal.lastRouteStatus', 'running');

      // 3. Guardar en caché local
      await localDataSource.cacheRoute(route.toRoute());

      // 4. Guardar posición final en storage
      await writeStorage(
        'root.finalPosition',
        json.encode({
          'latitude': route.toRoute().destination.latitude,
          'longitude': route.toRoute().destination.longitude,
        }),
      );

      return route.toRoute();
    } catch (e) {
      // En caso de error, guardar como operación pendiente
      await offlineOperationsRepository.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeRecovery,
          data: {
            'routeId': routeId,
            'action': 'resume',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Intentar con la caché local
      final cachedRoute = await localDataSource.getLastCachedRoute();
      if (cachedRoute != null && cachedRoute.id == routeId) {
        return cachedRoute;
      }

      rethrow;
    }
  }

  @override
  Future<void> saveRoutePosition(RoutePosition position) async {
    try {
      await remoteDataSource.saveRoutePosition(position);
    } catch (e) {
      await localDataSource.savePendingPosition(position);
      await offlineOperationsRepository.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeRecovery,
          data: {
            ...position.toJson(),
            'action': 'save_position',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );
    }
  }

  @override
  Future<List<RoutePosition>> getPendingPositions() async {
    return await localDataSource.getPendingPositions();
  }

  @override
  Future<void> syncPendingOperations() async {
    final pendingPositions = await localDataSource.getPendingPositions();
    for (final position in pendingPositions) {
      try {
        await remoteDataSource.saveRoutePosition(position);
        await localDataSource.removePendingPosition(position.id);
      } catch (e) {
        // Continuar con las demás aunque falle una
        continue;
      }
    }
  }

  // @override
  // Future<void> finishRoute(int routeId) async {
  //   try {
  //     await remoteDataSource.finishRoute(routeId);
  //     await localDataSource.cleanRouteData(routeId);
  //   } catch (e) {
  //     await offlineRepo.saveOperation(
  //       OfflineOperation(
  //         type: OfflineOperationType.routeRecovery,
  //         data: {
  //           'routeId': routeId,
  //           'action': 'finish',
  //           'timestamp': DateTime.now().toIso8601String(),
  //         },
  //       ),
  //     );
  //     rethrow;
  //   }
  // }

  @override
  Future<void> saveRoutePositionsBatch(
      List<Map<String, dynamic>> positions) async {
    try {
      await remoteDataSource.saveRoutePositionsBatch(positions);
    } catch (e) {
      // Guardar posiciones pendientes localmente
      await localDataSource.savePendingPositions(positions);
      rethrow;
    }
  }

  // @override
  // Future<void> cancelRoute(int routeId) async {
  //   try {
  //     await remoteDataSource.cancelRoute(routeId);
  //   } catch (e) {
  //     await offlineRepo.saveOperation(
  //       OfflineOperation(
  //         type: OfflineOperationType.routeEvent,
  //         data: {
  //           'routeId': routeId,
  //           'eventType': 'cancel',
  //           'timestamp': DateTime.now().toIso8601String(),
  //         },
  //       ),
  //     );
  //     rethrow;
  //   }
  // }

  // @override
  // Future<void> reportSos(int routeId) async {
  //   try {
  //     await remoteDataSource.reportSos(routeId);
  //   } catch (e) {
  //     // Guardar operación pendiente
  //     await offlineOperationsRepository.saveOperation(
  //       OfflineOperation(
  //         type: OfflineOperationType.routeEvent,
  //         data: {
  //           'routeId': routeId,
  //           'eventType': 'sos',
  //           'timestamp': DateTime.now().toIso8601String(),
  //         },
  //       ),
  //     );
  //     rethrow;
  //   }
  // }

  // @override
  // Future<int> createRoute(Map<String, dynamic> routeData) async {
  //   try {
  //     return await remoteDataSource.createRoute(routeData);
  //   } catch (e) {
  //     await offlineRepo.saveOperation(
  //       OfflineOperation(
  //         type: OfflineOperationType.routeRecovery,
  //         data: {
  //           'action': 'create',
  //           'data': routeData,
  //           'timestamp': DateTime.now().toIso8601String(),
  //         },
  //       ),
  //     );
  //     rethrow;
  //   }
  // }

   @override
  Future<RouteEntity> createRoute(CreateRouteEntity route) async {
    try {
      final createdRoute = await remoteDataSource.createRoute(route);
      return createdRoute;
    } catch (e) {
      // Guardar en operaciones offline
      await offlineOperationsRepository.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeCreation,
          data: route.toJson(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<RouteEntity> getRoute(String routeId) async {
    return await remoteDataSource.getRoute(routeId);
  }

  @override
  Future<void> finishRoute(FinishRouteEntity route) async {
    try {
      await remoteDataSource.finishRoute(route);
    } catch (e) {
      // Guardar en operaciones offline
      await offlineOperationsRepository.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeFinish,
          data: route.toJson(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelRoute(RouteEntity route) async {
    try {
      await remoteDataSource.cancelRoute(route);
    } catch (e) {
      // Guardar en operaciones offline
      await offlineOperationsRepository.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeCancel,
          data: route.toJson(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> sendSos(RouteEventEntity event) async {
    try {
      await remoteDataSource.sendSos(event);
    } catch (e) {
      // Guardar en operaciones offline
      await offlineOperationsRepository.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeSos,
          data: event.toJson(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions) async {
    try {
      await remoteDataSource.sendRoutePositions(positions);
    } catch (e) {
      // Guardar en operaciones offline
      for (final position in positions) {
        await offlineOperationsRepository.saveOperation(
          OfflineOperation(
            type: OfflineOperationType.routePositions,
            data: position.toJson(),
          ),
        );
      }
      rethrow;
    }
  }
}
