class Rol {
  final int id;
  final String nombre;

  Rol({required this.id, required this.nombre});

  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      id: map['id'] as int,
      nombre: map['rol'] as String,
    );
  }
}