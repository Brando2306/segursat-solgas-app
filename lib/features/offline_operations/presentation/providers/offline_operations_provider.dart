import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';
import 'package:safe_driving_app/features/inspection/presentation/providers/inspection_provider.dart';
import 'package:safe_driving_app/features/maintenance/data/datasources/maintenance_remote_datasource.dart';
import 'package:safe_driving_app/features/maintenance/data/repositories/maintenance_repository_impl.dart';
import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_recovery_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/features/route/presentation/providers/route_provider.dart';
import 'package:safe_driving_app/features/maintenance/presentation/providers/maintenance_provider.dart';

class OfflineOperationsProvider with ChangeNotifier {
  final OfflineOperationsRepository repository;

  OfflineOperationsProvider({required this.repository});

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

  List<OfflineOperation> get routeEventOperations => _operations
      .where((op) => op.type == OfflineOperationType.routeEvent)
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

  Future<void> retryOperation(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await repository.retryOperation(id);
      await loadOperations(); // Refresh the list
    } catch (e) {
      _error = 'Error al reintentar operación: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // // Métodos específicos para tipos de operaciones
  // Future<void> retryRouteCreation(String id) async {
  //   final operation = await repository.getOperationById(id);
  //   if (operation == null ||
  //       operation.type != OfflineOperationType.routeRecovery) return;

  //   try {
  //     // Aquí deberías llamar al RouteProvider para reintentar la creación de ruta
  //     // Ejemplo: await context.read<RouteProvider>().retryRouteCreation(operation.data['routeId']);
  //     await repository.removeOperation(id);
  //     await loadOperations();
  //   } catch (e) {
  //     await repository.updateRetryCount(
  //         id, operation.retryCount + 1, e.toString());
  //     rethrow;
  //   }
  // }
  Future<void> retryRouteCreation(BuildContext context, String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routeCreation) return;

    try {
      final route = RouteEntity.fromJson(operation.data);
      await context.read<RouteRepository>().createRoute(route);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
    }
  }

  Future<void> retryRouteFinish(BuildContext context, String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null || operation.type != OfflineOperationType.routeFinish)
      return;

    try {
      final route = FinishRouteEntity.fromJson(operation.data);
      await context.read<RouteRepository>().finishRoute(route);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
    }
  }

  Future<void> retryRouteCancel(BuildContext context, String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null || operation.type != OfflineOperationType.routeCancel)
      return;

    try {
      final route = RouteEntity.fromJson(operation.data);
      await context.read<RouteRepository>().cancelRoute(route);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
    }
  }

  Future<void> retryRouteSos(BuildContext context, String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null || operation.type != OfflineOperationType.routeSos)
      return;

    try {
      final event = RouteEventEntity.fromJson(operation.data);
      await context.read<RouteRepository>().sendSos(event);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
    }
  }

  Future<void> retryRoutePositions(BuildContext context, String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routePositions) return;

    try {
      final position = RoutePositionEntity.fromJson(operation.data);
      await context.read<RouteRepository>().sendRoutePositions([position]);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
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
        await context
            .read<RouteRepository>()
            .sendRoutePositions(positionsByRoute[routeId]!);
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

  Future<void> retryMaintenance(BuildContext context, String id) async {
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
      await context
          .read<MaintenanceProvider>()
          .submitMaintenanceData(maintenance, isRetry: true);

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
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryInspection(BuildContext context, String id) async {
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
      await context
          .read<InspectionProvider>()
          .submitInspectionData(inspection, isRetry: true);

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
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> retryRoutePositions(String id) async {
  //   final operation = await repository.getOperationById(id);
  //   if (operation == null ||
  //       operation.type != OfflineOperationType.routePositions) return;

  //   try {
  //     // Aquí deberías llamar al RouteProvider para reintentar el envío de posiciones
  //     // Ejemplo: await context.read<RouteProvider>().retryRoutePositions(operation.data['positions']);
  //     await repository.removeOperation(id);
  //     await loadOperations();
  //   } catch (e) {
  //     await repository.updateRetryCount(
  //         id, operation.retryCount + 1, e.toString());
  //     rethrow;
  //   }
  // }

  Future<void> retryRouteEvent(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null || operation.type != OfflineOperationType.routeEvent)
      return;

    try {
      // Aquí deberías llamar al RouteProvider para reintentar el evento de ruta
      // Ejemplo: await context.read<RouteProvider>().retryRouteEvent(operation.data);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
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

  Future<void> retryRouteRecovery(
      String opId, RouteProvider routeProvider, BuildContext context) async {
    final operation = await repository.getOperationById(opId);
    if (operation == null ||
        operation.type != OfflineOperationType.routeRecovery) return;
    try {
      // Se extrae el id de la ruta (asegúrate de que se guarde en los datos offline)
      final int routeId = operation.data['routeId'];
      // Se intenta reconsultar la ruta a través del provider (usa tu usecase existente)
      final route = await routeProvider.resumeRoute(routeId);
      // Si la recuperación fue exitosa, eliminar la operación offline y navegar
      await repository.removeOperation(opId);
      await loadOperations();
      Navigator.pushReplacementNamed(context, '/root/speedometer');
    } catch (e) {
      await repository.updateRetryCount(
          opId, (operation.retryCount + 1), e.toString());
      rethrow;
    }
  }

  Future<void> retryLatestRouteRecovery(BuildContext context) async {
    final operations = await repository.getRouteRecoveryOperations();
    if (operations.isEmpty) return;

    // Ordenar por fecha (más reciente primero)
    operations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await retryRouteRecovery(
        operations.first.id, context.read<RouteProvider>(), context);
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
}
