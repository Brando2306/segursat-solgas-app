import 'dart:convert';
import 'package:safe_driving_app/utils/storage.dart';

import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/route/domain/entities/route.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_local_data_source.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_remote_data_source.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDataSource remoteDataSource;
  final RouteLocalDataSource localDataSource;
  final OfflineOperationsRepository offlineOperationsRepository;

  RouteRepositoryImpl(
      {required this.remoteDataSource,
      required this.localDataSource,
      required this.offlineOperationsRepository});

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
  Future<RouteEntity> createRoute(CreateRouteEntity route) async {
    try {
      final createdRoute = await remoteDataSource.createRoute(route);

      // Guardar en offline de todas formas
      final offlineId =
          '${StorageKeys.offlineRoutePrefix}${DateTime.now().millisecondsSinceEpoch}';
      await writeStorage(StorageKeys.currentOfflineRouteId, offlineId);

      await offlineOperationsRepository.saveFailedRouteCreation(
          route, offlineId);

      return createdRoute;
    } catch (e) {
      final offlineId =
          '${StorageKeys.offlineRoutePrefix}${DateTime.now().millisecondsSinceEpoch}';
      // await prefs.setString(StorageKeys.currentOfflineRouteId, offlineId);
      await writeStorage(StorageKeys.currentOfflineRouteId, offlineId);

      await offlineOperationsRepository.saveFailedRouteCreation(
          route, offlineId);
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

      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineId != null) {
        final ops = await offlineOperationsRepository
            .getOperationsByOfflineId(offlineId);
        for (final op in ops) {
          await offlineOperationsRepository.removeOperation(op.id);
        }
        await removeStorage(StorageKeys.currentOfflineRouteId);
      }
    } catch (e) {
      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);

      if (offlineId != null) {
        await offlineOperationsRepository.saveFailedRouteFinish(
            route, offlineId);
      }
      rethrow;
    }
  }

  @override
  Future<void> cancelRoute(CancelRouteEntity route) async {
    try {
      await remoteDataSource.cancelRoute(route);

      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineId != null) {
        final ops = await offlineOperationsRepository
            .getOperationsByOfflineId(offlineId);
        for (final op in ops) {
          await offlineOperationsRepository.removeOperation(op.id);
        }
        await removeStorage(StorageKeys.currentOfflineRouteId);
      }
    } catch (e) {
      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);

      if (offlineId != null) {
        await offlineOperationsRepository.saveFailedRouteCancel(
            route, offlineId);
      }
      rethrow;
    }
  }

  @override
  Future<void> sendSos(EmergencyEventEntity event) async {
    try {
      await remoteDataSource.sendSos(event);
    } catch (e) {
      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);

      if (offlineId != null) {
        await offlineOperationsRepository.saveOperation(
          OfflineOperation(
            type: OfflineOperationType.routeSos,
            data: event.toJson(),
            offlineRouteId: offlineId,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  @override
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions) async {
    try {
      await remoteDataSource.sendRoutePositions(positions);
    } catch (e) {
      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineId != null) {
        await offlineOperationsRepository.saveFailedPositions(
            positions, offlineId);
      }
      rethrow;
    }
  }

  @override
  Future<String> getEmergencyPhoneNumber() async {
    try {
      return await remoteDataSource.getEmergencyPhoneNumber();
    } catch (e) {
      // Guardar como operación offline solo si hay un offlineRouteId
      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineId != null) {
        await offlineOperationsRepository.saveFailedEmergencyCall(offlineId);
      }
      throw Exception('Failed to get emergency number: $e');
    }
  }

  @override
  Future<RouteEntity> retryRouteCreation(CreateRouteEntity route) async {
    final createdRoute = await remoteDataSource.createRoute(route);
    return createdRoute;
  }

  @override
  Future<void> retryRoutePositions(List<RoutePositionEntity> positions) async {
    await remoteDataSource.sendRoutePositions(positions);
  }

  @override
  Future<void> retryRouteFinish(FinishRouteEntity route) async {
    await remoteDataSource.finishRoute(route);

    final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
    if (offlineId != null) {
      final ops =
          await offlineOperationsRepository.getOperationsByOfflineId(offlineId);
      for (final op in ops) {
        await offlineOperationsRepository.removeOperation(op.id);
      }
      await removeStorage(StorageKeys.currentOfflineRouteId);
    }
  }

  @override
  Future<void> retrySendSos(EmergencyEventEntity event) async {
    await remoteDataSource.sendSos(event);
  }

  @override
  Future<void> retryCancelRoute(CancelRouteEntity event) async {
    await remoteDataSource.cancelRoute(event);

    final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
    if (offlineId != null) {
      final ops =
          await offlineOperationsRepository.getOperationsByOfflineId(offlineId);
      for (final op in ops) {
        await offlineOperationsRepository.removeOperation(op.id);
      }
      await removeStorage(StorageKeys.currentOfflineRouteId);
    }
  }

  @override
  Future<String> retryEmergencyPhoneNumber() async {
    return await remoteDataSource.getEmergencyPhoneNumber();
  }

  @override
  Future<void> sendIncident(IncidentRouteEntity incident) async {
    try {
      await remoteDataSource.sendIncident(incident);
    } catch (e) {
      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineId != null) {
        await offlineOperationsRepository.saveFailedIncident(
            incident, offlineId);
      }
      rethrow;
    }
  }

  @override
  Future<void> retrySendIncident(IncidentRouteEntity incident) async {
    await remoteDataSource.sendIncident(incident);
  }
}
