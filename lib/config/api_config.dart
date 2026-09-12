/// Configuración central de la API.
///
/// Cambia solo [baseUrl] al pasar de desarrollo local a producción.
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
  static const String baseUrl = 'http://192.168.0.164/venexpress/public/api';

  // Producción: la URL real de venexpress.com (o el dominio que uses).
  // static const String baseUrl = 'https://tu-dominio.com/api';

  // Emulador Android apuntando a este mismo XAMPP:
  // static const String baseUrl = 'http://10.0.2.2/venexpress/public/api';

  static const Duration timeout = Duration(seconds: 20);
}
