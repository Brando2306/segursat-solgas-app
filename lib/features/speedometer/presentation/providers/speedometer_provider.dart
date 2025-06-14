// lib/providers/speedometer_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/providers/index.dart';
import 'package:safe_driving_app/providers/route.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

class SpeedometerProvider with ChangeNotifier {
  late final RouteRepository routeRepository;
  late final OfflineOperationsRepository offlineOperationsRepository;

  SpeedometerProvider({
    required this.routeRepository,
    required this.offlineOperationsRepository,
  });

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
    String twoDigits(int n) => n >= 10 ? "$n" : "0$n";
    return "${twoDigits(_currentDuration.inMinutes.remainder(60))}:"
        "${twoDigits(_currentDuration.inSeconds.remainder(60))}";
  }

  // Initialization
  Future<void> initialize() async {
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

  // Future<void> createOrResumeRoute() async {
  //   try {
  //     if (isNotEmptyString(readStorage('root.cronometer'))) {
  //       if (isNotEmptyString(readStorage('personal.lastRoute'))) {
  //         writeStorage(
  //             'root.createRoute.id', readStorage('personal.lastRoute'));
  //       }
  //     } else {
  //       final route = await createRoute();
  //       writeStorage('root.createRoute.id', route['id']);
  //     }
  //   } catch (e) {
  //     log('Error creating/resuming route: $e');
  //   }
  // }

  Future<void> createOrResumeRoute() async {
    try {
      if (isNotEmptyString(readStorage('root.cronometer'))) {
        // Si ya hay una ruta en progreso
        if (isNotEmptyString(readStorage('personal.lastRoute'))) {
          writeStorage(
              'root.createRoute.id', readStorage('personal.lastRoute'));

          final pendingCreation = await offlineOperationsRepository
              .getOperationsByType(OfflineOperationType.routeCreation)
              .then((ops) => ops.firstWhereOrNull(
                    (op) =>
                        RouteEntity.fromJson(op.data).id ==
                        readStorage('personal.lastRoute'),
                  ));

          if (pendingCreation != null) {
            // Necesitarías acceder al OfflineOperationsProvider aquí
            // Esto debería hacerse en el método que llama a createOrResumeRoute
            // o pasar el provider como parámetro
          }
        }
      } else {
        // Crear nueva ruta
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
      log('Error creating/resuming route: $e');

      // Si falla, verificar si hay una ruta pendiente en offline
      final pendingRoutes = await offlineOperationsRepository
          .getOperationsByType(OfflineOperationType.routeCreation);

      if (pendingRoutes.isNotEmpty) {
        // Usar la ruta pendiente más reciente
        final latestRouteOp = pendingRoutes.reduce(
          (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
        );

        final pendingRoute = RouteEntity.fromJson(latestRouteOp.data);
        writeStorage('root.createRoute.id', pendingRoute.id);
      } else {
        // No hay ruta pendiente y no se pudo crear una nueva
        throw Exception('No se pudo crear o reanudar la ruta');
      }
    }
  }

  void _initializeTimers() {
    // Initialize duration from storage or zero
    final savedTime = readStorage('root.cronometer') ?? 0;
    _currentDuration = Duration(seconds: savedTime);

    // Timer for duration
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentDuration += const Duration(seconds: 1);
      writeStorage('root.cronometer', _currentDuration.inSeconds);
      notifyListeners();
    });

    // Timer for current time
    _dateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });

    // Timer for sending position data
    _dataSendTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _attemptToSendPosition();
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

  // Future<void> _attemptToSendPosition() async {
  //   try {
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     final positionData = {
  //       "unitid": readStorage('personal.unitId'),
  //       "routeid": readStorage('root.createRoute.id'),
  //       "timestamp": getDate(),
  //       "latitude": position.latitude,
  //       "longitude": position.longitude,
  //       "altitude": position.altitude,
  //       "speed": position.speed.round(),
  //       "angle": _currentDuration.inSeconds,
  //     };

  //     await _createRoutePositions([positionData]);
  //   } catch (e) {
  //     log('Error sending position: $e');
  //   }
  // }

  Future<void> _attemptToSendPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final positionData = RoutePositionEntity(
        routeId: readStorage('root.createRoute.id'),
        unitId: readStorage('personal.unitId'),
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        speed: position.speed,
        angle: _currentDuration.inSeconds,
      );

      // Intentamos enviar la posición actual y cualquier posición pendiente
      await _sendPositions([positionData]);
    } catch (e) {
      log('Error sending position: $e');
    }
  }

  int get pendingPositionsCount {
    final savedPositions = readStorage('savedPositions')?.cast<String>() ?? [];
    return savedPositions.length;
  }

  Future<void> _sendPositions(List<RoutePositionEntity> positions) async {
    try {
      await routeRepository.sendRoutePositions(positions);
      // Si se enviaron correctamente, eliminamos cualquier posición pendiente del almacenamiento local
      writeStorage('savedPositions', []);
      notifyListeners();
    } catch (e) {
      // En caso de error, guardamos las posiciones localmente
      List<String> savedPositions =
          readStorage('savedPositions')?.cast<String>() ?? [];
      savedPositions.addAll(positions.map((p) => json.encode(p.toJson())));
      writeStorage('savedPositions', savedPositions);
      notifyListeners();
      log('Positions saved locally: ${savedPositions.length}');
    }
  }

  Future<void> _createRoutePositions(
      List<Map<String, dynamic>> positions) async {
    try {
      final url = Uri.parse(
        'http://sfdev.segursat.com/web/api/control/insert-route-positions-batch/',
      );

      final response = await http.post(
        url,
        body: jsonEncode(positions),
        headers: {
          "Content-Type": "application/json",
          'Authorization': ENDPOINTS.auth(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == STATUSCODE.OK) {
        log('Positions sent successfully');
      } else {
        throw Exception('Failed to send positions');
      }
    } catch (e) {
      log('Failed to send positions: $e');
      _savePositionsLocally(positions);
      rethrow;
    }
  }

  void _savePositionsLocally(List<Map<String, dynamic>> positions) {
    List<String> savedPositions =
        readStorage('savedPositions')?.cast<String>() ?? [];

    for (final position in positions) {
      savedPositions.add(json.encode(position));
    }

    writeStorage('savedPositions', savedPositions);
    log('Positions saved locally: ${savedPositions.length}');
  }

  Future<void> _retrySendingStoredPositions() async {
    final savedPositions = readStorage('savedPositions')?.cast<String>() ?? [];

    if (savedPositions.isEmpty) return;

    try {
      const batchSize = 25;
      final batches = <List<Map<String, dynamic>>>[];

      // Split into batches
      for (int i = 0; i < savedPositions.length; i += batchSize) {
        final end = i + batchSize < savedPositions.length
            ? i + batchSize
            : savedPositions.length;
        final batch = savedPositions
            .sublist(i, end)
            .map((p) => json.decode(p) as Map<String, dynamic>)
            .toList();
        batches.add(batch);
      }

      // Send each batch
      for (final batch in batches) {
        await _createRoutePositions(batch);
      }

      // Clear storage if all batches succeeded
      writeStorage('savedPositions', []);
      log('All stored positions sent successfully');
    } catch (e) {
      log('Failed to resend stored positions: $e');
    }
  }

  // Future<void> finishRoute({bool isEmergency = false}) async {
  //   _buttonFinishEnabled = false;
  //   notifyListeners();

  //   try {
  //     Map<String, dynamic> response;

  //     if (isEmergency || readStorage('root.type') == ROOT_TYPE.SOS) {
  //       response = await cancelRouteProvider();
  //     } else {
  //       response = await finishRouteProvider();
  //     }

  //     if (response['status'] == STATUSCODE.OK) {
  //       _cleanup();
  //     } else {
  //       throw Exception(handleApiError(response));
  //     }
  //   } catch (e) {
  //     _buttonFinishEnabled = true;
  //     notifyListeners();
  //     rethrow;
  //   }
  // }
  Future<void> finishRoute({bool isEmergency = false}) async {
    _buttonFinishEnabled = false;
    notifyListeners();

    try {
      final currentPosition = await Geolocator.getCurrentPosition();

      if (isEmergency || readStorage('root.type') == ROOT_TYPE.SOS) {
        final route = RouteEntity(
          id: readStorage('root.createRoute.id'),
          unitName: readStorage('personal.licensePlate'),
          timestamp: DateTime.now(),
          sourceLatitude:
              json.decode(readStorage('root.initialPosition'))['latitude'],
          sourceLongitude:
              json.decode(readStorage('root.initialPosition'))['longitude'],
          destinationLatitude:
              json.decode(readStorage('root.finalPosition'))['latitude'],
          destinationLongitude:
              json.decode(readStorage('root.finalPosition'))['longitude'],
          duration: _currentDuration.inSeconds,
        );
        await routeRepository.cancelRoute(route);
      } else {
        final route = FinishRouteEntity(
          routeId: readStorage('root.createRoute.id'),
          finishTimestamp: getDate(),
          finishLatitude: currentPosition.latitude,
          finishLongitude: currentPosition.longitude,
          time: readStorage('root.cronometer') ?? 0,
        );
        await routeRepository.finishRoute(route);
      }

      // Enviar cualquier posición pendiente antes de limpiar
      await _sendPendingPositions();

      _cleanup();
    } catch (e) {
      _buttonFinishEnabled = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _sendPendingPositions() async {
    final savedPositions = readStorage('savedPositions')?.cast<String>() ?? [];
    if (savedPositions.isEmpty) return;

    try {
      final positions = savedPositions
          .map((p) => RoutePositionEntity.fromJson(json.decode(p)))
          .toList();

      await routeRepository.sendRoutePositions(positions);
      writeStorage('savedPositions', []);
    } catch (e) {
      log('Failed to send pending positions: $e');
    }
  }

  void _cleanup() {
    _positionStream?.cancel();
    _dateTimer?.cancel();
    _durationTimer?.cancel();
    _dataSendTimer?.cancel();
    _internetCheckTimer?.cancel();

    cleanQuestionStorage();
    cleanResumeRoute();
    cleanRoot();
    cleanRootRecurringStop();
  }

  // Future<void> triggerEmergency() async {
  //   try {
  //     await sendEmergencyNotification();
  //     await callEmergencyPhone();
  //     await finishRoute(isEmergency: true);
  //   } catch (e) {
  //     log('Emergency trigger failed: $e');
  //     rethrow;
  //   }
  // }

  Future<void> triggerEmergency() async {
    try {
      final currentPosition = await Geolocator.getCurrentPosition();
      final event = RouteEventEntity(
        routeId: readStorage('root.createRoute.id'),
        unitId: readStorage('personal.unitId'),
        timestamp: DateTime.now(),
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        eventType: 'SOS',
      );

      await routeRepository.sendSos(event);
      await callEmergencyPhone();
      await finishRoute(isEmergency: true);
    } catch (e) {
      log('Emergency trigger failed: $e');
      rethrow;
    }
  }

  Future<void> sendEmergencyNotification() async {
    try {
      final response = await postInsertRouteSos();

      if (response['status'] != STATUSCODE.OK) {
        throw Exception('Failed to send emergency notification');
      }
    } catch (e) {
      log('Emergency notification failed: $e');
      rethrow;
    }
  }

  Future<void> callEmergencyPhone() async {
    try {
      final response = await getEmergencyNumber();

      if (response['status'] == STATUSCODE.OK) {
        final url = Uri(scheme: 'tel', path: response['emergency_phone']);

        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      }
    } catch (e) {
      log('Emergency call failed: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _dateTimer?.cancel();
    _durationTimer?.cancel();
    _dataSendTimer?.cancel();
    _internetCheckTimer?.cancel();
    super.dispose();
  }
}
