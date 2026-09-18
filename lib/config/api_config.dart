import 'package:flutter/foundation.dart' show kReleaseMode;

/// Configuración central de la API.
///
/// Cambia solo [_prodBaseUrl] al preparar un build de producción.
///
/// - Emulador Android apuntando a tu XAMPP local: usa 10.0.2.2 en
///   lugar de 127.0.0.1 (127.0.0.1 dentro del emulador apunta al
///   propio emulador, no a tu PC).
/// - Dispositivo físico en la misma red que tu PC: usa la IP local
///   de tu PC, ej. http://192.168.1.50:8000
/// - Producción: la URL real de venexpress.com (o el dominio que uses).
class ApiConfig {
  // Desarrollo local: celular físico en la misma red WiFi que esta PC,
  // apuntando al Apache de XAMPP (sin vhost, por eso pasa por /public).
  // Si tu IP local cambia (DHCP), actualiza este valor.
  static const String _devBaseUrl = 'http://192.168.0.164/venexpress/public/api';

  // Emulador Android apuntando a este mismo XAMPP:
  // static const String _devBaseUrl = 'http://10.0.2.2/venexpress/public/api';

  // Producción: reemplaza esto por la URL real de venexpress.com (o el
  // dominio que uses) antes de generar un build de release. Mientras
  // siga siendo este placeholder, baseUrl lanzará un error en vez de
  // compilar un release que en silencio intente conectarse a la IP de
  // desarrollo de arriba (que no existe fuera de esta red WiFi).
  static const String _prodBaseUrl = 'https://tu-dominio.com/api';

  static String get baseUrl {
    if (kReleaseMode) {
      if (_prodBaseUrl.contains('tu-dominio.com')) {
        throw StateError(
          'ApiConfig._prodBaseUrl todavía apunta al placeholder. '
          'Configura el dominio real de producción (https://...) en '
          'lib/config/api_config.dart antes de compilar un release.',
        );
      }

      return _prodBaseUrl;
    }

    return _devBaseUrl;
  }

  static const Duration timeout = Duration(seconds: 20);
}
