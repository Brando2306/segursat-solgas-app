import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/create_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/sync_service.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:http/http.dart' as http;

class MenuProvider with ChangeNotifier {
  final OfflineOperationsRepository offlineOperationsRepository;
  final RouteRepository routeRepository;
  final SyncService syncService;

  bool? buttonInspectionEnabled;
  bool? buttonRootEnabled;
  bool _hasPendingRoute = false;
  bool _hasInternet = true;
  bool _hasValidInspection = false;
  Map<String, dynamic>? _lastRouteData;

  // NUEVAS PROPIEDADES PARA OPERACIONES OFFLINE
  int _pendingOperationsCount = 0;
  bool _isLoadingOperations = false;

  bool get hasPendingRoute => _hasPendingRoute;
  bool get hasInternet => _hasInternet;
  bool get hasValidInspection => _hasValidInspection;
  Map<String, dynamic>? get lastRouteData => _lastRouteData;

  // GETTERS PARA OPERACIONES OFFLINE
  int get pendingOperationsCount => _pendingOperationsCount;
  bool get isLoadingOperations => _isLoadingOperations;

  MenuProvider({
    required this.offlineOperationsRepository,
    required this.routeRepository,
  }) : syncService = SyncService(offlineOperationsRepository, routeRepository);

  void clearPendingRoute() {
    _hasPendingRoute = false;
    _lastRouteData = null;
    notifyListeners();
  }

  Future<void> init() async {
    try {
      // CONSULTAS SIMULTÁNEAS - OPTIMIZACIÓN
      final unitFuture = _getUnit();
      final lastRouteFuture = _getLastRouteFromBackend();

      final results =
          await Future.wait([unitFuture, lastRouteFuture], eagerError: true);

      final unit = results[0] as Map<String, dynamic>;
      final lastRoute = results[1] as Map<String, dynamic>?;

      await _processUnitData(unit);
      await _processRouteData(unit, lastRoute);

      _hasInternet = true;
    } catch (e) {
      // Si falla, asumimos que no hay internet
      _hasInternet = false;
      _hasValidInspection = false;
      // 🚨 MEJORA: En caso de error, verificar offline más exhaustivamente
      _hasPendingRoute = await _checkOfflinePendingRoute() ||
          await _hasIncompleteRouteOperations();

      buttonInspectionEnabled = true;
      buttonRootEnabled = true;
    }

    // CARGAR CONTADOR DE OPERACIONES OFFLINE
    await _loadPendingOperationsCount();

    notifyListeners();
  }

  // NUEVO MÉTODO: Cargar contador de operaciones pendientes
  Future<void> _loadPendingOperationsCount() async {
    try {
      _isLoadingOperations = true;
      notifyListeners();

      final operations =
          await offlineOperationsRepository.getPendingOperations();

      // Filtrar solo las operaciones no sincronizadas
      final pendingOps =
          operations.where((op) => op.data['synced'] != true).toList();

      _pendingOperationsCount = pendingOps.length;

      // log('Operaciones offline pendientes: $_pendingOperationsCount');
    } catch (e) {
      // log('Error cargando contador de operaciones offline: $e');
      _pendingOperationsCount = 0;
    } finally {
      _isLoadingOperations = false;
      notifyListeners();
    }
  }

  // NUEVO MÉTODO: Actualizar contador (para llamar desde otras pantallas)
  Future<void> refreshPendingOperationsCount() async {
    await _loadPendingOperationsCount();
  }

  // NUEVO MÉTODO: Obtener estadísticas detalladas
  Future<Map<String, int>> getOfflineOperationsStatistics() async {
    try {
      final operations =
          await offlineOperationsRepository.getPendingOperations();
      final pendingOps =
          operations.where((op) => op.data['synced'] != true).toList();

      return {
        'total': pendingOps.length,
        'positions': pendingOps
            .where((op) => op.type == OfflineOperationType.routePositions)
            .length,
        'finish': pendingOps
            .where((op) => op.type == OfflineOperationType.routeFinish)
            .length,
        'cancel': pendingOps
            .where((op) => op.type == OfflineOperationType.routeCancel)
            .length,
        'emergency': pendingOps
            .where((op) => op.type == OfflineOperationType.emergencyCall)
            .length,
        'incidents': pendingOps
            .where((op) => op.type == OfflineOperationType.incidentReport)
            .length,
        'stops': pendingOps
            .where((op) => op.type == OfflineOperationType.routeStop)
            .length,
        'inspections': pendingOps
            .where((op) => op.type == OfflineOperationType.inspection)
            .length,
        'maintenance': pendingOps
            .where((op) => op.type == OfflineOperationType.maintenance)
            .length,
      };
    } catch (e) {
      // log('Error obteniendo estadísticas de operaciones: $e');
      return {
        'total': 0,
        'positions': 0,
        'finish': 0,
        'cancel': 0,
        'emergency': 0,
        'incidents': 0,
        'stops': 0,
        'inspections': 0,
        'maintenance': 0
      };
    }
  }

  // NUEVO MÉTODO: Para cuando se sincronice una operación exitosamente
  Future<void> onOperationSynced() async {
    await _loadPendingOperationsCount();
  }

  // El resto de tus métodos permanecen igual...
  Future<Map<String, dynamic>?> _getLastRouteFromBackend() async {
    try {
      final lastRouteId = readStorage('personal.lastRoute');
      if (lastRouteId == null) return null;

      final routeEntity = await routeRepository.getRoute(
        lastRouteId is int ? lastRouteId : int.parse(lastRouteId.toString()),
      );

      final routeMap = {
        'status': STATUSCODE.OK,
        'id': routeEntity.id,
        'unitid': routeEntity.unitId,
        'unit_name': routeEntity.unitName,
        'route_status': routeEntity.status,
        'positions': routeEntity.positions.map((p) => p.toJson()).toList(),
        'destination_latitude': routeEntity.destinationLatitude,
        'destination_longitude': routeEntity.destinationLongitude,
      };

      _lastRouteData = routeMap;
      return routeMap;
    } catch (e) {
      // log('Error al obtener última ruta del backend: $e');
      return null;
    }
  }

  Future<void> _processUnitData(Map<String, dynamic> unit) async {
    await writeStorage('personal.lastInitialInspectionDate',
        unit['last_initial_inspection_date']);
    await writeStorage('inspection.lastOdometer', unit['last_odometer']);

    final lastInspection = unit['last_initial_inspection_date'];
    _hasValidInspection = isNotEmptyString(lastInspection) &&
        DateFormat('yyyy-MM-dd').format(DateTime.now()) == lastInspection;

    buttonInspectionEnabled = !_hasValidInspection;
    buttonRootEnabled = _hasValidInspection;
  }

  Future<void> _processRouteData(
      Map<String, dynamic> unit, Map<String, dynamic>? lastRoute) async {
    final hasFinishedOffline = await _hasOfflineFinishedRoute();

    if (hasFinishedOffline) {
      // Snackbars.showSnackbarSuccess(
      //     '🐛 _processRouteData() - Ruta offline finalizada, no hay ruta pendiente');
      // log('=====🐛 _processRouteData() - Ruta offline finalizada, no hay ruta pendiente');
      _hasPendingRoute = false;
      return;
    }

    final hasBackendRoute = await _checkPendingRoute(unit);

    if (hasBackendRoute) {
      // Snackbars.showSnackbarSuccess(
      //     '🐛 _processRouteData() - Ruta backend pendiente encontrada');
      // log('=====🐛 _processRouteData() - Ruta backend pendiente encontrada');
      _hasPendingRoute = true;

      if (lastRoute != null && lastRoute['status'] == STATUSCODE.OK) {
        await _prepareRouteRecoveryData(lastRoute);
      }
    } else {
      // Snackbars.showSnackbarSuccess(
      //     '🐛 _processRouteData() - No hay ruta backend pendiente, verificando ruta offline');
      // log('=====🐛 _processRouteData() - No hay ruta backend pendiente, verificando ruta offline');
      _hasPendingRoute = await _checkOfflinePendingRoute() ||
          await _hasIncompleteRouteOperations();
    }
  }

  // NUEVO MÉTODO: Detectar rutas incompletas con operaciones pendientes
  Future<bool> _hasIncompleteRouteOperations() async {
    try {
      final offlineRouteId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineRouteId == null) {
        // log('🔍 _hasIncompleteRouteOperations - No hay offlineRouteId');
        return false;
      }

      final operations = await offlineOperationsRepository
          .getOperationsByOfflineId(offlineRouteId);

      // Filtrar solo operaciones no sincronizadas
      final pendingOps =
          operations.where((op) => op.data['synced'] != true).toList();

      if (pendingOps.isEmpty) {
        // log('🔍 _hasIncompleteRouteOperations - No hay operaciones pendientes');
        return false;
      }

      // Verificar si hay operaciones que indiquen ruta activa
      final hasRouteOperations = pendingOps.any((op) =>
          op.type == OfflineOperationType.routePositions ||
          op.type == OfflineOperationType.routeStop ||
          op.type == OfflineOperationType.incidentReport ||
          op.type == OfflineOperationType.routeSos);

      // Verificar que NO tenga finish o cancel (ruta aún activa)
      final hasFinishOrCancel = pendingOps.any((op) =>
          op.type == OfflineOperationType.routeFinish ||
          op.type == OfflineOperationType.routeCancel);

      final hasRouteCreation =
          pendingOps.any((op) => op.type == OfflineOperationType.routeCreation);

      // log('🔍 _hasIncompleteRouteOperations - '
      //     'hasRouteOperations: $hasRouteOperations, '
      //     'hasFinishOrCancel: $hasFinishOrCancel, '
      //     'hasRouteCreation: $hasRouteCreation, '
      //     'totalPending: ${pendingOps.length}');

      // Si tiene operaciones de ruta activa Y no está finalizada/cancelada
      final shouldRecover =
          (hasRouteOperations || hasRouteCreation) && !hasFinishOrCancel;

      if (shouldRecover) {
        // log('🚨 _hasIncompleteRouteOperations - Ruta pendiente detectada por operaciones incompletas');

        // Preparar datos para recuperación
        await _prepareOfflineRouteRecovery(offlineRouteId, pendingOps);
      }

      return shouldRecover;
    } catch (e) {
      // log('❌ _hasIncompleteRouteOperations - Error: $e');
      return false;
    }
  }

  // NUEVO MÉTODO: Preparar recuperación de ruta offline
  Future<void> _prepareOfflineRouteRecovery(
      String offlineRouteId, List<OfflineOperation> pendingOps) async {
    try {
      // Buscar la última posición para restaurar el cronómetro
      final positionOps = pendingOps
          .where((op) => op.type == OfflineOperationType.routePositions)
          .toList();

      if (positionOps.isNotEmpty) {
        // Obtener la última operación de posiciones
        final lastPositionOp = positionOps.reduce((curr, next) =>
            curr.createdAt.isAfter(next.createdAt) ? curr : next);

        final positions = (lastPositionOp.data['positions'] as List)
            .map((p) => RoutePositionEntity.fromJson(p))
            .toList();

        if (positions.isNotEmpty) {
          final lastPosition = positions.last;
          // Restaurar cronómetro desde la última posición
          await writeStorage('root.cronometer', lastPosition.angle ?? 0);
          // log('🔄 Cronómetro restaurado: ${lastPosition.angle}');
        }
      }

      // Buscar datos de la ruta en operaciones de creación
      final creationOps = pendingOps
          .where((op) => op.type == OfflineOperationType.routeCreation)
          .toList();

      if (creationOps.isNotEmpty) {
        final creationOp = creationOps.first;
        final route = CreateRouteEntity.fromJson(creationOp.data);

        // Restaurar posición final si existe
        if (route.destinationLatitude != null &&
            route.destinationLongitude != null) {
          await writeStorage(
              'root.finalPosition',
              json.encode({
                'latitude': double.parse(route.destinationLatitude.toString()),
                'longitude': double.parse(route.destinationLongitude.toString())
              }));
          // log('🔄 Posición final restaurada desde creación offline');
        }
      }

      // log('✅ Preparación de recuperación offline completada');
    } catch (e) {
      // log('❌ Error en _prepareOfflineRouteRecovery: $e');
    }
  }

  Future<void> _prepareRouteRecoveryData(Map<String, dynamic> route) async {
    if (route['status'] == STATUSCODE.OK) {
      final positions = route['positions'];
      if (isNotEmptyString(positions)) {
        final lastObject = positions.last;
        await writeStorage('root.cronometer',
            isNotEmptyString(lastObject['angle']) ? lastObject['angle'] : 0);
      }

      if (isNotEmptyString(route['destination_latitude']) &&
          isNotEmptyString(route['destination_longitude'])) {
        await writeStorage(
            'root.finalPosition',
            json.encode({
              'latitude': route['destination_latitude'],
              'longitude': route['destination_longitude']
            }));
      }
    }
  }

  Future<bool> _prepareOfflineRouteData() async {
    try {
      final finalPos = readStorage('root.finalPosition');
      if (finalPos == null) {
        // log('No hay posición final guardada para recuperación offline');
        return false;
      }

      if (readStorage('root.currentPosition') == null) {
        try {
          final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best);
          await writeStorage(
            'root.currentPosition',
            json.encode({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          );
          // log('Posición actual obtenida para recuperación offline');
        } catch (e) {
          // log('No se pudo obtener posición actual para recuperación offline: $e');
        }
      }

      if (readStorage('root.cronometer') == null) {
        await writeStorage('root.cronometer', '0');
        // log('Cronómetro inicializado a 0 para recuperación offline');
      }

      return true;
    } catch (e) {
      // log('Error en _prepareOfflineRouteData: $e');
      return false;
    }
  }

  Future<bool> checkAndPrepareRouteRecovery() async {
    if (_hasInternet && _lastRouteData != null) {
      return true;
    } else if (!_hasInternet) {
      return await _prepareOfflineRouteData();
    }
    return false;
  }

  Future<bool> _hasOfflineFinishedRoute() async {
    try {
      final offlineRouteId = readStorage(StorageKeys.currentOfflineRouteId);
      if (offlineRouteId == null) return false;

      final ops = await offlineOperationsRepository
          .getOperationsByOfflineId(offlineRouteId);

      final hasUnsyncedFinishOrCancel = ops.any((op) =>
          (op.type == OfflineOperationType.routeFinish ||
              op.type == OfflineOperationType.routeCancel) &&
          op.data['synced'] != true);

      return hasUnsyncedFinishOrCancel;
    } catch (e) {
      // log('Error checking offline finished routes: $e');
      return false;
    }
  }

  Future<bool> _checkOfflinePendingRoute() async {
    final offlineRouteId = readStorage(StorageKeys.currentOfflineRouteId);

    // Snackbars.showSnackbarSuccess(
    //     '🐛 _checkOfflinePendingRoute() - offlineRouteId: $offlineRouteId');
    // log('======🐛 _checkOfflinePendingRoute() - offlineRouteId: $offlineRouteId');

    if (offlineRouteId == null) {
      // Snackbars.showSnackbarSuccess(
      //     '🐛 _checkOfflinePendingRoute() - NO hay offlineRouteId, retornando false');
      // log('======🐛 _checkOfflinePendingRoute() - NO hay offlineRouteId, retornando false');
      return false;
    }

    // 🎯 NUEVA VERIFICACIÓN: Si ya tenemos una ruta activa en curso, no recuperar una anterior
    final currentRouteId = readStorage('root.createRoute.id');
    if (currentRouteId != null) {
      // Snackbars.showSnackbarSuccess(
      //     '🐛 _checkOfflinePendingRoute() - Ya hay ruta activa (ID: $currentRouteId), no recuperar offline');
      // log('======🐛 _checkOfflinePendingRoute() - Ya hay ruta activa (ID: $currentRouteId), no recuperar offline');
      return false;
    }

    final ops = await offlineOperationsRepository
        .getOperationsByOfflineId(offlineRouteId);
    final hasFinishOrCancel = ops.any((op) =>
        op.type == OfflineOperationType.routeFinish ||
        op.type == OfflineOperationType.routeCancel);

    if (hasFinishOrCancel) {
      final allSynced = ops.every((op) => op.data['synced'] == true);
      if (!allSynced) return false;
    }

    final positionOps =
        ops.where((op) => op.type == OfflineOperationType.routePositions);

    // Snackbars.showSnackbarSuccess(
    //     '🐛 _checkOfflinePendingRoute() - positionOps: ${positionOps.length}');
    // log('======🐛 _checkOfflinePendingRoute() - positionOps: ${positionOps.length}');

    // 🎯 CAMBIO CLAVE: Si no hay posiciones, no hay ruta para recuperar
    if (positionOps.isEmpty) return false; // ← NUEVA LÍNEA

    // Snackbars.showSnackbarSuccess(
    //     '🐛 _checkOfflinePendingRoute() - positionOps no está vacío, procesando...');
    // log('======🐛 _checkOfflinePendingRoute() - positionOps no está vacío, procesando...');

    final lastOp = positionOps.reduce(
        (curr, next) => curr.createdAt.isAfter(next.createdAt) ? curr : next);
    final positions = (lastOp.data['positions'] as List)
        .map((p) => RoutePositionEntity.fromJson(p))
        .toList();

    if (positions.isNotEmpty) {
      final lastPosition = positions.last;
      await writeStorage('root.cronometer', lastPosition.angle ?? 0);
      await writeStorage(
          'root.currentPosition',
          json.encode({
            'latitude': lastPosition.latitude,
            'longitude': lastPosition.longitude
          }));
    }

    // Snackbars.showSnackbarSuccess(
    //     '🐛 _checkOfflinePendingRoute() - Ruta offline pendiente encontrada');
    // log('======🐛 _checkOfflinePendingRoute() - Ruta offline pendiente encontrada');
    return true;
  }

  Future<bool> _checkPendingRoute(Map<String, dynamic> unit) async {
    final lastRouteStatus = unit['last_route_status'];
    final lastRouteId = unit['last_route'];

    if (lastRouteStatus == 'R' && lastRouteId != null) {
      await writeStorage('personal.lastRoute', lastRouteId);
      await writeStorage('root.createRoute.id', lastRouteId);
      await writeStorage('personal.lastRouteStatus', lastRouteStatus);
      return true;
    }
    return false;
  }

  Future<bool> syncPendingRoutesAndContinue() async {
    try {
      if (!_hasInternet) {
        return false;
      }

      EasyLoading.show(status: 'Sincronizando rutas pendientes...');
      final result = await syncService.syncPendingRoutes();
      EasyLoading.dismiss();

      if (result.failed > 0) {
        // log('Sincronización completada con ${result.failed} errores');
        // Puedes manejar errores parciales aquí
      }

      return result.successful > 0 || result.total == 0;
    } catch (e) {
      EasyLoading.dismiss();
      // log('Error en syncPendingRoutesAndContinue: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getUnit() async {
    final url = Uri.http(
      ENDPOINTS.HOST,
      ENDPOINTS.GET_UNIT
          .replaceAll('<name>', readStorage('personal.licensePlate')),
    );

    final response = await http.get(url, headers: {
      "Content-Type": "application/json",
      'Authorization': ENDPOINTS.auth(),
    });

    if (response.statusCode != STATUSCODE.OK) {
      throw Exception('Failed to load unit data');
    }

    return json.decode(response.body);
  }
}
