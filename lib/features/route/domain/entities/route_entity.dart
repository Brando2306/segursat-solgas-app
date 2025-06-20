import 'package:safe_driving_app/features/route/domain/entities/route.dart';

class RouteEntity {
  final int id;
  final dynamic unitName;
  final dynamic timestamp;
  final dynamic sourceLatitude;
  final dynamic sourceLongitude;
  final dynamic destinationLatitude;
  final dynamic destinationLongitude;
  final dynamic isFinished;
  final dynamic isCancelled;
  final dynamic duration;

  RouteEntity({
    required this.id,
    required this.unitName,
    required this.timestamp,
    required this.sourceLatitude,
    required this.sourceLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.isFinished = false,
    this.isCancelled = false,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_name': unitName,
      'timestamp': timestamp,
      'source_latitude': sourceLatitude,
      'source_longitude': sourceLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'is_finished': isFinished,
      'is_cancelled': isCancelled,
      'duration': duration,
    };
  }

  factory RouteEntity.fromJson(Map<String, dynamic> json) {
    return RouteEntity(
      id: json['id'],
      unitName: json['unit_name'],
      timestamp: json['timestamp'],
      sourceLatitude: json['source_latitude'],
      sourceLongitude: json['source_longitude'],
      destinationLatitude: json['destination_latitude'],
      destinationLongitude: json['destination_longitude'],
      isFinished: json['is_finished'] ?? false,
      isCancelled: json['is_cancelled'] ?? false,
      duration: json['duration'],
    );
  }

  Route toRoute() {
    return Route(
      id: this.id,
      unitName: this.unitName,
      status: RouteStatus.running, // You'll need to handle status properly
      timestamp: this.timestamp,
      source: Position(latitude: sourceLatitude, longitude: sourceLongitude),
      destination: Position(
          latitude: destinationLatitude, longitude: destinationLongitude),
      positions: null, // You'll need to handle positions if needed
    );
  }
}

class CancelRouteEntity {
  final dynamic routeId;
  final dynamic cancelTimestamp;
  final dynamic cancelLatitude;
  final dynamic cancelLongitude;
  final dynamic time;

  CancelRouteEntity({
    required this.routeId,
    required this.cancelTimestamp,
    required this.cancelLatitude,
    required this.cancelLongitude,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeid': routeId,
      'cancel_timestamp': cancelTimestamp,
      'cancel_latitude': cancelLatitude,
      'cancel_longitude': cancelLongitude,
      'time': time,
    };
  }

  factory CancelRouteEntity.fromJson(Map<String, dynamic> json) {
    return CancelRouteEntity(
      routeId: json['routeid'],
      cancelTimestamp: json['cancel_timestamp'],
      cancelLatitude: json['cancel_latitude'],
      cancelLongitude: json['cancel_longitude'],
      time: json['time'],
    );
  }
}

class FinishRouteEntity {
  final dynamic routeId;
  final dynamic finishTimestamp;
  final dynamic finishLatitude;
  final dynamic finishLongitude;
  final dynamic time;

  FinishRouteEntity({
    required this.routeId,
    required this.finishTimestamp,
    required this.finishLatitude,
    required this.finishLongitude,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeid': routeId,
      'finish_timestamp': finishTimestamp,
      'finish_latitude': finishLatitude,
      'finish_longitude': finishLongitude,
      'time': time,
    };
  }

  factory FinishRouteEntity.fromJson(Map<String, dynamic> json) {
    return FinishRouteEntity(
      routeId: json['routeid'],
      finishTimestamp: json['finish_timestamp'],
      finishLatitude: json['finish_latitude'],
      finishLongitude: json['finish_longitude'],
      time: json['time'],
    );
  }

  FinishRouteEntity copyWith({
    dynamic routeId,
    dynamic finishTimestamp,
    dynamic finishLatitude,
    dynamic finishLongitude,
    dynamic time,
  }) {
    return FinishRouteEntity(
      routeId: routeId ?? this.routeId,
      finishTimestamp: finishTimestamp ?? this.finishTimestamp,
      finishLatitude: finishLatitude ?? this.finishLatitude,
      finishLongitude: finishLongitude ?? this.finishLongitude,
      time: time ?? this.time,
    );
  }
}

class CreateRouteEntity {
  final dynamic unitName;
  final dynamic timestamp;
  final dynamic sourceLatitude;
  final dynamic sourceLongitude;
  final dynamic destinationLatitude;
  final dynamic destinationLongitude;

  CreateRouteEntity({
    required this.unitName,
    required this.timestamp,
    required this.sourceLatitude,
    required this.sourceLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'unit_name': unitName,
      'timestamp': timestamp,
      'source_latitude': sourceLatitude,
      'source_longitude': sourceLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
    };
  }

  factory CreateRouteEntity.fromJson(Map<String, dynamic> json) {
    return CreateRouteEntity(
      unitName: json['unit_name'],
      timestamp: json['timestamp'],
      sourceLatitude: json['source_latitude'],
      sourceLongitude: json['source_longitude'],
      destinationLatitude: json['destination_latitude'],
      destinationLongitude: json['destination_longitude'],
    );
  }
}
