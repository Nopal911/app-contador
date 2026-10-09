import 'dart:math';
import 'email_service.dart';

class _Otp {
  final String codigo;
  final DateTime expira;
  int intentos = 0;
  _Otp(this.codigo, this.expira);
}

/// Resultado de verificar un código.
class OtpResultado {
  final bool ok;
  final String? mensaje;

  /// true = el código se invalidó (demasiados intentos) y el usuario
  /// debe volver al login e ingresar su contraseña otra vez.
  final bool reiniciar;

  const OtpResultado.exito()
      : ok = true,
        mensaje = null,
        reiniciar = false;
  const OtpResultado.error(this.mensaje, {this.reiniciar = false}) : ok = false;
}

/// Segundo factor (2FA) por correo: código de 6 dígitos de un solo uso.
/// - Expira a los 5 minutos.
/// - Máximo 5 intentos fallidos; después hay que iniciar sesión de nuevo.
/// - 60 segundos de espera para reenviar el código.
class OtpService {
  static const int _minutosExpira = 5;
  static const int _maxIntentos = 5;
  static const int _segundosEspera = 60;

  static final Map<String, _Otp> _activos = {};
  static final Map<String, DateTime> _ultimoEnvio = {};

  static String _normalizar(String c) => c.trim().toLowerCase();

  static String _generarCodigo() {
    final r = Random.secure();
    return (100000 + r.nextInt(900000)).toString();
  }

  /// Genera y envía un código nuevo (invalida el anterior).
  /// Devuelve null si se envió bien, o el texto del error.
  static Future<String?> enviarCodigo(String correo) async {
    final c = _normalizar(correo);
    final codigo = _generarCodigo();

    _activos[c] = _Otp(
      codigo,
      DateTime.now().add(const Duration(minutes: _minutosExpira)),
    );
    _ultimoEnvio[c] = DateTime.now();

    final error = await EmailService.enviarCodigoVerificacion(
      destinatario: correo.trim(),
      codigo: codigo,
      minutos: _minutosExpira,
    );
    if (error != null) {
      _activos.remove(c);
      return error;
    }
    return null;
  }

  /// Igual que [enviarCodigo] pero respetando la espera de 60 segundos.
  static Future<String?> reenviarCodigo(String correo) async {
    final c = _normalizar(correo);
    final ultimo = _ultimoEnvio[c];
    if (ultimo != null) {
      final falta =
          _segundosEspera - DateTime.now().difference(ultimo).inSeconds;
      if (falta > 0) return 'Espera $falta segundos antes de reenviar el código';
    }
    return enviarCodigo(correo);
  }

  static OtpResultado verificar(String correo, String codigo) {
    final c = _normalizar(correo);
    final cod = codigo.trim();

    if (cod.isEmpty) {
      return const OtpResultado.error('Ingresa el código que te enviamos');
    }

    const caducado = 'El código expiró o ya no es válido. Pulsa "Reenviar código"';
    final otp = _activos[c];
    if (otp == null) return const OtpResultado.error(caducado);

    if (DateTime.now().isAfter(otp.expira)) {
      _activos.remove(c);
      return const OtpResultado.error(caducado);
    }

    if (otp.codigo != cod) {
      otp.intentos++;
      if (otp.intentos >= _maxIntentos) {
        _activos.remove(c);
        return const OtpResultado.error(
          'Demasiados intentos. Inicia sesión de nuevo',
          reiniciar: true,
        );
      }
      return OtpResultado.error(
        'Código incorrecto (${_maxIntentos - otp.intentos} intentos restantes)',
      );
    }

    _activos.remove(c); // De un solo uso
    return const OtpResultado.exito();
  }

  /// Invalida cualquier código pendiente (al cancelar o salir de la pantalla).
  static void cancelar(String correo) => _activos.remove(_normalizar(correo));
}
