import '../models/incident_model.dart';
import 'api_client.dart';

class IncidentService {
  final ApiClient _client = ApiClient();

  Future<IncidentModel> report({
    required int packageId,
    required String type,
    required String description,
  }) async {
    final response = await _client.post('/driver/packages/$packageId/incidents', body: {
      'type': type,
      'description': description,
    });

    return IncidentModel.fromJson(response['incident']);
  }

  Future<List<IncidentModel>> listFor(int packageId) async {
    final response = await _client.get('/driver/packages/$packageId/incidents');

    return (response['data'] as List)
        .map((e) => IncidentModel.fromJson(e))
        .toList();
  }
}
