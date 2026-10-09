import 'dart:math';
import '../database/database_helper.dart';
import 'email_service.dart';

class _Solicitud {
  final String codigo;
  final DateTime expira;
  int intentos = 0;
  _Solicitud(this.codigo, this.expira);
}

/// Recuperación de contraseña por código de un solo uso.
/// - El código expira a los 10 minutos.
/// - Máximo 5 intentos fallidos por código.
/// - 60 segundos de espera entre solicitudes del mismo correo.
/// - Solo se actualiza la columna `pass`: el rol (role_id) NUNCA se toca.
class RecuperacionService {
  static const int _minutosExpira = 10;
  static const int _maxIntentos = 5;
  static const int _segundosEspera = 60;

  static final Map<String, _Solicitud> _solicitudes = {};
  static final Map<String, DateTime> _ultimoEnvio = {};

  static final RegExp _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

  static String _normalizar(String c) => c.trim().toLowerCase();

  static String _generarCodigo() {
    final r = Random.secure();
    return (100000 + r.nextInt(900000)).toString();
  }

  /// Devuelve null si todo salió bien. Por seguridad devuelve null también
  /// cuando el correo NO existe (para no revelar qué correos están registrados).
  static Future<String?> solicitarCodigo(String correoCrudo) async {
    final correo = _normalizar(correoCrudo);
    if (correo.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailRegex.hasMatch(correo)) {
      return 'El correo no tiene un formato válido';
    }

    final ultimo = _ultimoEnvio[correo];
    if (ultimo != null) {
      final falta =
          _segundosEspera - DateTime.now().difference(ultimo).inSeconds;
      if (falta > 0) return 'Espera $falta segundos antes de pedir otro código';
    }
    _ultimoEnvio[correo] = DateTime.now();

    final db = await DatabaseHelper.instance.database;
    final filas = await db.query(
      'user_app',
      columns: ['id'],
      where: 'LOWER(correo) = ?',
      whereArgs: [correo],
      limit: 1,
    );
    if (filas.isEmpty) return null; // No revelamos que no existe

    final codigo = _generarCodigo();
    _solicitudes[correo] = _Solicitud(
      codigo,
      DateTime.now().add(const Duration(minutes: _minutosExpira)),
    );

    final error = await EmailService.enviarCodigoRecuperacion(
      destinatario: correoCrudo.trim(),
      codigo: codigo,
      minutos: _minutosExpira,
    );
    if (error != null) {
      _solicitudes.remove(correo);
      return error;
    }
    return null;
  }

  /// Devuelve null si la contraseña se cambió, o un texto con el error.
  static Future<String?> restablecer({
    required String correo,
    required String codigo,
    required String nuevaPass,
  }) async {
    final c = _normalizar(correo);
    final pass = nuevaPass.trim();
    final cod = codigo.trim();

    if (cod.isEmpty) return 'Ingresa el código que te enviamos';
    if (pass.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    const invalido = 'Código inválido o expirado. Solicita uno nuevo';
    final s = _solicitudes[c];
    if (s == null) return invalido;

    if (DateTime.now().isAfter(s.expira)) {
      _solicitudes.remove(c);
      return invalido;
    }

    if (s.codigo != cod) {
      s.intentos++;
      if (s.intentos >= _maxIntentos) {
        _solicitudes.remove(c);
        return 'Demasiados intentos. Solicita un nuevo código';
      }
      return 'Código incorrecto (${_maxIntentos - s.intentos} intentos restantes)';
    }

    final db = await DatabaseHelper.instance.database;
    final filas = await db.update(
      'user_app',
      {'pass': pass}, // Solo la contraseña: el rol se conserva intacto
      where: 'LOWER(correo) = ?',
      whereArgs: [c],
    );

    _solicitudes.remove(c); // El código es de un solo uso
    if (filas == 0) return 'No se pudo actualizar la contraseña';
    return null;
  }
}