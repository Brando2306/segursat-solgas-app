import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'package:safe_driving_app/class/index.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/root/index.dart';
import 'package:safe_driving_app/utils/storage.dart';

class SelectDestinationProvider with ChangeNotifier {
  // Solo el MapController permanece aquí porque es parte de la lógica del mapa
  final MapController mapController = MapController();

  // Estado de la aplicación
  Position _position = Position(
    longitude: -77.06337978247707,
    latitude: -12.047933614518184,
    timestamp: null,
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
  bool _changeInputs = true;
  List<DirectionDto> _directionsList = [];
  List<String> _results = [SELECTDESTINATION.TEXT_TOP_LIST];
  Timer? _searchTimer;
  String _searchText = '';
  String? _selectedResult;
  String? _latitudeText;
  String? _longitudeText;
  bool _hasInternetConnection = true;

  // Getters
  Position get position => _position;
  bool get blockIconMovePosition => _blockIconMovePosition;
  bool get blockNextButton => _blockNextButton;
  bool get changeInputs => _changeInputs;
  List<DirectionDto> get directionsList => _directionsList;
  List<String> get results => _results;
  String get searchText => _searchText;
  String? get selectedResult => _selectedResult;
  String? get latitudeText => _latitudeText;
  String? get longitudeText => _longitudeText;
  bool get hasInternetConnection => _hasInternetConnection;

  SelectDestinationProvider() {
    _checkInternetConnection();
    // Escuchar cambios en la conexión
    Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _hasInternetConnection = result != ConnectivityResult.none;
    // Si no hay internet, forzar el modo manual
    if (!_hasInternetConnection) {
      _changeInputs = false;
    }
    notifyListeners();
  }

  // Setters con notificación de cambios
  set position(Position value) {
    _position = value;
    notifyListeners();
  }

  set blockIconMovePosition(bool value) {
    _blockIconMovePosition = value;
    notifyListeners();
  }

  set blockNextButton(bool value) {
    _blockNextButton = value;
    notifyListeners();
  }

  set latitudeText(String? value) {
    _latitudeText = value;
    notifyListeners();
  }

  set longitudeText(String? value) {
    _longitudeText = value;
    notifyListeners();
  }

  // Métodos de lógica de negocio
  void handleMapTap(_, LatLng tappedPoint) {
    position = Position(
      longitude: tappedPoint.longitude,
      latitude: tappedPoint.latitude,
      timestamp: null,
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    blockNextButton = true;
    blockIconMovePosition = true;
  }

  void centerMapPosition() {
    if (blockIconMovePosition) {
      mapController.move(LatLng(_position.latitude, _position.longitude), 18);
    }
  }

  void toggleInputMode() {
    _changeInputs = !_changeInputs;
    notifyListeners();
  }

  void clearManualInput() {
    _latitudeText = null;
    _longitudeText = null;
    notifyListeners();
  }

  Future<void> searchManualCoordinates(BuildContext context) async {
    if (_latitudeText == null || _longitudeText == null) return;

    EasyLoading.show(status: 'Buscando coordenadas...');
    try {
      position = Position(
        longitude: double.parse(_longitudeText!.trim()),
        latitude: double.parse(_latitudeText!.trim()),
        timestamp: null,
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      mapController.move(LatLng(_position.latitude, _position.longitude), 18);
      blockIconMovePosition = true;
      blockNextButton = true;

      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      print('search coordinate Text: $e');
      notificationError(
          context, 'Coordenadas incorrectas. Ejemplo: -12.1234, -77.1234');
    }
    EasyLoading.dismiss();
  }

  void handleTextChanged(String text) {
    _searchText = text;
    _selectedResult = null;
    notifyListeners();
    _startSearchTimer();
  }

  void _startSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = Timer(Duration(seconds: 2), () {
      _searchDirection(_searchText);
    });
  }

  Future<void> _searchDirection(String value) async {
    if (!_hasInternetConnection) return;

    try {
      if (value.isEmpty || value.length <= 3) return;

      FocusManager.instance.primaryFocus?.unfocus();
      EasyLoading.show(status: 'Buscando destino...');

      _directionsList = await _fetchDirections(value);

      if (_directionsList.isNotEmpty) {
        _results = [SELECTDESTINATION.TEXT_TOP_LIST];
        _results.addAll(removeDuplicatesDirectionDto(_directionsList)
            .map((e) => e.direction)
            .toList());
        notifyListeners();
      }

      EasyLoading.dismiss();
    } catch (e) {
      print('_searchDirection error: $e');
      EasyLoading.dismiss();
    }
  }

  Future<List<DirectionDto>> _fetchDirections(String direction) async {
    final url = Uri.http(ENDPOINTS.HOST, ENDPOINTS.GET_LOCATION);
    final response = await http.post(
      url,
      body: json.encode({'address': direction}),
      headers: {
        "Content-Type": "application/json",
        "Authorization": ENDPOINTS.auth()
      },
    );

    if (response.statusCode != STATUSCODE.OK) {
      throw Exception('No se encontró la ubicación');
    }

    final data = json.decode(response.body);
    final directionsObjsJson = data['results'][0];

    return [directionsObjsJson]
        .map((tagJson) => DirectionDto.fromJson(tagJson))
        .toList();
  }

  Future<void> selectResult(String? value, BuildContext context) async {
    if (value == null ||
        value.isEmpty ||
        value == SELECTDESTINATION.TEXT_TOP_LIST) return;

    _selectedResult = value;
    notifyListeners();

    final direction = _directionsList.firstWhere((e) => e.direction == value);

    await writeStorage('root.address', value);

    position = Position(
      longitude: double.parse(direction.longitude),
      latitude: double.parse(direction.latitude),
      timestamp: null,
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    mapController.move(LatLng(_position.latitude, _position.longitude), 18);
    blockIconMovePosition = true;
    blockNextButton = true;
  }

  Future<void> confirmDestination(BuildContext context) async {
    if (!_blockNextButton) return;

    await writeStorage(
      'root.finalPosition',
      json.encode(
          {'latitude': _position.latitude, 'longitude': _position.longitude}),
    );

    Navigator.pushNamed(context, '/root/speedometer');
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
