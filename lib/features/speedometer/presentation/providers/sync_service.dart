import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/cancel_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/create_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/emergency_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/finish_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/incident_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/stop_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/utils/storage.dart';

class SyncService {
  final OfflineOperationsRepository _repository;
  final RouteRepository _routeRepository;

  SyncService(this._repository, this._routeRepository);

  Future<SyncResult> syncPendingRoutes() async {
    final pendingOps = await _repository.getPendingOperations();
    final routeOps = pendingOps.where(_isRouteOperation).toList();

    var successful = 0;
    var failed = 0;
    final errors = <String>[];

    // PRIMERO: Procesar todas las creaciones de ruta para obtener los IDs reales
    final creationOps = routeOps
        .where((op) => op.type == OfflineOperationType.routeCreation)
        .toList();
    final routeIdMap = <String, int>{}; // Mapeo: offlineRouteId -> realRouteId

    for (final op in creationOps) {
      try {
        await _retryRouteCreationWithIdUpdate(op, routeIdMap);
        successful++;

        final updatedData = {...op.data, 'synced': true};
        await _repository.updateOperation(op.copyWith(data: updatedData));
      } catch (e) {
        failed++;
        errors.add('${op.type.displayName}: $e');
        await _repository.updateRetryCount(
            op.id, op.retryCount + 1, e.toString());
      }
    }

    // LUEGO: Procesar las demás operaciones CON LOS IDs ACTUALIZADOS
    final otherOps = routeOps
        .where((op) => op.type != OfflineOperationType.routeCreation)
        .toList();

    for (final op in otherOps) {
      try {
        await _retrySingleOperation(op, routeIdMap);
        successful++;

        final updatedData = {...op.data, 'synced': true};
        await _repository.updateOperation(op.copyWith(data: updatedData));
      } catch (e) {
        failed++;
        errors.add('${op.type.displayName}: $e');
        await _repository.updateRetryCount(
            op.id, op.retryCount + 1, e.toString());
      }
    }

    await _cleanupSyncedGroups(routeOps);
    return SyncResult(
      total: routeOps.length,
      successful: successful,
      failed: failed,
      errors: errors,
    );
  }

  bool _isRouteOperation(OfflineOperation op) {
    return op.type == OfflineOperationType.routeCreation ||
        op.type == OfflineOperationType.routePositions ||
        op.type == OfflineOperationType.routeFinish ||
        op.type == OfflineOperationType.routeCancel ||
        op.type == OfflineOperationType.routeSos ||
        op.type == OfflineOperationType.incidentReport ||
        op.type == OfflineOperationType.routeStop;
  }

  Future<void> _retrySingleOperation(
      OfflineOperation op, Map<String, int> routeIdMap) async {
    // OBTENER EL ROUTEID REAL SI EXISTE EN EL MAPA
    final realRouteId = _getRealRouteId(op, routeIdMap);

    switch (op.type) {
      case OfflineOperationType.routePositions:
        final positions = (op.data['positions'] as List)
            .map((p) => RoutePositionEntity.fromJson(p))
            .toList();

        // ACTUALIZAR POSICIONES CON ROUTEID REAL
        final updatedPositions =
            positions.map((p) => p.copyWith(routeId: realRouteId)).toList();

        await _routeRepository.retryRoutePositions(updatedPositions);
        break;

      case OfflineOperationType.routeFinish:
        var route = FinishRouteEntity.fromJson(op.data);
        // ACTUALIZAR FINISH CON ROUTEID REAL
        route = route.copyWith(routeId: realRouteId);
        await _routeRepository.retryRouteFinish(route);
        break;

      case OfflineOperationType.routeCancel:
        var route = CancelRouteEntity.fromJson(op.data);
        // ACTUALIZAR CANCEL CON ROUTEID REAL
        route = route.copyWith(routeId: realRouteId);
        await _routeRepository.retryCancelRoute(route);
        break;

      case OfflineOperationType.routeSos:
        var event = EmergencyEventEntity.fromJson(op.data);
        // ACTUALIZAR SOS CON ROUTEID REAL
        event = event.copyWith(routeId: realRouteId);
        await _routeRepository.retrySendSos(event);
        break;

      case OfflineOperationType.incidentReport:
        var incident = IncidentRouteEntity.fromJson(op.data);
        // ACTUALIZAR INCIDENTE CON ROUTEID REAL
        incident = incident.copyWith(routeId: realRouteId);
        await _routeRepository.retrySendIncident(incident);
        break;

      case OfflineOperationType.routeStop:
        var stop = StopRouteEntity.fromJson(op.data);
        // ACTUALIZAR STOP CON ROUTEID REAL
        stop = stop.copyWith(routeId: realRouteId);
        await _routeRepository.retrySendRouteStop(stop);
        break;

      case OfflineOperationType.routeCreation:
        // Ya procesado anteriormente
        break;

      default:
        throw Exception('Unsupported operation type: ${op.type}');
    }
  }

  Future<void> _retryRouteCreationWithIdUpdate(
      OfflineOperation op, Map<String, int> routeIdMap) async {
    final route = CreateRouteEntity.fromJson(op.data);
    final createdRoute = await _routeRepository.retryRouteCreation(route);

    // GUARDAR EL MAPEO OFFLINE_ID -> REAL_ID
    if (op.offlineRouteId != null) {
      routeIdMap[op.offlineRouteId!] = createdRoute.id;

      // Actualizar también las operaciones en la base de datos offline
      await _updateRelatedOperationsWithNewRouteId(
          op.offlineRouteId!, createdRoute.id);
    }

    // Actualizar el storage local con el nuevo ID
    await _updateRouteIdInStorage(createdRoute.id);
  }

  int? _getRealRouteId(OfflineOperation op, Map<String, int> routeIdMap) {
    // Intentar obtener del mapa primero
    if (op.offlineRouteId != null &&
        routeIdMap.containsKey(op.offlineRouteId!)) {
      return routeIdMap[op.offlineRouteId!];
    }

    // Si no está en el mapa, usar el routeId de la operación (puede ser null)
    final existingRouteId = op.data['routeId'] ?? op.routeId;
    return existingRouteId is int ? existingRouteId : null;
  }

  Future<void> _updateRelatedOperationsWithNewRouteId(
      String offlineRouteId, int newRouteId) async {
    final operations =
        await _repository.getOperationsByOfflineId(offlineRouteId);

    for (final op in operations) {
      if (op.type == OfflineOperationType.routeCreation)
        continue; // Skip creation itself

      Map<String, dynamic> updatedData = Map<String, dynamic>.from(op.data);

      switch (op.type) {
        case OfflineOperationType.routePositions:
          final positions = (op.data['positions'] as List).map((p) {
            final position = RoutePositionEntity.fromJson(p);
            return position.copyWith(routeId: newRouteId).toJson();
          }).toList();
          updatedData['positions'] = positions;
          break;

        case OfflineOperationType.routeFinish:
        case OfflineOperationType.routeCancel:
        case OfflineOperationType.routeSos:
        case OfflineOperationType.incidentReport:
        case OfflineOperationType.routeStop:
          updatedData['routeId'] = newRouteId;
          break;

        default:
          break;
      }

      await _repository.updateOperation(op.copyWith(
        data: updatedData,
        routeId: newRouteId.toString(),
      ));

      print(
          '🔄 SyncService - Actualizada operación ${op.type} con routeId: $newRouteId');
    }
  }

  Future<void> _updateRouteIdInStorage(int newRouteId) async {
    try {
      await writeStorage('root.createRoute.id', newRouteId);
      await writeStorage('personal.lastRoute', newRouteId);
      print('🔄 SyncService - RouteId actualizado en storage: $newRouteId');
    } catch (e) {
      print('❌ SyncService - Error actualizando routeId en storage: $e');
    }
  }

  Future<void> _cleanupSyncedGroups(List<OfflineOperation> operations) async {
    final offlineRouteIds = operations
        .map((op) => op.offlineRouteId)
        .where((id) => id != null)
        .toSet();

    for (final offlineRouteId in offlineRouteIds) {
      final groupOps =
          await _repository.getOperationsByOfflineId(offlineRouteId!);
      final allSynced = groupOps.every((op) => op.data['synced'] == true);

      if (allSynced) {
        for (final op in groupOps) {
          await _repository.removeOperation(op.id);
        }
        print(
            '🧹 SyncService - Grupo $offlineRouteId completamente sincronizado y limpiado');
      }
    }
  }
}

class SyncResult {
  final int total;
  final int successful;
  final int failed;
  final List<String> errors;

  SyncResult({
    required this.total,
    required this.successful,
    required this.failed,
    required this.errors,
  });
}
