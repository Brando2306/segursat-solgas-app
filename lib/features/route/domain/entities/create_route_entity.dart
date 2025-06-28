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
