import 'package:safe_driving_app/features/route/domain/entities/route.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_event_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';

abstract class RouteRepository {
  Future<Route> getLastActiveRoute();
  Future<Route> resumeRoute(int routeId);
  Future<void> saveRoutePosition(RoutePosition position);
  Future<List<RoutePosition>> getPendingPositions();

  Future<RouteEntity> createRoute(CreateRouteEntity route);
  Future<RouteEntity> getRoute(String routeId);
  Future<void> finishRoute(FinishRouteEntity route);
  Future<void> cancelRoute(CancelRouteEntity route);
  Future<void> sendSos(RouteEventEntity event);
  Future<void> sendRoutePositions(List<RoutePositionEntity> positions);
}
