class IncidentModel {
  final int id;
  final int packageId;
  final String type;
  final String description;
  final String status;
  final String? createdAt;
  final String? resolvedAt;
  final String? resolutionNotes;

  IncidentModel({
    required this.id,
    required this.packageId,
    required this.type,
    required this.description,
    required this.status,
    this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  bool get isResolved => status == 'resuelta' || status == 'cerrada';

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'],
      packageId: json['package_id'],
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'],
      resolvedAt: json['resolved_at'],
      resolutionNotes: json['resolution_notes'],
    );
  }
}

/// Motivos disponibles al reportar, igual que en el backend
/// (App\Http\Controllers\Api\DriverIncidentController::TYPES).
class IncidentType {
  static const clienteAusente = 'CLIENTE_AUSENTE';
  static const direccionIncorrecta = 'DIRECCION_INCORRECTA';
  static const paqueteDanado = 'PAQUETE_DANADO';
  static const rechazadoPorCliente = 'RECHAZADO_POR_CLIENTE';
  static const otro = 'OTRO';

  static const Map<String, String> labels = {
    clienteAusente: 'Cliente ausente',
    direccionIncorrecta: 'Dirección incorrecta',
    paqueteDanado: 'Paquete dañado',
    rechazadoPorCliente: 'Rechazado por el cliente',
    otro: 'Otro',
  };
}
