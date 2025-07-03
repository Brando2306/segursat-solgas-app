import 'dart:developer';

import 'package:safe_driving_app/features/route/domain/entities/cancel_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/create_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/finish_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/incident_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/stop_route_entity.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:safe_driving_app/utils/storage.dart';

import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_response_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/emergency_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_remote_data_source.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDataSource remoteDataSource;
  final OfflineOperationsRepository offlineOperationsRepository;

  RouteRepositoryImpl(
      {required this.remoteDataSource,
      required this.offlineOperationsRepository});

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
  Future<RouteEntity> getRoute(int routeId) async {
    try {
      final route = await remoteDataSource.getRoute(routeId);

      // Check if we have an offlineRouteId in storage
      final offlineRouteId = readStorage(StorageKeys.currentOfflineRouteId);

      if (offlineRouteId == null) {
        // Create a new offlineRouteId since this is a new device
        final newOfflineRouteId =
            '${StorageKeys.offlineRoutePrefix}${DateTime.now().millisecondsSinceEpoch}';
        await writeStorage(
            StorageKeys.currentOfflineRouteId, newOfflineRouteId);

        // Create a fake route creation operation for offline consistency
        final createRouteEntity = CreateRouteEntity(
          destinationLatitude: route.destinationLatitude.toString(),
          destinationLongitude: route.destinationLongitude.toString(),
          unitName: route.unitName, // Assuming route has unitName
          timestamp: getDate(), // Assuming route has timestamp
          sourceLatitude: route.sourceLatitude
              .toString(), // Assuming route has sourceLatitude
          sourceLongitude: route.sourceLongitude
              .toString(), // Assuming route has sourceLongitude
          // Add other required fields based on your CreateRouteEntity
        );

        final operation = OfflineOperation(
            type: OfflineOperationType.routeCreation,
            data: createRouteEntity.toJson(),
            offlineRouteId: newOfflineRouteId,
            synced: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now());

        await offlineOperationsRepository.saveOperation(operation);

        log('Created new offlineRouteId for existing route: $newOfflineRouteId');
      }

      return route;
    } catch (e) {
      // // Handle offline case
      // final offlineRouteId = readStorage(StorageKeys.currentOfflineRouteId);
      // if (offlineRouteId != null) {
      //   // Try to get any existing positions from offline storage
      //   final ops = await offlineOperationsRepository
      //       .getOperationsByOfflineId(offlineRouteId);

      //   // Check if we have a route creation operation
      //   final hasRouteCreation =
      //       ops.any((op) => op.type == OfflineOperationType.routeCreation);

      //   if (hasRouteCreation) {
      //     // Get positions if available
      //     final positionOps =
      //         ops.where((op) => op.type == OfflineOperationType.routePositions);
      //     List<PositionEntity> positions = [];

      //     if (positionOps.isNotEmpty) {
      //       final lastPositionOp = positionOps.reduce((curr, next) =>
      //           curr.createdAt.isAfter(next.createdAt) ? curr : next);

      //       positions = (lastPositionOp.data['positions'] as List)
      //           .map((p) => PositionEntity.fromJson(p))
      //           .toList();
      //     }

      //     // Get the creation operation to build a minimal RouteEntity
      //     final creationOp = ops.firstWhere(
      //         (op) => op.type == OfflineOperationType.routeCreation);

      //     return RouteEntity(
      //       id: routeId,
      //       positions: positions,
      //       unitId: int.parse(creationOp.data['unit_id']),
      //       unitName: '', // You might need to store this elsewhere
      //       sourceLatitude: 0, // Default values
      //       sourceLongitude: 0,
      //       sourceAddress: '',
      //       destinationLatitude:
      //           double.parse(creationOp.data['destination_latitude']),
      //       destinationLongitude:
      //           double.parse(creationOp.data['destination_longitude']),
      //       destinationAddress: '',
      //       status: 'R', // Assuming 'R' for running
      //     );
      //   }
      // }

      rethrow;
    }
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
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. La finalización de la ruta se guardó y lo podrás sincronizar luego.');
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
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. La cancelación de la ruta se guardó y lo podrás sincronizar luego.');
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
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. El evento SOS se guardó y lo podrás sincronizar luego.');
      }
      rethrow;
    }
  }

  @override
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions) async {
    //TODO: probar cuando no hay red, se crea la ruta, y luego la activo, actualmente se envian las posiciones por q backend no valida el routeid, entonces front debe validar eso y si no tiene routeid mandarlo a guardar, no se si desde el entity podemos hacer eso con un required en routeid
    // Validación adicional en el repositorio
    if (positions.isEmpty) {
      throw Exception('No se pueden enviar posiciones vacías');
    }

    // Filtramos posiciones sin routeId
    final invalidPositions = positions.where((p) => p.routeId == null).toList();
    final validPositions = positions.where((p) => p.routeId != null).toList();

    // Guardamos inmediatamente las inválidas
    if (invalidPositions.isNotEmpty) {
      await _storeInvalidPositions(invalidPositions);
    }

    if (validPositions.isNotEmpty) {
      try {
        await remoteDataSource.sendRoutePositions(validPositions);
      } catch (e) {
        await _storeInvalidPositions(validPositions); // Guardar como fallidas
        rethrow;
      }
    } else {
      throw Exception('No se pueden enviar posiciones válidas sin un routeId');
    }
  }

  Future<void> _storeInvalidPositions(
      List<RoutePositionEntity> positions) async {
    final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
    if (offlineId != null && positions.isNotEmpty) {
      await offlineOperationsRepository.saveFailedPositions(
          positions, offlineId);
      if (positions.length == 1) {
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. La posición de la ruta se guardó y la podrás sincronizar luego.');
      } else {
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. Las posiciones de la ruta se guardaron y las podrás sincronizar luego.');
      }
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
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. El número de emergencia se guardó y lo podrás sincronizar luego.');
      }
      throw Exception('Failed to get emergency number: $e');
    }
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
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. El incidente se guardó y lo podrás sincronizar luego.');
      }
      rethrow;
    }
  }

  @override
  Future<void> sendRouteStop(StopRouteEntity stop) async {
    try {
      await remoteDataSource.sendRouteStop(stop);
    } catch (e) {
      final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineId != null) {
        await offlineOperationsRepository.saveFailedRouteStop(stop, offlineId);
        Snackbars.showSnackbarSuccess(
            'Modo offline activado. La parada de la ruta se guardó y la podrás sincronizar luego.');
      }
      rethrow;
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
  Future<void> retrySendSos(EmergencyEventEntity event) async {
    await remoteDataSource.sendSos(event);
  }

  @override
  Future<String> retryEmergencyPhoneNumber() async {
    return await remoteDataSource.getEmergencyPhoneNumber();
  }

  @override
  Future<void> retrySendIncident(IncidentRouteEntity incident) async {
    await remoteDataSource.sendIncident(incident);
  }

  @override
  Future<void> retrySendRouteStop(StopRouteEntity stop) async {
    await remoteDataSource.sendRouteStop(stop);
  }
}
