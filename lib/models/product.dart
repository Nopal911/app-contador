class Producto {
  final int? id;
  final String nombreProduct;
  final double precio;
  final int cantidad;
  final String? imagen;

  Producto({
    this.id,
    required this.nombreProduct,
    required this.precio,
    required this.cantidad,
    this.imagen,
  });

  // Convertir un Producto a Map para insertarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_product': nombreProduct,
      'precio': precio,
      'cantidad': cantidad,
      'imagen': imagen,
    };
  }

  // Crear un Producto a partir de los datos de SQLite o la API
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] != null ? map['id'] as int : null,
      nombreProduct: (map['nombre_product'] ?? map['title'] ?? '') as String,
      precio: (map['precio'] ?? map['price'] ?? 0.0).toDouble(),
      cantidad: (map['cantidad'] ?? 1) as int,
      imagen: (map['imagen'] ?? map['image']) as String?,
    );
  }
}