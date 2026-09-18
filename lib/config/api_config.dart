import 'package:flutter/foundation.dart' show kReleaseMode;

/// Configuración central de la API.
///
/// [baseUrl] se define en tiempo de compilación con:
///
///   flutter run  --dart-define=API_BASE_URL=http://192.168.1.50/venexpress/public/api
///   flutter build apk --dart-define=API_BASE_URL=https://tu-dominio.com/api
///
/// Así el mismo código nunca "olvida" apuntar a producción: un build
/// de release sin --dart-define falla en el arranque en vez de
/// quedarse silenciosamente pegado a una IP de desarrollo por HTTP.
///
/// - Emulador Android apuntando a tu XAMPP local: usa 10.0.2.2 en
///   lugar de 127.0.0.1 (127.0.0.1 dentro del emulador apunta al
///   propio emulador, no a tu PC).
/// - Dispositivo físico en la misma red que tu PC: usa la IP local
///   de tu PC, ej. http://192.168.1.50/venexpress/public/api
class ApiConfig {
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  // Valor de conveniencia solo para `flutter run` en debug sin pasar
  // --dart-define. Si tu IP local cambia (DHCP), actualiza este valor
  // o simplemente pasa --dart-define=API_BASE_URL=... en su lugar.
  static const String _devFallbackBaseUrl =
      'http://192.168.0.164/venexpress/public/api';

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL no fue definido. Compila con '
        '--dart-define=API_BASE_URL=https://tu-dominio.com/api',
      );
    }

    return _devFallbackBaseUrl;
  }

  static const Duration timeout = Duration(seconds: 20);
}
