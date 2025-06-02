import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:sqflite/sqflite.dart';

class RouteLocalDataSource {
  final Database database;

  RouteLocalDataSource({required this.database});

  Future<void> init() async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS routes (
        id INTEGER PRIMARY KEY,
        unitName TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        sourceLat REAL NOT NULL,
        sourceLng REAL NOT NULL,
        destLat REAL NOT NULL,
        destLng REAL NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS route_positions (
        id TEXT PRIMARY KEY,
        routeId INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL NOT NULL,
        speed REAL NOT NULL,
        angle INTEGER NOT NULL,
        FOREIGN KEY (routeId) REFERENCES routes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> cacheRoute(Route route) async {
    await database.insert(
      'routes',
      {
        'id': route.id,
        'unitName': route.unitName,
        'status': route.status.toString().split('.').last,
        'timestamp': route.timestamp.toIso8601String(),
        'sourceLat': route.source.latitude,
        'sourceLng': route.source.longitude,
        'destLat': route.destination.latitude,
        'destLng': route.destination.longitude,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (route.positions != null) {
      await _cachePositions(route.id, route.positions!);
    }
  }

  Future<void> _cachePositions(
      int routeId, List<RoutePosition> positions) async {
    final batch = database.batch();

    for (final position in positions) {
      batch.insert(
        'route_positions',
        {
          'id': position.id,
          'routeId': routeId,
          'timestamp': position.timestamp.toIso8601String(),
          'latitude': position.latitude,
          'longitude': position.longitude,
          'altitude': position.altitude,
          'speed': position.speed,
          'angle': position.angle,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<Route?> getLastCachedRoute() async {
    final routeMap = await database.query(
      'routes',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (routeMap.isEmpty) return null;

    final routeId = routeMap.first['id'] as int;
    final positions = await _getCachedPositions(routeId);

    return Route(
      id: routeId,
      unitName: routeMap.first['unitName'] as String,
      status: RouteStatus.values.firstWhere(
        (e) => e.toString().split('.').last == routeMap.first['status'],
        orElse: () => RouteStatus.pending,
      ),
      timestamp: DateTime.parse(routeMap.first['timestamp'] as String),
      source: Position(
        latitude: routeMap.first['sourceLat'] as double,
        longitude: routeMap.first['sourceLng'] as double,
      ),
      destination: Position(
        latitude: routeMap.first['destLat'] as double,
        longitude: routeMap.first['destLng'] as double,
      ),
      positions: positions,
    );
  }

  Future<List<RoutePosition>> _getCachedPositions(int routeId) async {
    final positions = await database.query(
      'route_positions',
      where: 'routeId = ?',
      whereArgs: [routeId],
    );

    return positions
        .map((map) => RoutePosition(
              id: map['id'] as String,
              routeId: map['routeId'] as int,
              timestamp: DateTime.parse(map['timestamp'] as String),
              latitude: map['latitude'] as double,
              longitude: map['longitude'] as double,
              altitude: map['altitude'] as double,
              speed: map['speed'] as double,
              angle: map['angle'] as int,
            ))
        .toList();
  }

  Future<void> savePendingPosition(RoutePosition position) async {
    await database.insert(
      'route_positions',
      {
        'id': position.id,
        'routeId': position.routeId,
        'timestamp': position.timestamp.toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'speed': position.speed,
        'angle': position.angle,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RoutePosition>> getPendingPositions() async {
    final positions = await database.query('route_positions');
    return positions.map((map) => RoutePosition.fromJson(map)).toList();
  }

  Future<void> removePendingPosition(String positionId) async {
    await database.delete(
      'route_positions',
      where: 'id = ?',
      whereArgs: [positionId],
    );
  }

  Future<void> cleanRouteData(int routeId) async {
    await database.delete(
      'routes',
      where: 'id = ?',
      whereArgs: [routeId],
    );
    await database.delete(
      'route_positions',
      where: 'routeId = ?',
      whereArgs: [routeId],
    );
  }
}
