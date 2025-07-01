import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:http/http.dart' as http;

class MenuProvider with ChangeNotifier {
  final OfflineOperationsRepository offlineOperationsRepository;
  bool? buttonInspectionEnabled;
  bool? buttonRootEnabled;
  bool _hasPendingRoute = false;

  bool get hasPendingRoute => _hasPendingRoute;

  MenuProvider({required this.offlineOperationsRepository});

  void clearPendingRoute() {
    _hasPendingRoute = false;
    notifyListeners();
  }

  Future<void> init() async {
    try {
      final unit = await _getUnit();

      await writeStorage('personal.lastInitialInspectionDate',
          unit['last_initial_inspection_date']);
      await writeStorage('inspection.lastOdometer', unit['last_odometer']);

      final lastInspection = unit['last_initial_inspection_date'];
      final hasValidInspection = isNotEmptyString(lastInspection) &&
          DateFormat('yyyy-MM-dd').format(DateTime.now()) == lastInspection;

      buttonInspectionEnabled = !hasValidInspection;
      buttonRootEnabled = hasValidInspection;

      _hasPendingRoute = await _checkPendingRoute(unit);
    } catch (e) {
      _hasPendingRoute = await _checkOfflinePendingRoute();
      // Si hay error, habilita los botones
      buttonInspectionEnabled = true;
      buttonRootEnabled = true;
    }

    notifyListeners();
  }

  Future<bool> _checkOfflinePendingRoute() async {
    // 1. Verificar si hay una ruta activa en almacenamiento local
    final offlineRouteId = readStorage(StorageKeys.currentOfflineRouteId);
    if (offlineRouteId == null) return false;

    // 2. Verificar si la ruta no fue finalizada/cancelada
    final ops = await offlineOperationsRepository
        .getOperationsByOfflineId(offlineRouteId);
    final hasFinishOrCancel = ops.any((op) =>
        op.type == OfflineOperationType.routeFinish ||
        op.type == OfflineOperationType.routeCancel);

    if (hasFinishOrCancel) {
      // Verificar si TODAS las operaciones están sincronizadas
      final allSynced = ops.every((op) => op.data['synced'] == true);

      if (!allSynced) {
        // Ruta completa pero no sincronizada → No mostrar como pendiente
        return false;
      }
    }

    // 3. Recuperar última posición si existe
    final positionOps =
        ops.where((op) => op.type == OfflineOperationType.routePositions);
    if (positionOps.isNotEmpty) {
      final lastOp = positionOps.reduce(
          (curr, next) => curr.createdAt.isAfter(next.createdAt) ? curr : next);
      final positions = (lastOp.data['positions'] as List)
          .map((p) => RoutePositionEntity.fromJson(p))
          .toList();

      if (positions.isNotEmpty) {
        final lastPosition = positions.last;
        await writeStorage('root.cronometer', lastPosition.angle ?? 0);
        log('message: Última posición recuperada: $lastPosition');
        log('lastPosition.angle: ${lastPosition.angle}');
        await writeStorage(
            'root.currentPosition',
            json.encode({
              'latitude': lastPosition.latitude,
              'longitude': lastPosition.longitude
            }));
      }
    }

    return true;
  }

  Future<bool> _checkPendingRoute(Map<String, dynamic> unit) async {
    // Verificar si hay una ruta activa en el servidor o en almacenamiento local
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
