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

  // Métodos específicos para tipos de operaciones
  Future<void> retryRouteCreation(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routeRecovery) return;

    try {
      // Aquí deberías llamar al RouteProvider para reintentar la creación de ruta
      // Ejemplo: await context.read<RouteProvider>().retryRouteCreation(operation.data['routeId']);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
    }
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

  Future<void> retryRoutePositions(String id) async {
    final operation = await repository.getOperationById(id);
    if (operation == null ||
        operation.type != OfflineOperationType.routePositions) return;

    try {
      // Aquí deberías llamar al RouteProvider para reintentar el envío de posiciones
      // Ejemplo: await context.read<RouteProvider>().retryRoutePositions(operation.data['positions']);
      await repository.removeOperation(id);
      await loadOperations();
    } catch (e) {
      await repository.updateRetryCount(
          id, operation.retryCount + 1, e.toString());
      rethrow;
    }
  }

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
}
