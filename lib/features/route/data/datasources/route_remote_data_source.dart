import 'dart:convert';

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

  @override
  Future<RouteEntity> createRoute(CreateRouteEntity route) async {
    final data = route.toJson();
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.CREATE_ROUTE}',
      data: data,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create route');
    }

    return RouteEntity.fromJson(response.data);
  }

  @override
  Future<RouteEntity> getRoute(int routeId) async {
    final response = await _dio.get(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.GET_ROUTE.replaceAll('<int:id>', '$routeId')}',
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get route');
    }

    return RouteEntity.fromJson(response.data);
  }

  @override
  Future<void> finishRoute(FinishRouteEntity route) async {
    final data = route.toJson();
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.FINISH_ROUTE}',
      data: data,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to finish route');
    }
  }

  @override
  Future<void> cancelRoute(CancelRouteEntity route) async {
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.CANCEL_ROUTE}',
      data: route.toJson(),
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel route');
    }
  }

  @override
  Future<void> sendSos(EmergencyEventEntity event) async {
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.INSERT_ROUTE_SOS}',
      data: [event.toJson()],
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send SOS');
    }
  }

  @override
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions) async {
    final data = positions.map((p) => p.toJson()).toList();
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.INSERT_ROUTE_POSITIONS_BATCH}',
      data: data,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send route positions');
    }

    // Siempre status 200, pero revisar campo errors
    final responseData = response.data;
    if (responseData is Map && responseData.containsKey('errors')) {
      final errors = responseData['errors'];
      if (errors is List && errors.isNotEmpty) {
        throw Exception('Failed to send route positions: $errors');
      }
    }
  }

  @override
  Future<String> getEmergencyPhoneNumber() async {
    final response = await _client.get(
      Uri.http(ENDPOINTS.HOST, ENDPOINTS.EMERGENCY_PHONE),
      headers: {
        "Content-Type": "application/json",
        "Authorization": ENDPOINTS.auth()
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get emergency number');
    }

    final data = json.decode(response.body);
    return data['emergency_phone'] as String;
  }

  @override
  Future<void> sendIncident(IncidentRouteEntity incident) async {
    final response = await _client.post(
      Uri.http(ENDPOINTS.HOST, ENDPOINTS.CREATE_ROUTE_INCIDENTS),
      body: json.encode([incident.toJson()]),
      headers: {
        "Content-Type": "application/json",
        "Authorization": ENDPOINTS.auth()
      },
    );

    final jsonResponse = json.decode(response.body);
    if (jsonResponse is Map && jsonResponse.containsKey('errors')) {
      throw Exception(handleApiError(jsonResponse));
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to send incident');
    }
  }

  @override
  Future<void> sendRouteStop(StopRouteEntity stop) async {
    final response = await _client.post(
      Uri.http(ENDPOINTS.HOST, ENDPOINTS.CREATE_ROUTE_STOPS),
      body: json.encode([stop.toJson()]),
      headers: {
        "Content-Type": "application/json",
        "Authorization": ENDPOINTS.auth()
      },
    );

    final jsonResponse = json.decode(response.body);
    if (jsonResponse is Map && jsonResponse.containsKey('errors')) {
      throw Exception(handleApiError(jsonResponse));
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to send route stop');
    }
  }
}
