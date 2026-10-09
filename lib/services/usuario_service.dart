import 'dart:math';
import '../database/database_helper.dart';
import '../models/usuario.dart';
import '../models/rol.dart';

class UsuarioService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Usuario>> obtenerUsuarios() async {
    final maps = await _dbHelper.getUsuarios();
    return maps.map((map) => Usuario.fromMap(map)).toList();
  }

  Future<List<Rol>> obtenerRoles() async {
    final maps = await _dbHelper.getRoles();
    return maps.map((map) => Rol.fromMap(map)).toList();
  }

  Future<String?> registrarUsuario(Usuario usuario, String confirmarPass) async {
    final nombre = usuario.nombre.trim();
    final apellidoPaterno = usuario.apellidoPaterno.trim();
    final apellidoMaterno = usuario.apellidoMaterno?.trim();
    final correo = usuario.correo.trim();
    final pass = usuario.pass.trim();

    if (nombre.isEmpty) return 'El nombre es obligatorio';
    if (apellidoPaterno.isEmpty) return 'El apellido paterno es obligatorio';
    if (correo.isEmpty) return 'El correo es obligatorio';

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(correo)) {
      return 'El correo no tiene un formato válido';
    }

    if (pass.isEmpty) return 'La contraseña es obligatoria';
    if (pass.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (pass != confirmarPass.trim()) return 'Las contraseñas no coinciden';

    if (await _dbHelper.existeCorreo(correo)) {
      return 'Ya existe un usuario registrado con ese correo';
    }

    // ══════════════════════════════════════════════════════════════
    // REGLA: decidimos el rol automáticamente, SIN preguntarle
    // al usuario. Ya no usamos usuario.roleId que venga de fuera.
    // ══════════════════════════════════════════════════════════════

    // Preguntamos cuántos administradores hay YA registrados
    final totalAdmins = await _dbHelper.contarAdmins();

    // Si hay MENOS de 2 admins, este nuevo registro será Administrador (id 1).
    // A partir del tercer registro en adelante, será Usuario normal (id 2).
    final int roleIdFinal = totalAdmins < 2 ? 1 : 2;

    try {
      final usuarioLimpio = Usuario(
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        // Si el materno viene vacío se guarda NULL
        apellidoMaterno: (apellidoMaterno == null || apellidoMaterno.isEmpty)
            ? null
            : apellidoMaterno,
        correo: correo,
        pass: pass,
        desc: usuario.desc?.trim(),
        roleId: roleIdFinal, // Usamos el rol CALCULADO, no el que traía el objeto original
      );
      await _dbHelper.insertUsuario(usuarioLimpio.toMap());
      return null;
    } catch (e) {
      return 'Ocurrió un error al guardar en la base de datos: $e';
    }
  }

  /// Registro automático para quien entra por primera vez con Google.
  /// Usa la MISMA regla de rol que el registro normal. La contraseña es
  /// aleatoria: la cuenta se usa con Google (o con "Olvidé mi contraseña").
  Future<String?> registrarUsuarioSocial({
    required String nombre,
    String apellidoPaterno = '',
    required String correo,
  }) async {
    final totalAdmins = await _dbHelper.contarAdmins();
    final int roleIdFinal = totalAdmins < 2 ? 1 : 2;

    final azar = Random.secure();
    final passAleatoria = List.generate(
      24,
      (_) => 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'[azar.nextInt(56)],
    ).join();

    try {
      final usuario = Usuario(
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        correo: correo,
        pass: passAleatoria,
        roleId: roleIdFinal,
      );
      await _dbHelper.insertUsuario(usuario.toMap());
      return null;
    } catch (e) {
      return 'Ocurrió un error al guardar en la base de datos: $e';
    }
  }
}

//otefrajav@gmail.com
