import 'package_model.dart';

class DeliveryStop {
  final int order;
  final double distanceKm;
  final PackageModel package;

  DeliveryStop({
    required this.order,
    required this.distanceKm,
    required this.package,
  });

  factory DeliveryStop.fromJson(Map<String, dynamic> json) {
    return DeliveryStop(
      order: json['order'],
      distanceKm: (json['distance_km'] as num).toDouble(),
      package: PackageModel.fromJson(json['package']),
    );
  }
}
