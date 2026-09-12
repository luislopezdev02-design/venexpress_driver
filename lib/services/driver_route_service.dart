import '../models/route_model.dart';
import 'api_client.dart';

class DriverRouteService {
  final ApiClient _client = ApiClient();

  Future<RouteModel?> getActiveRoute() async {
    final response = await _client.get('/driver/route');

    if (response['route'] == null) return null;

    return RouteModel.fromJson(response['route']);
  }

  Future<RouteModel> startRoute() async {
    final response = await _client.post('/driver/route/start');
    return RouteModel.fromJson(response['route']);
  }
}
