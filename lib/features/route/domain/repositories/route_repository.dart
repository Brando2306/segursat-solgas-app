import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';

abstract class RouteRepository {
  Future<Route> getLastActiveRoute();
  Future<Route> resumeRoute(int routeId);
  Future<void> saveRoutePosition(RoutePosition position);
  Future<List<RoutePosition>> getPendingPositions();
  Future<void> finishRoute(int routeId);

  Future<int> createRoute(Map<String, dynamic> routeData);
  Future<void> saveRoutePositionsBatch(List<Map<String, dynamic>> positions);
  Future<void> cancelRoute(int routeId);
  Future<void> reportSos(int routeId);
}
