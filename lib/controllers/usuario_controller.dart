import '../models/usuario.dart';
import '../models/rol.dart';
import '../services/usuario_service.dart';

class UsuarioController {
  final UsuarioService _service = UsuarioService();

  Future<List<Usuario>> listarUsuarios() async {
    return await _service.obtenerUsuarios();
  }

  Future<List<Rol>> listarRoles() async {
    return await _service.obtenerRoles();
  }

  // Ya NO recibe roleId: el servicio decide el rol automáticamente
  Future<String?> registrar({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String correo,
    required String pass,
    required String confirmarPass,
    String? desc,
  }) async {
    final usuario = Usuario(
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      correo: correo,
      pass: pass,
      desc: desc,
      roleId: 0, // Valor temporal/placeholder: el servicio lo va a reemplazar antes de guardar
    );
    return await _service.registrarUsuario(usuario, confirmarPass);
  }
}
