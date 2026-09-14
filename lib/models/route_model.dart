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

class WarehouseStop {
  final int id;
  final String? name;
  final String? address;
  final String? city;
  final String? state;

  WarehouseStop({
    required this.id,
    this.name,
    this.address,
    this.city,
    this.state,
  });

  factory WarehouseStop.fromJson(Map<String, dynamic> json) {
    return WarehouseStop(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
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
  final WarehouseStop? warehouse;

  RouteStopModel({
    required this.id,
    required this.sequence,
    required this.status,
    required this.mapColor,
    required this.packagesCollectedCount,
    this.ally,
    this.warehouse,
  });

  bool get isVisited => status == 'visited';

  /// Nombre a mostrar sin importar si la parada es una agencia
  /// aliada (ruta hub_transfer / delivery) o un almacén propio
  /// (ruta hub_distribution).
  String get displayName =>
      ally?.name ?? warehouse?.name ?? 'Parada #$sequence';

  String? get displayAddress => ally?.address ?? warehouse?.address;

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      id: json['id'],
      sequence: json['sequence'] ?? 0,
      status: json['status'] ?? 'pending',
      mapColor: json['map_color'] ?? 'blue',
      packagesCollectedCount: json['packages_collected_count'] ?? 0,
      ally: json['ally'] != null ? AllyStop.fromJson(json['ally']) : null,
      warehouse: json['warehouse'] != null ? WarehouseStop.fromJson(json['warehouse']) : null,
    );
  }
}

/// Operación de escaneo vigente para un repartidor de HUB en su ruta
/// activa (calculada por el backend en DriverRouteController::active(),
/// con la MISMA lógica que Livewire\Driver\Dashboard::render() usa
/// para el portal web — así ambos nunca se contradicen). Null para
/// repartidores de entrega o cuando la ruta todavía no está en curso.
class HubScanInfo {
  final String operation; // 'collection' | 'hub_departure' | 'hub_arrival'
  final String title;
  final String subtitle;
  final String cta;
  final int? pendingCount;
  final String? nextStopName;
  final String? warehouseName;

  HubScanInfo({
    required this.operation,
    required this.title,
    required this.subtitle,
    required this.cta,
    this.pendingCount,
    this.nextStopName,
    this.warehouseName,
  });

  factory HubScanInfo.fromJson(Map<String, dynamic> json) {
    return HubScanInfo(
      operation: json['operation'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      cta: json['cta'] ?? '',
      pendingCount: json['pending_count'],
      nextStopName: json['next_stop_name'],
      warehouseName: json['warehouse_name'],
    );
  }
}

class RouteModel {
  final int id;
  final String? name;
  final String? city;
  final String? routeType;
  final String status;
  final String? startedAt;
  final int totalStops;
  final int visitedStops;
  final int pendingStops;
  final int progressPercentage;
  final List<RouteStopModel> stops;

  /// Solo viene poblado cuando este RouteModel se construyó a partir
  /// de la respuesta de /driver/route (ver DriverRouteService.getActiveRoute()).
  HubScanInfo? hubScan;

  RouteModel({
    required this.id,
    this.name,
    this.city,
    this.routeType,
    required this.status,
    this.startedAt,
    this.hubScan,
    required this.totalStops,
    required this.visitedStops,
    required this.pendingStops,
    required this.progressPercentage,
    required this.stops,
  });

  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isHubTransfer => routeType == 'hub_transfer';
  bool get isHubDistribution => routeType == 'hub_distribution';

  String get routeTypeLabel => switch (routeType) {
        'hub_transfer' => 'Recolección (Aliado → HUB)',
        'hub_distribution' => 'Distribución (HUB → Almacén)',
        'delivery' => 'Reparto a domicilio',
        _ => routeType ?? '',
      };

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] ?? {};

    return RouteModel(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      routeType: json['route_type'],
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
