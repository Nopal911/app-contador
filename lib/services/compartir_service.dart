import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

/// Comparte un producto por WhatsApp, Facebook, Instagram, etc. usando el
/// menú nativo del teléfono. Incluye la foto si se puede descargar.
class CompartirService {
  /// Devuelve null si todo salió bien, o el texto del error.
  static Future<String?> compartirProducto({
    required String nombre,
    required dynamic precio,
    String? imagenUrl,
  }) async {
    final texto = '¡Mira este producto en Mi Tiendita!\n\n'
        'Producto: $nombre\n'
        'Precio: \$$precio MXN\n'
        '¡Consíguelo ahora!';

    try {
      XFile? foto;
      if (imagenUrl != null && imagenUrl.trim().isNotEmpty) {
        foto = await _descargarFoto(imagenUrl.trim());
      }

      await SharePlus.instance.share(
        ShareParams(
          text: texto,
          subject: 'Producto de Mi Tiendita',
          files: foto == null ? null : [foto],
          fileNameOverrides: foto == null ? null : [foto.name],
        ),
      );
      return null;
    } catch (e) {
      return 'No se pudo compartir: $e';
    }
  }

  /// Descarga la imagen del producto. Si falla, se comparte solo el texto.
  static Future<XFile?> _descargarFoto(String url) async {
    try {
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return null;

      final tipo =
          resp.headers['content-type']?.split(';').first.trim() ?? 'image/jpeg';
      if (!tipo.startsWith('image/')) return null;

      final ext = tipo.endsWith('png') ? 'png' : 'jpg';
      return XFile.fromData(
        resp.bodyBytes,
        mimeType: tipo,
        name: 'producto.$ext',
      );
    } catch (_) {
      return null;
    }
  }
}
