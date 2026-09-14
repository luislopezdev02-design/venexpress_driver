import '../models/package_model.dart';
import 'api_client.dart';

class HubScanResult {
  final String message;
  final PackageModel package;

  HubScanResult({required this.message, required this.package});
}

/// Escaneos del repartidor de HUB (driver_type = 'hub'), replicando el
/// mismo flujo de dos pasos que Livewire\Driver\Scanner en el portal
/// web: primero [lookup] identifica la guía sin ejecutar nada, y con
/// esa respuesta la UI decide qué operación proponer; solo al
/// confirmar se llama al método que sí cambia el estado del paquete.
class HubScanService {
  final ApiClient _client = ApiClient();

  /// Identifica una guía por su tracking number sin ejecutar ningún
  /// movimiento. Lanza ApiException(statusCode: 404) si no existe.
  Future<PackageModel> lookup(String trackingNumber) async {
    final response = await _client.get('/driver/packages/lookup', query: {
      'tracking_number': trackingNumber,
    });

    return PackageModel.fromJson(response['package']);
  }

  /// Recolección en la agencia aliada (RECIBIDO_AGENCIA -> RECOLECTADO_VENEXPRESS).
  /// Ruta hub_transfer, primer escaneo.
  Future<HubScanResult> scanCollection(String trackingNumber) => _post('/driver/scan', trackingNumber);

  /// Recepción física en el HUB (RECOLECTADO_VENEXPRESS -> EN_HUB).
  /// Ruta hub_transfer, segundo escaneo.
  Future<HubScanResult> scanHubReception(String trackingNumber) =>
      _post('/driver/scan/hub-reception', trackingNumber);

  /// Salida del HUB hacia el almacén destino (EN_HUB -> EN_TRANSITO_NACIONAL).
  /// Ruta hub_distribution, primer escaneo.
  Future<HubScanResult> scanHubDispatch(String trackingNumber) => _post('/driver/hub/dispatch', trackingNumber);

  /// Llegada al almacén destino (no cambia el estado, solo libera la
  /// custodia del driver de HUB). Ruta hub_distribution, segundo escaneo.
  Future<HubScanResult> scanHubArrival(String trackingNumber) => _post('/driver/hub/arrival', trackingNumber);

  Future<HubScanResult> _post(String path, String trackingNumber) async {
    final response = await _client.post(path, body: {
      'tracking_number': trackingNumber,
    });

    return HubScanResult(
      message: response['message'] ?? '',
      package: PackageModel.fromJson(response['package']),
    );
  }
}

/// Operación de escaneo propuesta para una guía dada, calculada en el
/// cliente con la MISMA lógica que
/// Livewire\Driver\Scanner::resolveOperation() del portal web: depende
/// únicamente del route_type de la ruta activa y del current_status
/// del paquete. Las validaciones reales (agencia/parada/ruta,
/// driver_id, custodia) siguen viviendo solo en el backend
/// (LogisticsScanService); esto es puramente para decidir qué botón
/// de confirmación mostrar.
class HubOperation {
  final String key; // 'collection' | 'hub_reception' | 'hub_departure' | 'hub_arrival'
  final String title;
  final String cta;
  final String hint;

  const HubOperation({
    required this.key,
    required this.title,
    required this.cta,
    required this.hint,
  });
}

class HubOperationResolution {
  final HubOperation? operation;
  final String? blockedReason;

  const HubOperationResolution.eligible(this.operation) : blockedReason = null;

  const HubOperationResolution.blocked(String reason)
      : operation = null,
        blockedReason = reason;

  bool get isEligible => operation != null;
}

HubOperationResolution resolveHubOperation({
  required String? activeRouteType,
  required String packageCurrentStatus,
  required String packageStatusLabel,
}) {
  if (activeRouteType == 'hub_transfer') {
    if (packageCurrentStatus == 'RECIBIDO_AGENCIA') {
      return const HubOperationResolution.eligible(HubOperation(
        key: 'collection',
        title: 'Registrar recolección',
        cta: 'Confirmar recolección',
        hint: 'Guía localizada en la agencia. Confirma para registrar la salida hacia Venexpress.',
      ));
    }

    if (packageCurrentStatus == 'RECOLECTADO_VENEXPRESS') {
      return const HubOperationResolution.eligible(HubOperation(
        key: 'hub_reception',
        title: 'Registrar recepción en HUB',
        cta: 'Confirmar recepción en HUB',
        hint: 'La recolección de esta guía ya fue registrada. Siguiente etapa: recepción en HUB.',
      ));
    }

    return HubOperationResolution.blocked(
      'Este paquete no está en un estado válido para tu ruta de recolección. '
      'Estado actual: $packageStatusLabel.',
    );
  }

  if (activeRouteType == 'hub_distribution') {
    if (packageCurrentStatus == 'EN_HUB') {
      return const HubOperationResolution.eligible(HubOperation(
        key: 'hub_departure',
        title: 'Registrar salida de HUB',
        cta: 'Confirmar salida de HUB',
        hint: 'Guía localizada en HUB. Confirma para registrar su salida hacia el almacén destino.',
      ));
    }

    if (packageCurrentStatus == 'EN_TRANSITO_NACIONAL') {
      return const HubOperationResolution.eligible(HubOperation(
        key: 'hub_arrival',
        title: 'Registrar llegada a almacén',
        cta: 'Confirmar llegada a almacén',
        hint: 'Este paquete ya salió del HUB y está en tránsito nacional. Siguiente etapa: llegada al almacén destino.',
      ));
    }

    return HubOperationResolution.blocked(
      'Este paquete no está en un estado válido para tu ruta de distribución. '
      'Estado actual: $packageStatusLabel.',
    );
  }

  return HubOperationResolution.blocked(
    'Tipo de ruta no soportado para escaneo: ${activeRouteType ?? "ninguna"}.',
  );
}
