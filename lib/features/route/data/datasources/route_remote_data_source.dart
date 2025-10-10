import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:safe_driving_app/features/route/domain/entities/cancel_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/create_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/finish_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/incident_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/stop_route_entity.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_response_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/emergency_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';

abstract class RouteRemoteDataSource {
  Future<RouteEntity> createRoute(CreateRouteEntity route);
  Future<RouteEntity> getRoute(int routeId);
  Future<void> finishRoute(FinishRouteEntity route);
  Future<void> cancelRoute(CancelRouteEntity route);
  Future<void> sendSos(EmergencyEventEntity event);
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions);
  Future<String> getEmergencyPhoneNumber();
  Future<void> sendIncident(IncidentRouteEntity incident);
  Future<void> sendRouteStop(StopRouteEntity stop);
}

class RouteRemoteDataSourceImpl implements RouteRemoteDataSource {
  final http.Client _client;
  final Dio _dio;

  RouteRemoteDataSourceImpl({required http.Client client, required Dio dio})
      : _client = client,
        _dio = dio;

  void _log(String message, [dynamic data]) {
    log('[ROUTE_DS] $message${data != null ? ': ${jsonEncode(data)}' : ''}');
  }

  @override
  Future<RouteEntity> createRoute(CreateRouteEntity route) async {
    final data = route.toJson();
    _log('📤 Enviando createRoute', data);

    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.CREATE_ROUTE}',
      data: data,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    _log('📥 Respuesta createRoute', response.data);

    if (response.statusCode != 200) {
      _log('❌ Error al crear ruta: ${response.statusCode}');
      throw Exception('Failed to create route');
    }

    _log('✅ Ruta creada exitosamente');
    return RouteEntity.fromJson(response.data);
  }

  @override
  Future<RouteEntity> getRoute(int routeId) async {
    _log('📤 Solicitando getRoute', {'routeId': routeId});

    final response = await _dio.get(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.GET_ROUTE.replaceAll('<int:id>', '$routeId')}',
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    _log('📥 Respuesta getRoute', response.data);

    if (response.statusCode != 200) {
      _log('❌ Error al obtener ruta: ${response.statusCode}');
      throw Exception('Failed to get route');
    }

    _log('✅ Ruta obtenida correctamente');
    return RouteEntity.fromJson(response.data);
  }

  @override
  Future<void> finishRoute(FinishRouteEntity route) async {
    final data = route.toJson();
    _log('📤 Enviando finishRoute', data);

    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.FINISH_ROUTE}',
      data: data,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    _log('📥 Respuesta finishRoute', response.data);

    if (response.statusCode != 200) {
      _log('❌ Error al finalizar ruta: ${response.statusCode}');
      throw Exception('Failed to finish route');
    }

    _log('✅ Ruta finalizada correctamente');
  }

  @override
  Future<void> cancelRoute(CancelRouteEntity route) async {
    _log('📤 Enviando cancelRoute', route.toJson());

    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.CANCEL_ROUTE}',
      data: route.toJson(),
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    _log('📥 Respuesta cancelRoute', response.data);

    if (response.statusCode != 200) {
      _log('❌ Error al cancelar ruta: ${response.statusCode}');
      throw Exception('Failed to cancel route');
    }

    _log('✅ Ruta cancelada correctamente');
  }

  @override
  Future<void> sendSos(EmergencyEventEntity event) async {
    _log('📤 Enviando SOS', event.toJson());

    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.INSERT_ROUTE_SOS}',
      data: [event.toJson()],
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    _log('📥 Respuesta sendSos', response.data);

    if (response.statusCode != 200) {
      _log('❌ Error al enviar SOS: ${response.statusCode}');
      throw Exception('Failed to send SOS');
    }

    _log('✅ SOS enviado correctamente');
  }

  @override
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions) async {
    final data = positions.map((p) => p.toJson()).toList();
    _log('📤 Enviando posiciones de ruta (batch)', data);

    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.INSERT_ROUTE_POSITIONS_BATCH}',
      data: data,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    _log('📥 Respuesta sendRoutePositions', response.data);

    if (response.statusCode != 200) {
      _log('❌ Error al enviar posiciones: ${response.statusCode}');
      throw Exception('Failed to send route positions');
    }

    final responseData = response.data;
    if (responseData is Map && responseData.containsKey('errors')) {
      final errors = responseData['errors'];
      if (errors is List && errors.isNotEmpty) {
        _log('⚠️ Errores en envío de posiciones', errors);
        throw Exception('Failed to send route positions: $errors');
      }
    }

    _log('✅ Posiciones enviadas correctamente');
  }

  @override
  Future<String> getEmergencyPhoneNumber() async {
    _log('📤 Solicitando número de emergencia');

    final response = await _client.get(
      Uri.http(ENDPOINTS.HOST, ENDPOINTS.EMERGENCY_PHONE),
      headers: {
        "Content-Type": "application/json",
        "Authorization": ENDPOINTS.auth()
      },
    );

    _log('📥 Respuesta getEmergencyPhoneNumber', response.body);

    if (response.statusCode != 200) {
      _log('❌ Error al obtener número de emergencia: ${response.statusCode}');
      throw Exception('Failed to get emergency number');
    }

    final data = json.decode(response.body);
    final number = data['emergency_phone'] as String;
    _log('✅ Número de emergencia obtenido', {'phone': number});
    return number;
  }

  @override
  Future<void> sendIncident(IncidentRouteEntity incident) async {
    _log('📤 Enviando incidente', incident.toJson());

    final response = await _client.post(
      Uri.http(ENDPOINTS.HOST, ENDPOINTS.CREATE_ROUTE_INCIDENTS),
      body: json.encode([incident.toJson()]),
      headers: {
        "Content-Type": "application/json",
        "Authorization": ENDPOINTS.auth()
      },
    );

    final jsonResponse = json.decode(response.body);
    _log('📥 Respuesta sendIncident', jsonResponse);

    if (jsonResponse is Map && jsonResponse.containsKey('errors')) {
      _log('⚠️ Errores en envío de incidente', jsonResponse['errors']);
      throw Exception(handleApiError(jsonResponse));
    }

    if (response.statusCode != 200) {
      _log('❌ Error HTTP al enviar incidente: ${response.statusCode}');
      throw Exception('Failed to send incident');
    }

    _log('✅ Incidente enviado correctamente');
  }

  @override
  Future<void> sendRouteStop(StopRouteEntity stop) async {
    _log('📤 Enviando parada de ruta', stop.toJson());

    final response = await _client.post(
      Uri.http(ENDPOINTS.HOST, ENDPOINTS.CREATE_ROUTE_STOPS),
      body: json.encode([stop.toJson()]),
      headers: {
        "Content-Type": "application/json",
        "Authorization": ENDPOINTS.auth()
      },
    );

    final jsonResponse = json.decode(response.body);
    _log('📥 Respuesta sendRouteStop', jsonResponse);

    if (jsonResponse is Map && jsonResponse.containsKey('errors')) {
      _log('⚠️ Errores en envío de parada', jsonResponse['errors']);
      throw Exception(handleApiError(jsonResponse));
    }

    if (response.statusCode != 200) {
      _log('❌ Error HTTP al enviar parada: ${response.statusCode}');
      throw Exception('Failed to send route stop');
    }

    _log('✅ Parada de ruta enviada correctamente');
  }
}
