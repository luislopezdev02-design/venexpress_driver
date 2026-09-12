import '../models/delivery_stop_model.dart';
import '../models/package_model.dart';
import 'api_client.dart';

class AvailableDeliveriesPage {
  final List<PackageModel> items;
  final int total;

  AvailableDeliveriesPage({required this.items, required this.total});
}

class RouteOrderResult {
  final List<DeliveryStop> stops;
  final List<String> pendingLocation;

  RouteOrderResult({required this.stops, required this.pendingLocation});
}

class DriverDeliveryService {
  final ApiClient _client = ApiClient();

  Future<AvailableDeliveriesPage> getAvailable({int page = 1}) async {
    final response = await _client.get('/driver/deliveries/available', query: {'page': page});

    final data = (response['data'] as List).map((e) => PackageModel.fromJson(e)).toList();
    final meta = response['meta'] ?? {};

    return AvailableDeliveriesPage(items: data, total: meta['total'] ?? data.length);
  }

  /// Reclama un pedido escaneando su QR. Si otro repartidor ya lo
  /// tomó, el backend devuelve 422 con un mensaje claro.
  Future<PackageModel> claimByScan(String trackingNumber) async {
    final response = await _client.post('/driver/deliveries/claim-by-scan', body: {
      'tracking_number': trackingNumber,
    });

    return PackageModel.fromJson(response['package']);
  }

  Future<PackageModel> claimById(int packageId) async {
    final response = await _client.post('/driver/packages/$packageId/claim');
    return PackageModel.fromJson(response['package']);
  }

  /// Pedidos ya reclamados por el repartidor, ordenados de más lejos
  /// a más cerca desde su ubicación GPS actual. Los que todavía no
  /// tengan coordenadas (se geocodifican en segundo plano) vienen
  /// aparte en pendingLocation.
  Future<RouteOrderResult> getRouteOrder({required double latitude, required double longitude}) async {
    final response = await _client.get('/driver/deliveries/route-order', query: {
      'latitude': latitude,
      'longitude': longitude,
    });

    final stops = (response['stops'] as List).map((e) => DeliveryStop.fromJson(e)).toList();
    final pending = (response['pending_location'] as List? ?? []).map((e) => e.toString()).toList();

    return RouteOrderResult(stops: stops, pendingLocation: pending);
  }
}
