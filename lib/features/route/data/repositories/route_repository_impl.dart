import 'dart:convert';

import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_local_data_source.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_remote_data_source.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/utils/storage.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDataSource remoteDataSource;
  final RouteLocalDataSource localDataSource;
  final OfflineOperationsRepository offlineRepo;

  RouteRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.offlineRepo,
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
        final route = await remoteDataSource.getRoute(lastRouteId as int);
        if (route.status == RouteStatus.running) {
          await localDataSource.cacheRoute(route);
          return route;
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
      final route = await remoteDataSource.getRoute(routeId);

      // 2. Actualizar almacenamiento local
      await writeStorage('personal.lastRoute', routeId);
      await writeStorage('root.createRoute.id', routeId);
      await writeStorage('personal.lastRouteStatus', 'running');

      // 3. Guardar en caché local
      await localDataSource.cacheRoute(route);

      // 4. Guardar posición final en storage
      await writeStorage(
        'root.finalPosition',
        json.encode({
          'latitude': route.destination.latitude,
          'longitude': route.destination.longitude,
        }),
      );

      return route;
    } catch (e) {
      // En caso de error, guardar como operación pendiente
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
      await offlineRepo.saveOperation(
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

  @override
  Future<void> finishRoute(int routeId) async {
    try {
      await remoteDataSource.finishRoute(routeId);
      await localDataSource.cleanRouteData(routeId);
    } catch (e) {
      await offlineRepo.saveOperation(
        OfflineOperation(
          type: OfflineOperationType.routeRecovery,
          data: {
            'routeId': routeId,
            'action': 'finish',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );
      rethrow;
    }
  }
}
