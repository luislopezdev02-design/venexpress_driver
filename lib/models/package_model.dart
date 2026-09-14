class PersonInfo {
  final String? name;
  final String? idDoc;
  final String? phone;

  PersonInfo({this.name, this.idDoc, this.phone});

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      name: json['name'],
      idDoc: json['id_doc'],
      phone: json['phone'],
    );
  }
}

class PackageModel {
  final int id;
  final String trackingNumber;
  final String currentStatus;
  final String statusLabel;
  final String? deliveryStatus;
  final PersonInfo sender;
  final PersonInfo recipient;
  final String? destinationCity;
  final bool requiresDelivery;
  final String? deliveryAddress;
  final String? deliverySector;
  final String? deliveryReference;
  final String packageType;
  final bool isFragile;
  final bool isCod;
  final double? codAmountUsd;
  final String? codStatus;
  final String? codCollectedAt;
  final String? codPaymentMethod;
  final double? driverRemunerationUsd;
  final String? driverRemunerationStatus;
  final bool securityWarning;
  final int? incidentsCount;
  final String? updatedAt;
  final String? deliveryCompletedAt;

  PackageModel({
    required this.id,
    required this.trackingNumber,
    required this.currentStatus,
    required this.statusLabel,
    this.deliveryStatus,
    required this.sender,
    required this.recipient,
    this.destinationCity,
    required this.requiresDelivery,
    this.deliveryAddress,
    this.deliverySector,
    this.deliveryReference,
    required this.packageType,
    required this.isFragile,
    required this.isCod,
    this.codAmountUsd,
    this.codStatus,
    this.codCollectedAt,
    this.codPaymentMethod,
    this.driverRemunerationUsd,
    this.driverRemunerationStatus,
    required this.securityWarning,
    this.incidentsCount,
    this.updatedAt,
    this.deliveryCompletedAt,
  });

  bool get isDelivered => currentStatus == 'ENTREGADO';

  bool get codPendingCollection =>
      isCod && isDelivered && codStatus != 'liquidado' && codCollectedAt == null;

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      trackingNumber: json['tracking_number'] ?? '',
      currentStatus: json['current_status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      deliveryStatus: json['delivery_status'],
      sender: PersonInfo.fromJson(json['sender'] ?? {}),
      recipient: PersonInfo.fromJson(json['recipient'] ?? {}),
      destinationCity: json['destination_city'],
      requiresDelivery: json['requires_delivery'] ?? false,
      deliveryAddress: json['delivery_address'],
      deliverySector: json['delivery_sector'],
      deliveryReference: json['delivery_reference'],
      packageType: json['package_type'] ?? '',
      isFragile: json['is_fragile'] ?? false,
      isCod: json['is_cod'] ?? false,
      codAmountUsd: (json['cod_amount_usd'] as num?)?.toDouble(),
      codStatus: json['cod_status'],
      codCollectedAt: json['cod_collected_at'],
      codPaymentMethod: json['cod_payment_method'],
      driverRemunerationUsd: (json['driver_remuneration_usd'] as num?)?.toDouble(),
      driverRemunerationStatus: json['driver_remuneration_status'],
      securityWarning: json['security_warning'] ?? false,
      incidentsCount: json['incidents_count'],
      updatedAt: json['updated_at'],
      deliveryCompletedAt: json['delivery_completed_at'],
    );
  }
}
