// Esta clase es el MODELO. Solo guarda datos, no hace nada más.
// No sabe de bases de datos, no sabe de pantallas. Es una "cajita" de información.
class Usuario {
  final int? id;                // int? = puede ser null (un usuario nuevo aún no tiene id, lo da SQLite)
  final String nombre;          // Sin ? = obligatorio, nunca null
  final String apellidoPaterno; // Obligatorio al registrar ('' en usuarios anteriores a esta versión)
  final String? apellidoMaterno; // Opcional (hay personas sin segundo apellido)
  final String correo;
  final String pass;
  final String? desc;           // Opcional
  final int roleId;             // Número del rol: 1 = Administrador, 2 = Usuario
  final String? rolNombre;      // Texto del rol, solo para MOSTRAR en la tabla (no se guarda en user_app)

  // Última ubicación compartida (null si el usuario nunca la compartió)
  final double? latitud;
  final double? longitud;
  final String? direccion;
  final String? ubicacionFecha;

  // Constructor con parámetros nombrados (las llaves { })
  Usuario({
    this.id,                    // Opcional al crear el objeto
    required this.nombre,       // Obligatorio, si no lo pasas, Dart no compila
    this.apellidoPaterno = '',  // Con valor por defecto para no romper código existente
    this.apellidoMaterno,
    required this.correo,
    required this.pass,
    this.desc,
    required this.roleId,
    this.rolNombre,
    this.latitud,
    this.longitud,
    this.direccion,
    this.ubicacionFecha,
  });

  bool get tieneUbicacion => latitud != null && longitud != null;

  /// Nombre + apellidos, omitiendo los que estén vacíos.
  String get nombreCompleto => [nombre, apellidoPaterno, apellidoMaterno ?? '']
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  // Convierte el objeto Usuario en un Map, porque sqflite solo entiende Maps al insertar
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,   // Las claves deben ser IDÉNTICAS a las columnas de la tabla
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'correo': correo,
      'pass': pass,
      'desc': desc,
      'role_id': roleId,  // En Dart es roleId, en SQL es role_id (con guion bajo)
      // NO mandamos 'id': SQLite lo asigna solo con AUTOINCREMENT
    };
  }

  // Hace lo contrario: toma una fila de SQLite (Map) y arma un objeto Usuario de Dart
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int?,             // Busca la clave 'id' y la castea (convierte) a int?
      nombre: map['nombre'] as String,
      apellidoPaterno: (map['apellido_paterno'] as String?) ?? '',
      apellidoMaterno: map['apellido_materno'] as String?,
      correo: map['correo'] as String,
      pass: map['pass'] as String,
      desc: map['desc'] as String?,
      roleId: map['role_id'] as int,
      // rol_nombre NO existe en la tabla user_app; viene de un JOIN con rol_permiso
      rolNombre: map['rol_nombre'] as String?,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      direccion: map['direccion'] as String?,
      ubicacionFecha: map['ubicacion_fecha'] as String?,
    );
  }
}
