// lib/models/stop_model.dart
class StopModel {
  final int id;
  final int routeId;
  final String name;
  final String landmark;
  final String cityName;
  final double latitude;
  final double longitude;
  final int sequenceOrder;
  final bool isActive;

  StopModel({
    required this.id,
    required this.routeId,
    required this.name,
    required this.landmark,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    required this.sequenceOrder,
    required this.isActive,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] as int,
      routeId: json['route_id'] as int,
      name: json['name'] as String,
      landmark: json['landmark'] as String? ?? '',
      cityName: json['city_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sequenceOrder: json['sequence_order'] as int,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'name': name,
      'landmark': landmark,
      'city_name': cityName,
      'latitude': latitude,
      'longitude': longitude,
      'sequence_order': sequenceOrder,
      'is_active': isActive,
    };
  }

  String get displayName {
    return landmark.isNotEmpty ? '$name ($landmark)' : name;
  }

  @override
  String toString() {
    return 'StopModel(id: $id, name: $name, city: $cityName)';
  }
}
