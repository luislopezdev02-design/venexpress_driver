import 'dart:io';
import '../models/driver_model.dart';
import 'api_client.dart';

class AuthResult {
  final DriverUser user;
  final DriverModel driver;

  AuthResult({required this.user, required this.driver});
}

class AuthService {
  final ApiClient _client = ApiClient();

  Future<AuthResult> login(String email, String password) async {
    final deviceName = '${Platform.operatingSystem}-device';

    final response = await _client.post('/driver/login', body: {
      'email': email,
      'password': password,
      'device_name': deviceName,
    });

    await _client.saveToken(response['token']);

    return AuthResult(
      user: DriverUser.fromJson(response['user']),
      driver: DriverModel.fromJson(response['driver']),
    );
  }

  Future<void> logout() async {
    try {
      await _client.post('/driver/logout');
    } catch (_) {
      // Si el token ya no era válido, igual limpiamos localmente.
    } finally {
      await _client.clearToken();
    }
  }

  Future<bool> hasSession() async {
    final token = await _client.getToken();
    return token != null;
  }

  Future<AuthResult?> me() async {
    try {
      final response = await _client.get('/driver/me');
      return AuthResult(
        user: DriverUser.fromJson(response['user']),
        driver: DriverModel.fromJson(response['driver']),
      );
    } catch (_) {
      return null;
    }
  }
}
