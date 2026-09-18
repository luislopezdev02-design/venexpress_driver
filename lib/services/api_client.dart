import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Excepción con el mensaje ya listo para mostrar al usuario (viene
/// del campo "message" que devuelven nuestros controllers Laravel).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'venexpress_driver_token';

  /// Se dispara cuando el backend rechaza el token (401), justo
  /// después de borrarlo del almacenamiento seguro. AuthProvider se
  /// suscribe a esto para volver a AuthStatus.unauthenticated, y así
  /// la app regresa sola al login en vez de seguir reintentando
  /// requests con un token ya revocado hasta que el usuario toque
  /// "Cerrar sesión" manualmente.
  static void Function()? onUnauthorized;

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http
        .get(_uri(path, query), headers: await _headers())
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http
        .post(
          _uri(path),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  /// POST con multipart, para endpoints que reciben una foto (ej.
  /// completar entrega con evidencia).
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    File? file,
    String fileFieldName = 'photo',
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);

    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    request.fields.addAll(fields);

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(fileFieldName, file.path));
    }

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);

    return _handleResponse(response);
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    Map<String, dynamic>? decoded;

    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // 422: errores de validación de Laravel (incluye "errors": {...})
    if (response.statusCode == 422 && decoded != null) {
      if (decoded['errors'] != null) {
        final errors = decoded['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        final message = (firstError is List && firstError.isNotEmpty)
            ? firstError.first.toString()
            : decoded['message']?.toString() ?? 'Datos inválidos.';
        throw ApiException(message, statusCode: 422);
      }

      throw ApiException(
        decoded['message'] ?? 'No se pudo procesar la solicitud.',
        statusCode: 422,
      );
    }

    if (response.statusCode == 401) {
      await clearToken();
      onUnauthorized?.call();
      throw ApiException('Tu sesión expiró. Inicia sesión de nuevo.', statusCode: 401);
    }

    if (response.statusCode == 403) {
      throw ApiException(
        decoded?['message'] ?? 'No tienes permiso para esta acción.',
        statusCode: 403,
      );
    }

    if (response.statusCode == 404) {
      throw ApiException(decoded?['message'] ?? 'No se encontró el recurso.', statusCode: 404);
    }

    throw ApiException(
      decoded?['message'] ?? 'Ocurrió un error inesperado (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
