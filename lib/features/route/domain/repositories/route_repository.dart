import 'package:safe_driving_app/features/route/domain/entities/route.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';

abstract class RouteRepository {
  Future<Route> getLastActiveRoute();
  
  Future<RouteEntity> createRoute(CreateRouteEntity route);
  Future<RouteEntity> getRoute(String routeId);
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
