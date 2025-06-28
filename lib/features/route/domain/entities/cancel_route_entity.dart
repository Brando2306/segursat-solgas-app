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

  CancelRouteEntity copyWith({
    dynamic routeId,
    dynamic cancelTimestamp,
    dynamic cancelLatitude,
    dynamic cancelLongitude,
    dynamic time,
  }) {
    return CancelRouteEntity(
      routeId: routeId ?? this.routeId,
      cancelTimestamp: cancelTimestamp ?? this.cancelTimestamp,
      cancelLatitude: cancelLatitude ?? this.cancelLatitude,
      cancelLongitude: cancelLongitude ?? this.cancelLongitude,
      time: time ?? this.time,
    );
  }
}
