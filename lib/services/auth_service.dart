import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
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
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    final deviceName = '$platform-${await _client.getDeviceId()}';

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

  /// Valida el token guardado. Lanza ApiException (401 sesión
  /// vencida, 403 cuenta no habilitada) o un error de red: quien
  /// llama decide, porque "sin internet" no debe tratarse igual que
  /// "sesión inválida" (antes ambos cerraban la sesión).
  Future<AuthResult> me() async {
    final response = await _client.get('/driver/me');

    return AuthResult(
      user: DriverUser.fromJson(response['user']),
      driver: DriverModel.fromJson(response['driver']),
    );
  }

  Future<void> clearLocalSession() => _client.clearToken();
}
