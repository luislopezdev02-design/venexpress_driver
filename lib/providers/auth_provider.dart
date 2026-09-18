import 'package:flutter/material.dart';
import '../config/navigation.dart';
import '../models/driver_model.dart';
import '../screens/login_screen.dart';
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

  AuthProvider() {
    // Si cualquier request a la API recibe un 401 (token revocado o
    // expirado), ApiClient ya borró el token guardado; aquí reflejamos
    // eso en el estado de la app para que _SplashGate navegue solo de
    // vuelta al login, en vez de dejar al usuario viendo errores hasta
    // que toque "Cerrar sesión" manualmente.
    ApiClient.onUnauthorized = _handleUnauthorized;
  }

  void _handleUnauthorized() {
    if (status != AuthStatus.authenticated) {
      return;
    }

    user = null;
    driver = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();

    // Actualizar `status` solo mueve lo que hay debajo de todo en el
    // stack (_SplashGate, usado como `MaterialApp.home`). Si el
    // usuario está en cualquier pantalla empujada con Navigator.push
    // (la inmensa mayoría del uso real de la app), esa pantalla se
    // queda arriba tapando el login. Reseteamos el stack completo con
    // el mismo patrón que ya usa el botón manual de "Cerrar sesión"
    // (home_screen.dart), pero usando el navigatorKey global porque
    // aquí no hay un BuildContext propio.
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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
