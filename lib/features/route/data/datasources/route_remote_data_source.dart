import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:safe_driving_app/features/route/domain/entities/route.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/storage.dart';

abstract class RouteRemoteDataSource {
  // Future<Route> getRoute(int id);
  Future<List<Route>> getActiveRoutes();
  // Future<int> createRoute(Map<String, dynamic> routeData);
  Future<void> saveRoutePosition(RoutePosition position);
  Future<void> saveRoutePositionsBatch(List<Map<String, dynamic>> positions);
  // Future<void> cancelRoute(int routeId);
  // Future<void> finishRoute(int routeId);
  // Future<void> reportSos(int routeId);

  Future<RouteEntity> createRoute(CreateRouteEntity route);
  Future<RouteEntity> getRoute(String routeId);
  Future<void> finishRoute(FinishRouteEntity route);
  Future<void> cancelRoute(CancelRouteEntity route);
  Future<void> sendSos(RouteEventEntity event);
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions);
}

class RouteRemoteDataSourceImpl implements RouteRemoteDataSource {
  final http.Client _client;
  final Dio _dio;

  RouteRemoteDataSourceImpl({required http.Client client, required Dio dio})
      : _client = client,
        _dio = dio;

  // @override
  // Future<Route> getRoute(int id) async {
  //   final response = await _makeRequest(
  //     ENDPOINTS.GET_ROUTE.replaceAll('<int:id>', '$id'),
  //   );
  //   return mapResponseToRoute(response);
  // }

  @override
  Future<List<Route>> getActiveRoutes() async {
    try {
      final currentRouteId = readStorage('personal.lastRoute');
      if (currentRouteId != null) {
        final route = await getRoute(currentRouteId);
        return [route.toRoute()];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // @override
  // Future<int> createRoute(Map<String, dynamic> route) async {
  //   final response = await _makeRequest(
  //     ENDPOINTS.CREATE_ROUTE,
  //     method: 'POST',
  //     body: {
  //       'unit_name': readStorage('personal.licensePlate'),
  //       'timestamp': getDate(),
  //       'source_latitude':
  //           json.decode(readStorage('root.initialPosition'))['latitude'],
  //       'source_longitude':
  //           json.decode(readStorage('root.initialPosition'))['longitude'],
  //       'destination_latitude':
  //           json.decode(readStorage('root.finalPosition'))['latitude'],
  //       'destination_longitude':
  //           json.decode(readStorage('root.finalPosition'))['longitude'],
  //     },
  //   );
  //   return response['id'];
  // }

  @override
  Future<void> saveRoutePosition(RoutePosition position) async {
    await _makeRequest(
      ENDPOINTS.SAVE_POSITION,
      method: 'POST',
      body: position.toJson(),
    );
  }

  // @override
  // Future<void> finishRoute(int routeId) async {
  //   await _makeRequest(
  //     ENDPOINTS.FINISH_ROUTE.replaceAll('<int:id>', '$routeId'),
  //     method: 'POST',
  //   );
  // }

  @override
  Future<void> saveRoutePositionsBatch(
      List<Map<String, dynamic>> positions) async {
    await _makeRequest(
      ENDPOINTS.SAVE_POSITIONS_BATCH,
      method: 'POST',
      body: {'positions': positions},
    );
  }

  // @override
  // Future<void> cancelRoute(int routeId) async {
  //   await _makeRequest(
  //     ENDPOINTS.CANCEL_ROUTE.replaceAll('<int:id>', '$routeId'),
  //     method: 'POST',
  //   );
  // }

  // @override
  // Future<void> reportSos(int routeId) async {
  //   await _makeRequest(
  //     ENDPOINTS.INSERT_ROUTE_SOS.replaceAll('<int:id>', '$routeId'),
  //     method: 'POST',
  //   );
  // }

  Future<Map<String, dynamic>> _makeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.http(ENDPOINTS.HOST, endpoint);
    final headers = {
      'Authorization': ENDPOINTS.auth().toString(),
      'Content-Type': 'application/json',
    };

    final response = method == 'POST'
        ? await _client.post(uri, headers: headers, body: json.encode(body))
        : await _client.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load data: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  Route mapResponseToRoute(Map<String, dynamic> response) {
    // Se obtiene el timestamp ya sea de "timestamp" (si es String) o "source_timestamp" (si es entero)
    final dynamic ts = response['timestamp'] ?? response['source_timestamp'];
    final DateTime parsedTimestamp = ts is String
        ? DateTime.parse(ts)
        : ts is int
            ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
            : DateTime.fromMillisecondsSinceEpoch(getDate());

    // Se detecta el estado usando "route_status" o "status"
    final dynamic rawStatus = response['route_status'] ?? response['status'];
    RouteStatus parsedStatus;
    if (rawStatus == 'running' || rawStatus == 'R') {
      parsedStatus = RouteStatus.running;
    } else if (rawStatus == 'completed' || rawStatus == 'C') {
      parsedStatus = RouteStatus.completed;
    } else if (rawStatus == 'cancelled' || rawStatus == 'X') {
      parsedStatus = RouteStatus.cancelled;
    } else {
      parsedStatus = RouteStatus.pending;
    }

    return Route(
      id: response['id'],
      unitName: response['unit_name'] ?? readStorage('personal.licensePlate'),
      status: parsedStatus,
      timestamp: parsedTimestamp,
      source: Position(
        latitude: response['source_latitude']?.toDouble() ??
            json.decode(readStorage('root.initialPosition'))['latitude'],
        longitude: response['source_longitude']?.toDouble() ??
            json.decode(readStorage('root.initialPosition'))['longitude'],
      ),
      destination: Position(
        latitude: response['destination_latitude']?.toDouble() ??
            json.decode(readStorage('root.finalPosition'))['latitude'],
        longitude: response['destination_longitude']?.toDouble() ??
            json.decode(readStorage('root.finalPosition'))['longitude'],
      ),
      positions: (response['positions'] as List?)
          ?.map((p) => RoutePosition(
                routeId: response['id'],
                timestamp: DateTime.parse(p['timestamp']),
                latitude: p['latitude']?.toDouble() ?? 0.0,
                longitude: p['longitude']?.toDouble() ?? 0.0,
                altitude: p['altitude']?.toDouble() ?? 0.0,
                speed: p['speed']?.toDouble() ?? 0.0,
                angle: p['angle'] ?? 0,
              ))
          .toList(),
    );
  }

  @override
  Future<RouteEntity> createRoute(CreateRouteEntity route) async {
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.CREATE_ROUTE}',
      data: route.toJson(),
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
  Future<RouteEntity> getRoute(String routeId) async {
    final response = await _dio.get(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.GET_ROUTE.replaceAll('<int:id>', routeId)}',
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
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.FINISH_ROUTE}',
      data: route.toJson(),
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
  Future<void> sendSos(RouteEventEntity event) async {
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
    final response = await _dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.INSERT_ROUTE_POSITIONS_BATCH}',
      data: positions.map((p) => p.toJson()).toList(),
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send route positions');
    }
  }
}
