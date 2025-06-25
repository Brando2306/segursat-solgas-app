import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe_driving_app/utils/storage.dart';

import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_recovery_entity.dart';
import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';
import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/inspection/domain/repositories/inspection_repository.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';

class OfflineOperationsProvider with ChangeNotifier {
  final OfflineOperationsRepository repository;
  final RouteRepository routeRepository;
  final MaintenanceRepository maintenanceRepository;
  final InspectionRepository inspectionRepository;

  OfflineOperationsProvider(
      {required this.repository,
      required this.routeRepository,
      required this.maintenanceRepository,
      required this.inspectionRepository});

  List<OfflineOperation> _operations = [];
  List<OfflineOperation> get operations => _operations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Filtros por tipo de operación
  List<OfflineOperation> get routeRecoveryOperations => _operations
      .where((op) => op.type == OfflineOperationType.routeRecovery)
      .toList();

  List<OfflineOperation> get maintenanceOperations => _operations
      .where((op) => op.type == OfflineOperationType.maintenance)
      .toList();

  List<OfflineOperation> get inspectionOperations => _operations
      .where((op) => op.type == OfflineOperationType.inspection)
      .toList();

  List<OfflineOperation> get routePositionsOperations => _operations
      .where((op) => op.type == OfflineOperationType.routePositions)
      .toList();

  List<OfflineOperation> get routeFinishOperations => _operations
      .where((op) => op.type == OfflineOperationType.routeFinish)
      .toList();

  List<OfflineOperation> get routeCancelOperations => _operations
      .where((op) => op.type == OfflineOperationType.routeCancel)
      .toList();

  List<OfflineOperation> get routeSosOperations => _operations
      .where((op) => op.type == OfflineOperationType.routeSos)
      .toList();

  Future<void> loadOperations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _operations = await repository.getPendingOperations();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar operaciones offline: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveOperation(OfflineOperation operation) async {
    try {
      await repository.saveOperation(operation);
      await loadOperations(); // Refresh the list
    } catch (e) {
      _error = 'Error al guardar operación: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> retryOperation(OfflineOperation operation) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Obtener la operación actualizada
      final updatedOp =
          await repository.getOperationById(operation.id) ?? operation;

      switch (updatedOp.type) {
        case OfflineOperationType.routeCreation:
          final route = CreateRouteEntity.fromJson(updatedOp.data);
          await routeRepository.retryRouteCreation(route);
          break;
        case OfflineOperationType.routePositions:
          final positions = (updatedOp.data['positions'] as List)
              .map((p) => RoutePositionEntity.fromJson(p))
              .toList();
          await routeRepository.retryRoutePositions(positions);
          break;
        case OfflineOperationType.routeFinish:
          final route = FinishRouteEntity.fromJson(updatedOp.data);
          await routeRepository.retryRouteFinish(route);
          break;
        default:
          throw Exception('Tipo de operación no soportado');
      }

      // Actualizar como sincronizado en lugar de eliminar
      final updatedData = {...updatedOp.data, 'synced': true};
      await repository.updateOperation(
        updatedOp.copyWith(data: updatedData),
      );

      // Verificar si todo el grupo está sincronizado
      if (updatedOp.offlineRouteId != null) {
        await _checkAndCleanGroup(updatedOp.offlineRouteId!);
      }

      Snackbars.showSnackbarSuccess('Operación sincronizada correctamente');
    } catch (e) {
      // Actualizar contador de reintentos
      await repository.updateRetryCount(
          operation.id, operation.retryCount + 1, e.toString());

      Snackbars.showSnackbarError(
          'Error al reintentar operación: ${e.toString()}');
    } finally {
      _isLoading = false;
      await loadOperations();
    }
  }

  Future<void> _checkAndCleanGroup(String offlineRouteId) async {
    final operations =
        await repository.getOperationsByOfflineId(offlineRouteId);
    final allSynced = operations.every((op) => op.data['synced'] == true);

    if (allSynced) {
      for (final op in operations) {
        // await repository.removeOperation(op.id);
      }
    }
  }

  Future<void> retryOperationById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedOp = await repository.getOperationById(id);
      if (updatedOp == null) return;

      switch (updatedOp.type) {
        case OfflineOperationType.routeCreation:
          await retryRouteCreation(id);
          break;
        case OfflineOperationType.routePositions:
          await retryRoutePositions(id);
          break;
        case OfflineOperationType.routeFinish:
          await retryRouteFinish(id);
          break;
        case OfflineOperationType.routeCancel:
          await retryRouteCancel(id);
          break;
        case OfflineOperationType.routeSos:
          await retryRouteSos(id);
          break;
        case OfflineOperationType.emergencyCall:
          await retryEmergencyCall(id);
          break;
        case OfflineOperationType.incidentReport: // <-- Agrega este caso
          await retryIncidentReport(id);
          break;
        // case OfflineOperationType.maintenance:
        //   await retryMaintenance(context, id);
        //   break;
        // case OfflineOperationType.inspection:
        //   await retryInspection(context, id);
        //   break;
        case OfflineOperationType.routeRecovery:
          // No se reintenta automáticamente, se maneja manualmente
          Snackbars.showSnackbarError(
              'Operación de recuperación de ruta no reintentable');
          return;
        // ... otros casos
        default:
          await retryOperation(updatedOp);
      }

      // Actualizar como sincronizado en lugar de eliminar
      final updatedData = {...updatedOp.data, 'synced': true};
      await repository.updateOperation(
        updatedOp.copyWith(data: updatedData),
      );

      // Verificar si todo el grupo está sincronizado
      if (updatedOp.offlineRouteId != null) {
        await _checkAndCleanGroup(updatedOp.offlineRouteId!);
      }

      Snackbars.showSnackbarSuccess('Operación sincronizada correctamente');
    } catch (e) {
      await _handleRetryError(id, e);
    } finally {
      _isLoading = false;
      await loadOperations();
    }
  }

  Future<void> retryIncidentReport(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.incidentReport) return;

    try {
      // Convierte la data a tu entidad de incidente
      final incident = IncidentRouteEntity.fromJson(operation.data);
      await routeRepository.sendIncident(incident); // Usa el método de tu repo
      // await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleRetryError(String id, dynamic error) async {
    final operation = await repository.getOperationById(id);
    if (operation != null) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, error.toString());

      Snackbars.showSnackbarError(
          'Error al reintentar operación: ${error.toString()}');
    }
  }

  Future<void> retryRouteCreation(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routeCreation) return;

    try {
      final route = CreateRouteEntity.fromJson(operation.data);
      final createdRoute = await routeRepository.retryRouteCreation(route);

      // Actualizar el ID de ruta en todas las operaciones relacionadas
      if (operation.offlineRouteId != null) {
        await _updateRelatedOperationsWithNewRouteId(
            operation.offlineRouteId!, createdRoute.id);
      }

      // await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateRelatedOperationsWithNewRouteId(
      String offlineRouteId, int newRouteId) async {
    // Obtener todas las operaciones del mismo grupo
    final operations =
        await repository.getOperationsByOfflineId(offlineRouteId);

    for (final op in operations) {
      if (op.type == OfflineOperationType.routePositions) {
        // Actualizar las posiciones con el nuevo routeId
        final updatedPositions = (op.data['positions'] as List).map((p) {
          final position = RoutePositionEntity.fromJson(p);
          return position.copyWith(routeId: newRouteId);
        }).toList();

        await repository.updateOperation(op.copyWith(
          data: {'positions': updatedPositions.map((p) => p.toJson()).toList()},
          routeId: newRouteId.toString(),
        ));
      } else if (op.type == OfflineOperationType.routeFinish) {
        // Actualizar el finish con el nuevo routeId
        final finish = FinishRouteEntity.fromJson(op.data);
        await repository.updateOperation(op.copyWith(
          data: finish.copyWith(routeId: newRouteId).toJson(),
          routeId: newRouteId.toString(),
        ));
      } else if (op.type == OfflineOperationType.routeCancel) {
        // Actualizar el cancel con el nuevo routeId
        final cancel = CancelRouteEntity.fromJson(op.data);
        await repository.updateOperation(op.copyWith(
          data: cancel.copyWith(routeId: newRouteId).toJson(),
          routeId: newRouteId.toString(),
        ));
      } else if (op.type == OfflineOperationType.routeSos) {
        // Actualizar el SOS con el nuevo routeId
        final sos = EmergencyEventEntity.fromJson(op.data);
        await repository.updateOperation(op.copyWith(
          data: sos.copyWith(routeId: newRouteId).toJson(),
          routeId: newRouteId.toString(),
        ));
      } else if (op.type == OfflineOperationType.incidentReport) {
        // Actualizar el incidente con el nuevo routeId
        final incident = IncidentRouteEntity.fromJson(op.data);
        await repository.updateOperation(op.copyWith(
          data: incident.copyWith(routeId: newRouteId).toJson(),
          routeId: newRouteId.toString(),
        ));
      }
    }

    // Actualizar el ID en el almacenamiento local si es la ruta actual
    if (readStorage('root.createRoute.id') == offlineRouteId) {
      writeStorage('root.createRoute.id', newRouteId);
    }
  }

  Future<void> retryRouteFinish(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routeFinish) {
      return;
    }

    try {
      final route = FinishRouteEntity.fromJson(operation.data);
      await routeRepository.retryRouteFinish(route);
      // await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> retryRouteCancel(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routeCancel) {
      return;
    }

    try {
      final route = CancelRouteEntity.fromJson(operation.data);
      await routeRepository.retryCancelRoute(route);
      // await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> retryRouteSos(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null || operation.type != OfflineOperationType.routeSos) {
      return;
    }

    try {
      final event = EmergencyEventEntity.fromJson(operation.data);
      await routeRepository.retrySendSos(event);
      // await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> retryEmergencyCall(String id) async {
    _isLoading = true;
    notifyListeners();

    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.emergencyCall) return;

    try {
      // 1. Obtener número de emergencia
      final phoneNumber = await routeRepository.retryEmergencyPhoneNumber();

      // 2. Intentar llamada
      final url = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);

        // 3. Marcar como sincronizado
        final updatedData = {...operation.data, 'synced': true};
        await repository.updateOperation(
          operation.copyWith(data: updatedData),
        );

        Snackbars.showSnackbarSuccess('Llamada de emergencia realizada');
      } else {
        throw Exception('No se pudo iniciar la llamada');
      }
    } catch (e) {
      // await repository.updateRetryCount(
      //     id, (operation?.retryCount ?? 0) + 1, e.toString());
      Snackbars.showSnackbarError(
          'Error al reintentar llamada: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      await loadOperations();
    }
  }

  Future<void> retryRoutePositions(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routePositions) return;

    try {
      final positions = (operation.data['positions'] as List)
          .map((p) => RoutePositionEntity.fromJson(p))
          .toList();

      // Enviar en lotes de 25
      const batchSize = 25;
      for (int i = 0; i < positions.length; i += batchSize) {
        final end = (i + batchSize < positions.length)
            ? i + batchSize
            : positions.length;
        final batch = positions.sublist(i, end);
        await routeRepository.retryRoutePositions(batch);
      }

      // Actualizar como sincronizado en lugar de eliminar
      final updatedData = {...operation.data, 'synced': true};
      await repository.updateOperation(
        operation.copyWith(data: updatedData),
      );
      // Eliminar operación exitosa
      // await repository.removeOperation(operation.id);

      Snackbars.showSnackbarSuccess('Posiciones sincronizadas correctamente');
    } catch (e) {
      await repository.updateRetryCount(
        operation.id,
        operation.retryCount + 1,
        e.toString(),
      );
      Snackbars.showSnackbarError('Error al sincronizar posiciones: $e');
      rethrow;
    } finally {
      _isLoading = false;
      await loadOperations();
    }
  }

  // Método para manejar el reintento de todas las posiciones pendientes
  Future<void> retryAllRoutePositions(BuildContext context) async {
    final operations = await repository
        .getOperationsByType(OfflineOperationType.routePositions);

    // Agrupar por ruta para enviar en lotes
    final positionsByRoute = <String, List<RoutePositionEntity>>{};

    for (final op in operations) {
      final position = RoutePositionEntity.fromJson(op.data);
      positionsByRoute.putIfAbsent(position.routeId, () => []).add(position);
    }

    // Enviar cada lote
    for (final routeId in positionsByRoute.keys) {
      try {
        await routeRepository.sendRoutePositions(positionsByRoute[routeId]!);
        // Eliminar las operaciones exitosas
        for (final op in operations.where(
            (o) => RoutePositionEntity.fromJson(o.data).routeId == routeId)) {
          await repository.removeOperation(op.id);
        }
      } catch (e) {
        log('Failed to retry positions for route $routeId: $e');
      }
    }

    await loadOperations();
  }

  Future<void> retryMaintenance(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Se obtiene la operación por id en local
      final operation = await repository.getOperationById(id);
      if (operation == null ||
          operation.type != OfflineOperationType.maintenance) return;

      // Convertir la data al objeto de mantenimiento
      final maintenance = MaintenanceEntity.fromJson(operation.data);

      // Se intenta enviar la data
      await maintenanceRepository.retryMaintenance(maintenance);
      Snackbars.showSnackbarSuccess('Operación sincronizada correctamente');
      // Si todo es exitoso, se elimina la operación de offline
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      // En caso de error, se actualiza el contador sin duplicar la operación
      final operation = await repository.getOperationById(id);
      if (operation != null) {
        await repository.updateRetryCount(
            id, operation.retryCount + 1, e.toString());
        await loadOperations();
      }
      _error = 'Error al reintentar mantenimiento: ${e.toString()}';
      Snackbars.showSnackbarError(
          'Error al reintentar mantenimiento: ${e.toString()}');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryInspection(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Se obtiene la operación por id en local
      final operation = await repository.getOperationById(id);
      if (operation == null ||
          operation.type != OfflineOperationType.inspection) {
        return;
      }

      // Convertir la data al objeto de inspección
      final inspection = InspectionEntity.fromJson(operation.data);

      // Se intenta enviar la data
      await inspectionRepository.retryInspection(inspection);
      Snackbars.showSnackbarSuccess('Operación sincronizada correctamente');
      // Si todo es exitoso, se elimina la operación de offline
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      // En caso de error, se actualiza el contador sin duplicar la operación
      final operation = await repository.getOperationById(id);
      if (operation != null) {
        await repository.updateRetryCount(
            id, operation.retryCount + 1, e.toString());
        await loadOperations();
      }
      _error = 'Error al reintentar inspección: ${e.toString()}';
      Snackbars.showSnackbarError(
          'Error al reintentar inspección: ${e.toString()}');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeOperation(String id) async {
    try {
      await repository.removeOperation(id);
      await loadOperations(); // Refresh the list
    } catch (e) {
      _error = 'Error al eliminar operación: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> hasPendingRouteOperation() async {
    return await repository.hasPendingRouteOperation();
  }

  Future<void> saveRouteRecoveryAttempt(
      int routeId, Map<String, dynamic> routeData) async {
    final operation = OfflineOperation(
      type: OfflineOperationType.routeRecovery,
      data: RouteRecoveryEntity(
        routeId: routeId,
        timestamp: DateTime.now(),
        routeData: routeData,
      ).toJson(),
    );
    await saveOperation(operation);
  }

  // Agrupa operaciones por ruta
  Map<String, List<OfflineOperation>> get groupedRouteOperations {
    final routeOperations = _operations.where((op) =>
        op.type == OfflineOperationType.routeCreation ||
        op.type == OfflineOperationType.routePositions ||
        op.type == OfflineOperationType.routeSos ||
        op.type == OfflineOperationType.emergencyCall ||
        op.type == OfflineOperationType.incidentReport ||
        op.type == OfflineOperationType.routeFinish ||
        op.type == OfflineOperationType.routeCancel);

    final grouped = <String, List<OfflineOperation>>{};

    for (final op in routeOperations) {
      // Usar offlineRouteId como clave principal, si no existe usar routeId
      final key = op.offlineRouteId ?? op.routeId.toString() ?? 'no-route';
      grouped.putIfAbsent(key, () => []).add(op);
    }

    // Ordenar los grupos por fecha (más reciente primero)
    final sorted = Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          final aDate = a.value.first.createdAt;
          final bDate = b.value.first.createdAt;
          return bDate.compareTo(aDate);
        }),
    );

    return sorted;
  }

  // Método para reintentar todas las operaciones de una ruta
  Future<void> retryRouteOperations(String routeId) async {
    final operations = groupedRouteOperations[routeId] ?? [];

    // Ordenar: primero creación, luego posiciones, luego finalización
    operations.sort((a, b) {
      if (a.type == OfflineOperationType.routeCreation) return -1;
      if (b.type == OfflineOperationType.routeCreation) return 1;
      if (a.type == OfflineOperationType.routePositions) return -1;
      if (b.type == OfflineOperationType.routePositions) return 1;
      return 0;
    });

    for (final op in operations) {
      try {
        switch (op.type) {
          case OfflineOperationType.routeCreation:
            final route = CreateRouteEntity.fromJson(op.data);
            await routeRepository.createRoute(route);
            break;
          case OfflineOperationType.routePositions:
            final positions = (op.data['positions'] as List)
                .map((p) => RoutePositionEntity.fromJson(p))
                .toList();
            await routeRepository.sendRoutePositions(positions);
            break;
          case OfflineOperationType.routeFinish:
            final finish = FinishRouteEntity.fromJson(op.data);
            await routeRepository.finishRoute(finish);
            break;
          default:
            continue;
        }
        await repository.removeOperation(op.id);
      } catch (e) {
        await repository.updateRetryCount(
            op.id, op.retryCount + 1, e.toString());
        rethrow;
      }
    }
  }
}
