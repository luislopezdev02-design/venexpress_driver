class DriverModel {
  final int id;
  final String status;
  final String? driverType;
  final String? vehiclePlate;
  final String? vehicleType;

  DriverModel({
    required this.id,
    required this.status,
    this.driverType,
    this.vehiclePlate,
    this.vehicleType,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      status: json['status'] ?? '',
      driverType: json['driver_type'],
      vehiclePlate: json['vehicle_plate'],
      vehicleType: json['vehicle_type'],
    );
  }
}

class DriverUser {
  final int id;
  final String name;
  final String email;
  final String? phone;

  DriverUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    return DriverUser(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
    );
  }
}

class DashboardSummary {
  final int assigned;
  final int pendingToDeliver;
  final int delivered;
  final int deliveredToday;
  final int codPending;
  final double commissionRatePerPackage;
  final double commissionPendingUsd;
  final double commissionPaidUsd;

  DashboardSummary({
    required this.assigned,
    required this.pendingToDeliver,
    required this.delivered,
    required this.deliveredToday,
    required this.codPending,
    required this.commissionRatePerPackage,
    required this.commissionPendingUsd,
    required this.commissionPaidUsd,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final packages = json['packages'] ?? {};
    final commissions = json['commissions'] ?? {};

    return DashboardSummary(
      assigned: packages['assigned'] ?? 0,
      pendingToDeliver: packages['pending_to_deliver'] ?? 0,
      delivered: packages['delivered'] ?? 0,
      deliveredToday: packages['delivered_today'] ?? 0,
      codPending: packages['cod_pending'] ?? 0,
      commissionRatePerPackage:
          (commissions['rate_per_package_usd'] as num?)?.toDouble() ?? 0,
      commissionPendingUsd:
          (commissions['pending_usd'] as num?)?.toDouble() ?? 0,
      commissionPaidUsd: (commissions['paid_usd'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DriverPaymentModel {
  final int id;
  final int packageId;
  final String? trackingNumber;
  final double amountUsd;
  final String status;
  final String? paidAt;
  final String? createdAt;

  DriverPaymentModel({
    required this.id,
    required this.packageId,
    this.trackingNumber,
    required this.amountUsd,
    required this.status,
    this.paidAt,
    this.createdAt,
  });

  factory DriverPaymentModel.fromJson(Map<String, dynamic> json) {
    return DriverPaymentModel(
      id: json['id'],
      packageId: json['package_id'],
      trackingNumber: json['tracking_number'],
      amountUsd: (json['amount_usd'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
      paidAt: json['paid_at'],
      createdAt: json['created_at'],
    );
  }
}
