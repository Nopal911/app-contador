import 'package:google_sign_in/google_sign_in.dart';
import '../config/social_config.dart';
import '../database/database_helper.dart';
import 'usuario_service.dart';

class SocialResultado {
  final String? correo;
  final bool esAdmin;
  final String? error;
  final bool cancelado;

  const SocialResultado.exito({required this.correo, required this.esAdmin})
      : error = null,
        cancelado = false;
  const SocialResultado.error(this.error)
      : correo = null,
        esAdmin = false,
        cancelado = false;
  const SocialResultado.cancelado()
      : correo = null,
        esAdmin = false,
        error = null,
        cancelado = true;
}

/// Inicio de sesión con Google.
/// - Si el correo ya existe en la base de datos, entra con su rol actual.
/// - Si no existe, se registra automáticamente (mismo criterio de rol que
///   el registro normal) y entra.
/// Google ya verificó la identidad, así que no se pide el código OTP.
class GoogleAuthService {
  static bool _inicializado = false;

  static Future<SocialResultado> iniciarSesion() async {
    if (kGoogleServerClientId.startsWith('PEGA_AQUI')) {
      return const SocialResultado.error(
          'Falta configurar el ID de cliente de Google en '
          'lib/config/social_config.dart');
    }

    try {
      // En google_sign_in 7.x, initialize() se llama una sola vez
      if (!_inicializado) {
        await GoogleSignIn.instance
            .initialize(serverClientId: kGoogleServerClientId);
        _inicializado = true;
      }

      final cuenta = await GoogleSignIn.instance.authenticate();
      final correo = cuenta.email.trim();
      if (correo.isEmpty) {
        return const SocialResultado.error(
            'Tu cuenta de Google no devolvió un correo');
      }

      return await _entrar(correo, (cuenta.displayName ?? '').trim());
    } catch (e) {
      if (e.toString().toLowerCase().contains('cancel')) {
        return const SocialResultado.cancelado();
      }
      return SocialResultado.error('No se pudo iniciar sesión con Google: $e');
    }
  }

  static Future<SocialResultado> _entrar(
      String correo, String nombreCompleto) async {
    final db = DatabaseHelper.instance;
    var fila = await db.getUsuarioPorCorreo(correo);

    if (fila == null) {
      final partes = nombreCompleto
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      final nombre = partes.isNotEmpty ? partes.first : correo.split('@').first;
      final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

      final error = await UsuarioService().registrarUsuarioSocial(
        nombre: nombre,
        apellidoPaterno: apellidos,
        correo: correo,
      );
      if (error != null) return SocialResultado.error(error);

      fila = await db.getUsuarioPorCorreo(correo);
      if (fila == null) {
        return const SocialResultado.error('No se pudo crear tu cuenta');
      }
    }

    return SocialResultado.exito(
      correo: fila['correo'] as String,
      esAdmin: fila['rol_nombre'] == 'Administrador',
    );
  }
}
