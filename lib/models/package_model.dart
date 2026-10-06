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
  final bool hasDeliveryPin;
  final int? deliveryPinAttemptsLeft;
  final String? deliveryConfirmationMethod;
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
  final String? codPaymentReference;
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
    this.hasDeliveryPin = false,
    this.deliveryPinAttemptsLeft,
    this.deliveryConfirmationMethod,
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
    this.codPaymentReference,
    this.driverRemunerationUsd,
    this.driverRemunerationStatus,
    required this.securityWarning,
    this.incidentsCount,
    this.updatedAt,
    this.deliveryCompletedAt,
  });

  bool get isDelivered => currentStatus == 'ENTREGADO';

  /// Salió a reparto con este repartidor: solo desde aquí se puede
  /// confirmar la entrega a domicilio.
  bool get isOutForDelivery => currentStatus == 'EN_RUTA';

  /// COD que todavía hay que cobrarle al destinatario al entregar.
  bool get codPendingAtDelivery => isCod && codCollectedAt == null;

  bool get codPendingCollection =>
      isCod && isDelivered && codStatus != 'liquidado' && codCollectedAt == null;

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      trackingNumber: json['tracking_number'] ?? '',
      currentStatus: json['current_status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      deliveryStatus: json['delivery_status'],
      hasDeliveryPin: json['has_delivery_pin'] ?? false,
      deliveryPinAttemptsLeft: json['delivery_pin_attempts_left'],
      deliveryConfirmationMethod: json['delivery_confirmation_method'],
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
      codPaymentReference: json['cod_payment_reference'],
      driverRemunerationUsd: (json['driver_remuneration_usd'] as num?)?.toDouble(),
      driverRemunerationStatus: json['driver_remuneration_status'],
      securityWarning: json['security_warning'] ?? false,
      incidentsCount: json['incidents_count'],
      updatedAt: json['updated_at'],
      deliveryCompletedAt: json['delivery_completed_at'],
    );
  }
}
