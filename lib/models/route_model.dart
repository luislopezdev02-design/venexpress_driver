class AllyStop {
  final int id;
  final String? name;
  final String? address;
  final String? phone;
  final String? city;
  final double? latitude;
  final double? longitude;

  AllyStop({
    required this.id,
    this.name,
    this.address,
    this.phone,
    this.city,
    this.latitude,
    this.longitude,
  });

  factory AllyStop.fromJson(Map<String, dynamic> json) {
    return AllyStop(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      city: json['city'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class RouteStopModel {
  final int id;
  final int sequence;
  final String status;
  final String mapColor;
  final int packagesCollectedCount;
  final AllyStop? ally;

  RouteStopModel({
    required this.id,
    required this.sequence,
    required this.status,
    required this.mapColor,
    required this.packagesCollectedCount,
    this.ally,
  });

  bool get isVisited => status == 'visited';

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      id: json['id'],
      sequence: json['sequence'] ?? 0,
      status: json['status'] ?? 'pending',
      mapColor: json['map_color'] ?? 'blue',
      packagesCollectedCount: json['packages_collected_count'] ?? 0,
      ally: json['ally'] != null ? AllyStop.fromJson(json['ally']) : null,
    );
  }
}

class RouteModel {
  final int id;
  final String? name;
  final String? city;
  final String status;
  final String? startedAt;
  final int totalStops;
  final int visitedStops;
  final int pendingStops;
  final int progressPercentage;
  final List<RouteStopModel> stops;

  RouteModel({
    required this.id,
    this.name,
    this.city,
    required this.status,
    this.startedAt,
    required this.totalStops,
    required this.visitedStops,
    required this.pendingStops,
    required this.progressPercentage,
    required this.stops,
  });

  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] ?? {};

    return RouteModel(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      status: json['status'] ?? '',
      startedAt: json['started_at'],
      totalStops: progress['total_stops'] ?? 0,
      visitedStops: progress['visited_stops'] ?? 0,
      pendingStops: progress['pending_stops'] ?? 0,
      progressPercentage: progress['percentage'] ?? 0,
      stops: (json['stops'] as List? ?? [])
          .map((e) => RouteStopModel.fromJson(e))
          .toList(),
    );
  }
}
