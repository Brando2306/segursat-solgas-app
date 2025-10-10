import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/cancel_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/emergency_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/finish_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/incident_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/stop_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';

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

    for (final op in routeOps) {
      try {
        await _retrySingleOperation(op);
        successful++;

        // Marcar como sincronizado
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
    // return op.type == OfflineOperationType.routeCreation ||
    return op.type == OfflineOperationType.routePositions ||
        op.type == OfflineOperationType.routeFinish ||
        op.type == OfflineOperationType.routeCancel ||
        op.type == OfflineOperationType.routeSos ||
        op.type == OfflineOperationType.incidentReport ||
        op.type == OfflineOperationType.routeStop;
  }

  Future<void> _retrySingleOperation(OfflineOperation op) async {
    switch (op.type) {
      // case OfflineOperationType.routeCreation:
      //   final route = CreateRouteEntity.fromJson(op.data);
      //   await _routeRepository.retryRouteCreation(route);
      //   break;

      case OfflineOperationType.routePositions:
        final positions = (op.data['positions'] as List)
            .map((p) => RoutePositionEntity.fromJson(p))
            .toList();
        await _routeRepository.retryRoutePositions(positions);
        break;

      case OfflineOperationType.routeFinish:
        final route = FinishRouteEntity.fromJson(op.data);
        await _routeRepository.retryRouteFinish(route);
        break;

      case OfflineOperationType.routeCancel:
        final route = CancelRouteEntity.fromJson(op.data);
        await _routeRepository.retryCancelRoute(route);
        break;

      case OfflineOperationType.routeSos:
        final event = EmergencyEventEntity.fromJson(op.data);
        await _routeRepository.retrySendSos(event);
        break;

      case OfflineOperationType.incidentReport:
        final incident = IncidentRouteEntity.fromJson(op.data);
        await _routeRepository.retrySendIncident(incident);
        break;

      case OfflineOperationType.routeStop:
        final stop = StopRouteEntity.fromJson(op.data);
        await _routeRepository.retrySendRouteStop(stop);
        break;

      default:
        throw Exception('Unsupported operation type: ${op.type}');
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
