import 'package:flutter/foundation.dart';
import '../models/driver_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/// [offline]: hay una sesión guardada pero no se pudo validar por falta
/// de conexión (o un error temporal del servidor). No se borra el
/// token: la app ofrece reintentar en vez de mandar al login.
enum AuthStatus { unknown, authenticated, unauthenticated, offline }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  DriverUser? user;
  DriverModel? driver;
  String? errorMessage;
  bool isLoading = false;

  /// Lo asigna main.dart para navegar al login (fuera de cualquier
  /// BuildContext) cuando la sesión deja de ser válida.
  VoidCallback? onSessionExpired;

  AuthProvider() {
    ApiClient.onUnauthorized = _handleUnauthorized;
  }

  /// Cualquier 401 del backend (token vencido o revocado) devuelve al
  /// login desde cualquier pantalla. Ver ApiClient.onUnauthorized.
  void _handleUnauthorized() {
    if (status != AuthStatus.authenticated) {
      return;
    }

    user = null;
    driver = null;
    errorMessage = 'Tu sesión expiró. Inicia sesión de nuevo.';
    status = AuthStatus.unauthenticated;
    notifyListeners();

    onSessionExpired?.call();
  }

  /// Se llama al abrir la app (y al pulsar "Reintentar" sin conexión),
  /// para saber si ya hay una sesión guardada y validarla contra el
  /// backend.
  Future<void> checkSession() async {
    if (status == AuthStatus.offline) {
      status = AuthStatus.unknown;
      notifyListeners();
    }

    final hasSession = await _authService.hasSession();

    if (!hasSession) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final result = await _authService.me();
      user = result.user;
      driver = result.driver;
      errorMessage = null;
      status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // 401: sesión vencida/revocada. 403: la cuenta ya no está
        // habilitada para operar (suspendida, rechazada...).
        await _authService.clearLocalSession();
        user = null;
        driver = null;
        errorMessage = e.message;
        status = AuthStatus.unauthenticated;
      } else {
        errorMessage = e.message;
        status = AuthStatus.offline;
      }
    } catch (_) {
      errorMessage = 'No se pudo conectar con Venexpress. Verifica tu conexión a internet.';
      status = AuthStatus.offline;
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
    errorMessage = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
