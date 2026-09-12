import 'package:flutter/foundation.dart' show kReleaseMode;

/// Configuración central de la API.
///
/// La URL se elige SOLA según el tipo de build, usando [kReleaseMode]:
/// - `flutter run` (debug)            -> usa [_devBaseUrl]
/// - `flutter build apk --release`    -> usa [_prodBaseUrl]
///
/// Así no hay que acordarse de cambiar nada a mano antes de compilar el
/// APK final: solo edita las dos constantes de abajo una vez y listo.
///
/// --- Cómo editar [_devBaseUrl] ---
/// - Emulador Android apuntando a tu XAMPP local: usa 10.0.2.2 en
///   lugar de 127.0.0.1 (127.0.0.1 dentro del emulador apunta al
///   propio emulador, no a tu PC).
///     'http://10.0.2.2:8000/api'
/// - Teléfono físico en la MISMA red WiFi que tu PC: usa la IP local
///   de tu PC (ej. ipconfig / ifconfig), y arranca Laravel con
///   `php artisan serve --host=0.0.0.0` para que escuche en la red:
///     'http://192.168.1.50:8000/api'
///
/// --- Cómo editar [_prodBaseUrl] ---
/// - La URL real de tu dominio en producción, siempre con https://
///   (el build de release bloquea cleartext http:// a propósito,
///   ver network_security_config.xml).
///     'https://venexpress.com/api'
class ApiConfig {
  static const String _devBaseUrl = 'http://192.168.0.164:8000/api'; 
  static const String _prodBaseUrl = 'https://tu-dominio.com/api';

  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _devBaseUrl;

  static const Duration timeout = Duration(seconds: 20);
}
