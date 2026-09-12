import 'package:flutter/foundation.dart';
import '../models/driver_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  DriverUser? user;
  DriverModel? driver;
  String? errorMessage;
  bool isLoading = false;

  /// Se llama al abrir la app, para saber si ya hay una sesión
  /// guardada y validarla contra el backend.
  Future<void> checkSession() async {
    final hasSession = await _authService.hasSession();

    if (!hasSession) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final result = await _authService.me();

    if (result == null) {
      status = AuthStatus.unauthenticated;
    } else {
      user = result.user;
      driver = result.driver;
      status = AuthStatus.authenticated;
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      user = result.user;
      driver = result.driver;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'No se pudo conectar. Verifica tu conexión a internet.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    driver = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
