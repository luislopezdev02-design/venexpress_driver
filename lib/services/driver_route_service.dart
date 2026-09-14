import '../models/route_model.dart';
import 'api_client.dart';

class DriverRouteService {
  final ApiClient _client = ApiClient();

  Future<RouteModel?> getActiveRoute() async {
    final response = await _client.get('/driver/route');

    if (response['route'] == null) return null;

    final route = RouteModel.fromJson(response['route']);

    if (response['hub_scan'] != null) {
      route.hubScan = HubScanInfo.fromJson(response['hub_scan']);
    }

    return route;
  }

  Future<RouteModel> startRoute() async {
    final response = await _client.post('/driver/route/start');
    return RouteModel.fromJson(response['route']);
  }

  /// Rutas hub_transfer/hub_distribution sin repartidor asignado,
  /// compatibles con el tipo de repartidor autenticado (mismo criterio
  /// que RouteService::availableRoutesFor() en el backend).
  Future<List<RouteModel>> getAvailableRoutes() async {
    final response = await _client.get('/driver/route/available');
    return (response['data'] as List? ?? [])
        .map((e) => RouteModel.fromJson(e))
        .toList();
  }

  /// "Primero en tomar, primero en repartir": si otro repartidor la
  /// toma primero, el backend devuelve un 422 con un mensaje claro.
  Future<RouteModel> claimRoute(int routeId) async {
    final response = await _client.post('/driver/route/$routeId/claim');
    return RouteModel.fromJson(response['route']);
  }

  /// Finaliza la ruta en curso. El backend rechaza el cierre si
  /// quedan paquetes pendientes en alguna parada.
  Future<RouteModel> completeRoute() async {
    final response = await _client.post('/driver/route/complete');
    return RouteModel.fromJson(response['route']);
  }
}
