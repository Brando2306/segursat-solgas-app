import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/cancel_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/create_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/finish_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/emergency_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

class SpeedometerProvider with ChangeNotifier {
  late final RouteRepository routeRepository;
  late final OfflineOperationsRepository offlineOperationsRepository;

  SpeedometerProvider(
      {required this.routeRepository,
      required this.offlineOperationsRepository});

  // Stream subscriptions
  StreamSubscription<Position>? _positionStream;
  late LocationSettings _locationSettings;

  // State variables
  double _speed = 0;
  DateTime _currentTime = DateTime.now();
  Duration _currentDuration = Duration.zero;
  bool _buttonFinishEnabled = true;
  bool _hasInternetConnection = true;

  // Timers
  Timer? _dateTimer;
  Timer? _durationTimer;
  Timer? _dataSendTimer;
  Timer? _internetCheckTimer;

  // Getters
  double get speed => _speed;
  DateTime get currentTime => _currentTime;
  Duration get currentDuration => _currentDuration;
  bool get buttonFinishEnabled => _buttonFinishEnabled;
  bool get hasInternetConnection => _hasInternetConnection;

  // Format helpers
  String get formattedTime =>
      DateFormat('dd/MM/yyyy HH:mm:ss').format(_currentTime);
  String get formattedDuration {
    try {
      final duration =
          _currentDuration; // Copia local para evitar condiciones de carrera
      String twoDigits(int n) => n >= 10 ? "$n" : "0$n";
      return "${twoDigits(duration.inMinutes.remainder(60))}:"
          "${twoDigits(duration.inSeconds.remainder(60))}";
    } catch (e) {
      return "00:00"; // Valor por defecto en caso de error
    }
  }

  // Initialization
  Future<void> initialize() async {
    _buttonFinishEnabled = true;
    await _setupLocationStream();
    await createOrResumeRoute();
    _initializeTimers();
    _checkConnectivity();
  }

  Future<void> _setupLocationStream() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "La aplicación continuará recibiendo tu ubicación incluso cuando no la estés utilizando",
          notificationTitle: "Corriendo en segundo plano",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      _locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    } else {
      _locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position? position) {
      if (position != null) {
        _updatePosition(position);
      }
    });
  }

  void _updatePosition(Position position) {
    writeStorage(
      'root.currentPosition',
      json.encode(
          {'latitude': position.latitude, 'longitude': position.longitude}),
    );

    _speed = position.speed * 3.6;
    notifyListeners();
  }

  Future<void> createOrResumeRoute() async {
    try {
      if (isNotEmptyString(readStorage('root.cronometer')) &&
          isNotEmptyString(readStorage('root.finalPosition'))) {
        if (isNotEmptyString(readStorage('personal.lastRoute'))) {
          writeStorage(
              'root.createRoute.id', readStorage('personal.lastRoute'));
        }
      } else {
        final initialPosition =
            json.decode(readStorage('root.initialPosition'));
        final finalPosition = json.decode(readStorage('root.finalPosition'));

        final route = CreateRouteEntity(
          unitName: readStorage('personal.licensePlate'),
          timestamp: getDate(),
          sourceLatitude: initialPosition['latitude'],
          sourceLongitude: initialPosition['longitude'],
          destinationLatitude: finalPosition['latitude'],
          destinationLongitude: finalPosition['longitude'],
        );

        final createdRoute = await routeRepository.createRoute(route);
        writeStorage('root.createRoute.id', createdRoute.id);
      }
    } catch (e) {
      log('Error creating or resuming route: $e');
    }
  }

  void _initializeTimers() {
    // Initialize duration from storage or zero
    try {
      final savedTime =
          int.tryParse(readStorage('root.cronometer') ?? '0') ?? 0;
      _currentDuration = Duration(seconds: savedTime);
    } catch (e) {
      _currentDuration = Duration.zero;
    }

    // Timer for duration
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      try {
        _currentDuration += const Duration(seconds: 1);
        writeStorage('root.cronometer', _currentDuration.inSeconds.toString());
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating duration: $e');
      }
    });

    // Timer for current time
    _dateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });

    // Timer for sending position data
    _dataSendTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _attemptToSendPosition();
      _updatePendingPositionsCount();
    });

    // Timer for internet connectivity check
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult != ConnectivityResult.none;

    if (hasConnection != _hasInternetConnection) {
      _hasInternetConnection = hasConnection;
      notifyListeners();

      if (hasConnection) {
        _retrySendingStoredPositions();
      }
    }
  }

  Future<void> _attemptToSendPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final positionData = RoutePositionEntity(
        routeId: readStorage('root.createRoute.id'),
        unitId: readStorage('personal.unitId'),
        timestamp: getDate(),
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        speed: position.speed,
        angle: _currentDuration.inSeconds,
      );

      // Intentamos enviar la posición actual y cualquier posición pendiente
      // await _sendPositions([positionData]);
      await routeRepository.sendRoutePositions([positionData]);
    } catch (e) {
      log('Error sending position: $e');
    }
  }

  int _pendingPositionsCountValue = 0;

  int get pendingPositionsCountValue => _pendingPositionsCountValue;

  Future<void> _updatePendingPositionsCount() async {
    final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
    if (offlineId == null) {
      _pendingPositionsCountValue = 0;
      notifyListeners();
      return;
    }

    final operations =
        await offlineOperationsRepository.getOperationsByOfflineId(offlineId);
    final positionOps = operations
        .where((op) => op.type == OfflineOperationType.routePositions);

    int total = 0;
    for (final op in positionOps) {
      total += (op.data['positions'] as List).length;
    }

    if (total != _pendingPositionsCountValue) {
      _pendingPositionsCountValue = total;
      notifyListeners();
    }
  }

  Future<void> _retrySendingStoredPositions() async {
    final offlineId = readStorage(StorageKeys.currentOfflineRouteId);
    if (offlineId == null) return;

    // Obtener todas las posiciones pendientes para esta ruta
    final operations =
        await offlineOperationsRepository.getOperationsByOfflineId(offlineId);
    final positionOps = operations
        .where((op) => op.type == OfflineOperationType.routePositions);

    if (positionOps.isEmpty) return;

    try {
      // Extraer y unir todas las posiciones fallidas
      final allPositions = <RoutePositionEntity>[];
      for (final op in positionOps) {
        final positions = (op.data['positions'] as List)
            .map((p) => RoutePositionEntity.fromJson(p))
            .toList();
        allPositions.addAll(positions);
      }

      // Enviar en lotes de 25
      const batchSize = 25;
      for (int i = 0; i < allPositions.length; i += batchSize) {
        final end = (i + batchSize < allPositions.length)
            ? i + batchSize
            : allPositions.length;
        final batch = allPositions.sublist(i, end);
        await routeRepository.sendRoutePositions(batch);
      }

      // Eliminar las operaciones ya sincronizadas
      for (final op in positionOps) {
        await offlineOperationsRepository.removeOperation(op.id);
      }
    } catch (e) {
      log('Error al reenviar posiciones: $e');
    }
  }

  Future<void> finishRoute({bool isEmergency = false}) async {
    _buttonFinishEnabled = false;
    notifyListeners();

    try {
      final currentPosition = await Geolocator.getCurrentPosition();
      final routeId = readStorage('root.createRoute.id');

      if (isEmergency || readStorage('root.type') == ROOT_TYPE.SOS) {
        final route = CancelRouteEntity(
          routeId: routeId,
          cancelTimestamp: getDate(),
          cancelLatitude: currentPosition.latitude,
          cancelLongitude: currentPosition.longitude,
          time: readStorage('root.cronometer') ?? 0,
        );

        await routeRepository.cancelRoute(route);
      } else {
        final route = FinishRouteEntity(
          routeId: routeId,
          finishTimestamp: getDate(),
          finishLatitude: currentPosition.latitude,
          finishLongitude: currentPosition.longitude,
          time: readStorage('root.cronometer') ?? 0,
        );

        await routeRepository.finishRoute(route);
      }

      //TODO: Limpiar Rutas

      _cleanup();
    } catch (e) {
      _buttonFinishEnabled = true;
      notifyListeners();

      _cleanup();
      // rethrow;
    }
  }

  Future<void> triggerEmergency() async {
    final currentPosition = await Geolocator.getCurrentPosition();
    final routeId = readStorage('root.createRoute.id');
    final offlineId = readStorage(StorageKeys.currentOfflineRouteId) ??
        '${StorageKeys.offlineRoutePrefix}${DateTime.now().millisecondsSinceEpoch}';

    // Verificar si ya hay operaciones de emergencia para esta ruta
    final existingOps =
        await offlineOperationsRepository.getOperationsByOfflineId(offlineId);
    final hasExistingSos =
        existingOps.any((op) => op.type == OfflineOperationType.routeSos);
    final hasExistingCall =
        existingOps.any((op) => op.type == OfflineOperationType.emergencyCall);
    final hasExistingCancel =
        existingOps.any((op) => op.type == OfflineOperationType.routeCancel);

    // 1. Paso SOS - Solo si no existe ya
    if (!hasExistingSos) {
      await _executeEmergencyStep(
        action: () {
          final event = EmergencyEventEntity(
            routeId: routeId,
            unitId: readStorage('personal.unitId'),
            timestamp: getDate(),
            latitude: currentPosition.latitude,
            longitude: currentPosition.longitude,
          );
          return routeRepository.sendSos(event);
        },
        offlineType: OfflineOperationType.routeSos,
        offlineData: {
          'routeId': routeId,
          'unitId': readStorage('personal.unitId'),
          'timestamp': getDate(),
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
        },
        offlineId: offlineId,
      );
    }

    // 2. Paso Llamada - Solo si no existe ya
    if (!hasExistingCall) {
      await _executeEmergencyStep(
        action: () async {
          final phoneNumber = await routeRepository.getEmergencyPhoneNumber();
          final url = Uri(scheme: 'tel', path: phoneNumber);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            throw Exception('No se pudo iniciar la llamada');
          }
        },
        offlineType: OfflineOperationType.emergencyCall,
        offlineData: {
          'timestamp': DateTime.now().toIso8601String(),
        },
        offlineId: offlineId,
      );
    }

    // 3. Paso Cancelación - Solo si no existe ya
    if (!hasExistingCancel) {
      await _executeEmergencyStep(
        action: () {
          final route = CancelRouteEntity(
            routeId: routeId,
            cancelTimestamp: getDate(),
            cancelLatitude: currentPosition.latitude,
            cancelLongitude: currentPosition.longitude,
            time: readStorage('root.cronometer') ?? 0,
          );
          return routeRepository.cancelRoute(route);
        },
        offlineType: OfflineOperationType.routeCancel,
        offlineData: {
          'routeId': routeId,
          'cancelTimestamp': getDate(),
          'cancelLatitude': currentPosition.latitude,
          'cancelLongitude': currentPosition.longitude,
          'time': readStorage('root.cronometer') ?? 0,
        },
        offlineId: offlineId,
      );
    }

    _cleanup();
  }

  Future<void> _executeEmergencyStep({
    required Future<void> Function() action,
    required OfflineOperationType offlineType,
    required Map<String, dynamic> offlineData,
    required String offlineId,
  }) async {
    try {
      // Verificar si ya existe una operación similar no sincronizada
      final existingOps =
          await offlineOperationsRepository.getOperationsByOfflineId(offlineId);
      final existingOp = existingOps.firstWhereOrNull(
          (op) => op.type == offlineType && op.data['synced'] != true);

      if (existingOp != null) {
        // Si ya existe una operación no sincronizada, no hacemos nada
        return;
      }

      await action();
    } catch (e) {
      log('Error en operación $offlineType, guardando offline: $e');

      // Verificar nuevamente antes de guardar para evitar duplicados
      final existingOps =
          await offlineOperationsRepository.getOperationsByOfflineId(offlineId);
      final hasExisting = existingOps
          .any((op) => op.type == offlineType && op.data['synced'] != true);

      if (!hasExisting) {
        await offlineOperationsRepository.saveOperation(
          OfflineOperation(
            type: offlineType,
            data: offlineData,
            offlineRouteId: offlineId,
          ),
        );
      }
    }
  }

  Future<void> callEmergencyPhone() async {
    try {
      final phoneNumber = await routeRepository.getEmergencyPhoneNumber();
      final url = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw Exception('Could not launch phone call');
      }
    } catch (e) {
      log('Emergency call failed: $e');
      rethrow;
    }
  }

  void stopLocationUpdates() {
    _positionStream?.cancel();
    _dateTimer?.cancel();
    _durationTimer?.cancel();
    _dataSendTimer?.cancel();
    _internetCheckTimer?.cancel();
  }

  void clearStorages() {
    cleanQuestionStorage();
    cleanResumeRoute();
    cleanRoot();
    cleanRootRecurringStop();
  }

  void _cleanup() {
    stopLocationUpdates();
    clearStorages();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _dateTimer?.cancel();
    _durationTimer?.cancel();
    _dataSendTimer?.cancel();
    _internetCheckTimer?.cancel();

    _positionStream = null;
    _dateTimer = null;
    _durationTimer = null;
    _dataSendTimer = null;
    _internetCheckTimer = null;

    super.dispose();
  }
}
