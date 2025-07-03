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
