// PROVIDER CORREGIDO - Solución para BuildContext inválido
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class SelectSourceProvider with ChangeNotifier {
  final MapController mapController = MapController();

  // Connectivity
  bool _hasInternet = false;
  bool _isCheckingConnectivity = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // BuildContext tracking - NUEVA SOLUCIÓN
  BuildContext? _currentContext;
  bool _isContextValid = false;

  // Existing properties...
  Position _position = Position(
    longitude: 0,
    latitude: 0,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );

  bool _blockIconMovePosition = false;
  bool _blockNextButton = false;
  bool _noSignalMode = false;
  bool _isLoading = false;
  String _gpsStatus = 'Buscando señal...';
  double _gpsAccuracy = 0.0;

  // Getters
  Position get position => _position;
  bool get blockIconMovePosition => _blockIconMovePosition;
  bool get blockNextButton => _blockNextButton;
  bool get noSignalMode => _noSignalMode;
  bool get isLoading => _isLoading;
  String get gpsStatus => _gpsStatus;
  double get gpsAccuracy => _gpsAccuracy;
  MapController get map => mapController;
  bool get hasInternet => _hasInternet;
  bool get isCheckingConnectivity => _isCheckingConnectivity;

  // MÉTODO PARA VALIDAR CONTEXT - SOLUCIÓN PRINCIPAL
  bool _isValidContext() {
    if (_currentContext == null || !_isContextValid) {
      return false;
    }
    if (_currentContext is StatefulElement) {
      return (_currentContext as StatefulElement).state.mounted;
    }
    return true;
  }

  // MÉTODO SEGURO PARA MOSTRAR DIÁLOGOS
  Future<T?> _safeShowDialog<T>({
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = false,
  }) async {
    if (!_isValidContext()) {
      log('Context no válido, no se puede mostrar diálogo');
      return null;
    }

    try {
      return await showDialog<T>(
        context: _currentContext!,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
    } catch (e) {
      log('Error mostrando diálogo: $e');
      return null;
    }
  }

  Future<void> initialize(BuildContext context) async {
    // GUARDAR REFERENCIA AL CONTEXT
    _currentContext = context;
    _blockNextButton = false;
    _isContextValid = true;

    // Verificar que el context sigue siendo válido antes de cada operación
    if (!_isValidContext()) return;

    // Primero verificar conectividad
    await _initializeConnectivity();

    // Verificar context otra vez después de operación asíncrona
    if (!_isValidContext()) return;

    // Luego continuar con GPS
    await _checkLocationPermission();
    if (_blockNextButton || !_isValidContext()) return;

    await _getLocationWithRetry();
  }

  Future<void> _initializeConnectivity() async {
    // Verificar conectividad inicial
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _hasInternet = result != ConnectivityResult.none;

    // Escuchar cambios de conectividad
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_hasInternet;
      _hasInternet = result != ConnectivityResult.none;

      if (wasOffline && _hasInternet) {
        // Reconectado - actualizar status
        _gpsStatus = 'Conexión restaurada';
        if (_isValidContext()) notifyListeners();
      } else if (!wasOffline && !_hasInternet) {
        // Desconectado
        _gpsStatus = 'Modo offline - Sin conexión a internet';
        if (_isValidContext()) notifyListeners();
      }
    });

    _isCheckingConnectivity = false;
    if (_isValidContext()) notifyListeners();
  }

  Future<void> _checkLocationPermission() async {
    if (!_isValidContext()) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showGpsDisabledDialog();
      return;
    }

    if (!_isValidContext()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (_isValidContext()) await _showPermissionDeniedDialog();
        return;
      }
    }

    if (!_isValidContext()) return;

    if (permission == LocationPermission.deniedForever) {
      await _showPermissionPermanentlyDeniedDialog();
      return;
    }
  }

  Future<void> _getLocationWithRetry({int retries = 3}) async {
    if (!_isValidContext()) return;

    _isLoading = true;
    _gpsStatus = _hasInternet
        ? 'Obteniendo ubicación...'
        : 'Obteniendo ubicación (sin internet)...';
    notifyListeners();

    try {
      for (int i = 0; i < retries; i++) {
        if (!_isValidContext()) return;

        try {
          await _attemptGetLocation(attempt: i + 1);
          return;
        } catch (e) {
          if (i == retries - 1) rethrow;
          await Future.delayed(Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (_isValidContext()) {
        _gpsStatus = 'Error: ${e.toString()}';
        await _handleLocationError(e);
      }
    } finally {
      _isLoading = false;
      if (_isValidContext()) notifyListeners();
    }
  }

  Future<void> _handleLocationError(dynamic error) async {
    if (!_isValidContext()) return;

    if (error is LocationServiceDisabledException) {
      await _showGpsDisabledDialog();
    } else if (error is TimeoutException) {
      await _showNoSignalDialog();
    } else {
      await _showGenericErrorDialog(error.toString());
    }
  }

  Future<void> _attemptGetLocation({int attempt = 1}) async {
    if (!_isValidContext()) return;

    final statusSuffix = _hasInternet ? '' : ' (offline)';
    _gpsStatus = 'Intento $attempt/3$statusSuffix...';
    notifyListeners();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy:
          _noSignalMode ? LocationAccuracy.low : LocationAccuracy.best,
      timeLimit: Duration(seconds: _noSignalMode ? 45 : 20),
    ).timeout(Duration(seconds: _noSignalMode ? 60 : 30));

    if (!_isValidContext()) return;

    _position = position;
    _gpsAccuracy = position.accuracy;
    _gpsStatus = _hasInternet
        ? 'Ubicación obtenida'
        : 'Ubicación obtenida (modo offline)';
    _handleSuccessfulLocation();
  }

  void _handleSuccessfulLocation() {
    if (!_isValidContext()) return;

    try {
      _position = position;

      writeStorage(
        'root.initialPosition',
        json.encode({
          'latitude': _position.latitude,
          'longitude': _position.longitude,
          'accuracy': _position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
          'hasInternet': _hasInternet,
        }),
      );
      log('Datos guardados: ${readStorage('root.initialPosition')}');

      mapController.move(LatLng(_position.latitude, _position.longitude), 18);

      _blockIconMovePosition = true;
      _blockNextButton = true; // Habilitar botón SOLO después de guardar
      _noSignalMode = false;

      notifyListeners();
    } catch (e) {
      log('Error al guardar posición: $e');
      _blockNextButton = false; // Mantener deshabilitado si hay error
      log('Error en select_source_provider.dart + $e');
      notifyListeners();
    }

    // Mostrar diálogo con coordenadas si no hay internet
    if (!_hasInternet && _isValidContext()) {
      _showOfflineLocationConfirmation();
    }
  }

  // DIÁLOGOS ACTUALIZADOS CON MÉTODO SEGURO
  Future<void> _showGpsDisabledDialog() async {
    final result = await _safeShowDialog<String>(
      builder: (context) => AlertDialog(
        title: const Text("GPS Desactivado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_off, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Por favor, activa el GPS para continuar. El GPS funciona sin internet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/menu'),
            child: const Text('Salir'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop('settings');
            },
            child: const Text('Activar GPS'),
          ),
        ],
      ),
    );

    if (result == 'settings') {
      await Geolocator.openLocationSettings();
      // Dar tiempo para que el usuario configure
      await Future.delayed(Duration(seconds: 2));
      // Reinicializar solo si el context sigue válido
      if (_isValidContext()) {
        await initialize(_currentContext!);
      }
    }
  }

  Future<void> _showNoSignalDialog() async {
    final result = await _safeShowDialog<bool>(
      builder: (context) => AlertDialog(
        title: const Text("Problema de Señal GPS"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off,
                size: 48, color: _hasInternet ? Colors.orange : Colors.red),
            const SizedBox(height: 16),
            Text(
              _hasInternet
                  ? 'No se pudo obtener señal GPS precisa.'
                  : 'Sin conexión a internet y señal GPS débil.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '• Sal al aire libre\n• Aléjate de edificios altos\n• Espera unos minutos',
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Deseas continuar con precisión reducida?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (result == true && _isValidContext()) {
      _noSignalMode = true;
      notifyListeners();
      await _getLocationWithRetry();
    } else if (_isValidContext()) {
      Navigator.of(_currentContext!).pushReplacementNamed('/menu');
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    final result = await _safeShowDialog<String>(
      builder: (context) => AlertDialog(
        title: const Text("Permiso Denegado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'La aplicación necesita permisos de ubicación para funcionar correctamente.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('exit'),
            child: const Text('Salir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('settings'),
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );

    if (result == 'settings') {
      await Geolocator.openAppSettings();
      await Future.delayed(Duration(seconds: 2));
      if (_isValidContext()) {
        await initialize(_currentContext!);
      }
    } else if (_isValidContext()) {
      Navigator.of(_currentContext!).pushReplacementNamed('/menu');
    }
  }

  Future<void> _showPermissionPermanentlyDeniedDialog() async {
    final result = await _safeShowDialog<String>(
      builder: (context) => AlertDialog(
        title: const Text("Permiso Bloqueado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_disabled, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Has bloqueado permanentemente los permisos de ubicación. Debes habilitarlos manualmente en la configuración de la aplicación.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('exit'),
            child: const Text('Salir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('settings'),
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );

    if (result == 'settings') {
      await _openLocationSettings(); // Usa la nueva función
      // Esperar un poco para que el usuario pueda cambiar la configuración
      await Future.delayed(Duration(seconds: 2));
      // Verificar si el contexto sigue válido antes de continuar
      if (_isValidContext()) {
        await initialize(_currentContext!);
      }
    } else if (_isValidContext()) {
      Navigator.of(_currentContext!).pushReplacementNamed('/menu');
    }
  }

  Future<void> openAppSettingsWithLocation() async {
    await openAppSettings(); // Abre la pantalla de permisos de la app
  }

  Future<void> _openLocationSettings() async {
    try {
      if (Platform.isAndroid) {
        // Intentar abrir configuración de ubicación directa en Android
        const intent = 'android.settings.LOCATION_SOURCE_SETTINGS';
        if (await canLaunch(intent)) {
          await launch(intent);
          return;
        }
      } else if (Platform.isIOS) {
        // Intentar abrir configuración de ubicación en iOS
        const url = 'App-Prefs:Privacy&path=LOCATION';
        if (await canLaunch(url)) {
          await launch(url);
          return;
        }

        // Alternativa para iOS
        const urlAlt = 'App-Prefs:Privacy';
        if (await canLaunch(urlAlt)) {
          await launch(urlAlt);
          return;
        }
      }

      // Fallback estándar
      // await Geolocator.openAppSettings();
      await openAppSettingsWithLocation();
    } catch (e) {
      print('Error abriendo configuración: $e');
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _showGenericErrorDialog(String error) async {
    final result = await _safeShowDialog<String>(
      builder: (context) => AlertDialog(
        title: const Text("Error de Ubicación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ocurrió un error inesperado: $error',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('exit'),
            child: const Text('Salir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('retry'),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );

    if (result == 'retry' && _isValidContext()) {
      await initialize(_currentContext!);
    } else if (_isValidContext()) {
      Navigator.of(_currentContext!).pushReplacementNamed('/menu');
    }
  }

  Future<void> _showOfflineLocationConfirmation() async {
    await _safeShowDialog(
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.offline_pin, color: Colors.green[700], size: 28),
            const SizedBox(width: 8),
            const Text("Ubicación GPS Obtenida"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Modo Offline Activo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Sin conexión a internet, pero GPS funcionando correctamente.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu ubicación actual es:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text('Latitud: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SelectableText(
                          _position.latitude.toStringAsFixed(6),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text('Longitud: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SelectableText(
                          _position.longitude.toStringAsFixed(6),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.account_circle_sharp,
                          size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      const Text('Precisión: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '±${_position.accuracy.toStringAsFixed(1)} metros',
                        style: TextStyle(
                          color: _position.accuracy < 10
                              ? Colors.green[700]
                              : _position.accuracy < 50
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Usaremos esta ubicación como punto de partida.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Reintentar para obtener mejor precisión
                    if (_isValidContext()) _getLocationWithRetry();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Mejorar precisión'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Continuar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void centerMapOnPosition() {
    if (_blockIconMovePosition && _isValidContext()) {
      mapController.move(LatLng(_position.latitude, _position.longitude), 18);
    }
  }

  // MÉTODO PARA INVALIDAR CONTEXT - LLAMAR DESDE EL WIDGET
  void invalidateContext() {
    _isContextValid = false;
    _currentContext = null;
  }

  void disposeResources() {
    invalidateContext();

    _connectivitySubscription?.cancel();
    // mapController.dispose();
  }
}
