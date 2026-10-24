class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed; // in m/s
  final double? altitude;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.altitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'altitude': altitude,
    };
  }

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
    );
  }
}
