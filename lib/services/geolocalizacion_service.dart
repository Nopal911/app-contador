import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class UbicacionException implements Exception {
  final String mensaje;
  UbicacionException(this.mensaje);
}

/// Ubicación 100 % gratuita, sin API key:
/// - Coordenadas: GPS del teléfono (paquete geolocator).
/// - Dirección legible: Nominatim (geocodificación inversa de OpenStreetMap).
///   Política de uso: máximo 1 petición por segundo y User-Agent identificable.
class GeolocalizacionService {
  static const String _userAgent = 'app_contador/1.0 (proyecto escolar)';

  /// Pide permiso (si hace falta) y devuelve la posición actual.
  /// Lanza [UbicacionException] con un mensaje claro si no se puede.
  static Future<Position> obtenerPosicionActual() async {
    final gpsActivo = await Geolocator.isLocationServiceEnabled();
    debugPrint('[GEO] 1. GPS activo: $gpsActivo');
    if (!gpsActivo) {
      throw UbicacionException(
          'Activa el GPS de tu dispositivo para compartir tu ubicación');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    debugPrint('[GEO] 2. permiso: $permiso');
    if (permiso == LocationPermission.denied) {
      throw UbicacionException('Permiso de ubicación denegado');
    }
    if (permiso == LocationPermission.deniedForever) {
      throw UbicacionException(
          'El permiso de ubicación está bloqueado. Actívalo en Ajustes del teléfono');
    }

    debugPrint('[GEO] 3. pidiendo posición (máx. 12 s)...');
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // Plan B: la última ubicación conocida del dispositivo
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) return ultima;
      throw UbicacionException(
          'No se pudo obtener la ubicación a tiempo. Si usas el emulador, '
          'configura una en Extended controls > Location');
    }
  }

  /// Convierte coordenadas en una dirección. Devuelve null si falla
  /// (no es crítico: las coordenadas se guardan de todos modos).
  static Future<String?> obtenerDireccion(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'accept-language': 'es',
      });
      final resp = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene la ubicación actual y la guarda en el usuario.
  /// Devuelve null si todo salió bien, o el texto del error.
  static Future<String?> guardarUbicacionUsuario(String correo) async {
    try {
      final pos = await obtenerPosicionActual();
      debugPrint('[GEO] 4. posición: ${pos.latitude}, ${pos.longitude}');
      final direccion = await obtenerDireccion(pos.latitude, pos.longitude);
      debugPrint('[GEO] 5. dirección: $direccion');
      await DatabaseHelper.instance.actualizarUbicacion(
        correo: correo,
        latitud: pos.latitude,
        longitud: pos.longitude,
        direccion: direccion,
      );
      debugPrint('[GEO] 6. guardado en la base de datos');
      return null;
    } on UbicacionException catch (e) {
      debugPrint('[GEO] error controlado: ${e.mensaje}');
      return e.mensaje;
    } catch (e) {
      debugPrint('[GEO] error inesperado: $e');
      return 'No se pudo obtener la ubicación: $e';
    }
  }
}
