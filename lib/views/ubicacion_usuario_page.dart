import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/usuario.dart';

/// Muestra en un mapa (OpenStreetMap, gratis) la última ubicación
/// que compartió el usuario.
class UbicacionUsuarioPage extends StatelessWidget {
  final Usuario usuario;
  const UbicacionUsuarioPage({super.key, required this.usuario});

  String _formatearFecha(String? iso) {
    final f = iso == null ? null : DateTime.tryParse(iso);
    if (f == null) return 'Sin fecha';
    String d(int n) => n.toString().padLeft(2, '0');
    return '${d(f.day)}/${d(f.month)}/${f.year} ${d(f.hour)}:${d(f.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(usuario.latitud!, usuario.longitud!);

    return Scaffold(
      appBar: AppBar(title: Text('Ubicación de ${usuario.nombre}')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: punto, initialZoom: 16),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Ajusta si tu applicationId es otro (android/app/build.gradle)
                  userAgentPackageName: 'com.example.app_contador',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: punto,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 48),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© colaboradores de OpenStreetMap'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario.nombreCompleto,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(usuario.correo),
                const SizedBox(height: 8),
                Text(usuario.direccion ?? 'Dirección no disponible'),
                const SizedBox(height: 4),
                Text(
                  'Lat: ${usuario.latitud!.toStringAsFixed(5)}   '
                  'Lng: ${usuario.longitud!.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Actualizada: ${_formatearFecha(usuario.ubicacionFecha)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
