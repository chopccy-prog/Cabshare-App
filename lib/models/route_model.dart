// lib/models/route_model.dart
class RouteModel {
  final int id;
  final String name;
  final String fromCity;
  final String toCity;
  final double distanceKm;
  final int durationMinutes;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  RouteModel({
    required this.id,
    required this.name,
    required this.fromCity,
    required this.toCity,
    required this.distanceKm,
    required this.durationMinutes,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as int,
      name: json['name'] as String,
      fromCity: json['from_city'] as String,
      toCity: json['to_city'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'from_city': fromCity,
      'to_city': toCity,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'RouteModel(id: $id, name: $name, $fromCity → $toCity)';
  }
}
