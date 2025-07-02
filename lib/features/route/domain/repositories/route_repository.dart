import 'package:safe_driving_app/features/route/domain/entities/cancel_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/create_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/finish_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/incident_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_response_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/emergency_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/stop_route_entity.dart';

abstract class RouteRepository {
  Future<RouteEntity> createRoute(CreateRouteEntity route);
  Future<RouteEntity> getRoute(int routeId);
  Future<void> finishRoute(FinishRouteEntity route);
  Future<void> cancelRoute(CancelRouteEntity route);
  Future<void> sendSos(EmergencyEventEntity event);
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions);
  Future<String> getEmergencyPhoneNumber();

  Future<RouteEntity> retryRouteCreation(CreateRouteEntity route);
  Future<void> retryRoutePositions(List<RoutePositionEntity> positions);
  Future<void> retrySendSos(EmergencyEventEntity event);
  Future<String> retryEmergencyPhoneNumber();
  Future<void> retryCancelRoute(CancelRouteEntity event);
  Future<void> retryRouteFinish(FinishRouteEntity route);

  Future<void> sendIncident(IncidentRouteEntity incident);
  Future<void> retrySendIncident(IncidentRouteEntity incident);

  Future<void> sendRouteStop(StopRouteEntity stop);
  Future<void> retrySendRouteStop(StopRouteEntity stop);
}
