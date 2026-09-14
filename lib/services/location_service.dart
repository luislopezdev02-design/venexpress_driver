import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Activa el GPS de tu teléfono para poder ordenar tus entregas por distancia.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Necesitamos permiso de ubicación para ordenar tus entregas.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'El permiso de ubicación está bloqueado. Actívalo desde los ajustes de la app.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      // Cualquier falla obteniendo la posición de alta precisión
      // (timeout, proveedor no disponible, error de la plataforma,
      // etc.) — probamos con la última ubicación conocida del
      // dispositivo antes de rendirnos, en vez de dejar al
      // repartidor sin ruta.
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {
        lastKnown = null;
      }

      if (lastKnown != null) return lastKnown;

      throw LocationException(
        'No se pudo obtener tu ubicación GPS. Sal a un lugar despejado (o cerca de una ventana) e inténtalo de nuevo.\n'
        '(detalle técnico: $e)',
      );
    }
  }
}
