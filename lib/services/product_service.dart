import '../database/database_helper.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Obtener todos los productos
  Future<List<Producto>> obtenerProductos() async {
    final maps = await _dbHelper.getProducts();
    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  // Agregar un nuevo producto
  Future<String?> agregarProducto({
    required String nombre,
    required double precio,
    required int cantidad,
    String? imagen,
  }) async {
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) return 'El nombre del producto es obligatorio';
    if (precio <= 0) return 'El precio debe ser mayor a 0';
    if (cantidad <= 0) return 'La cantidad debe ser mayor a 0';

    try {
      final producto = Producto(
        nombreProduct: nombreLimpio,
        precio: precio,
        cantidad: cantidad,
        imagen: imagen?.isNotEmpty == true ? imagen : null,
      );
      
      await _dbHelper.insertProduct(producto.toMap());
      return null; // Sin error
    } catch (e) {
      return 'Error al guardar el producto: $e';
    }
  }

  // Actualizar cantidad de un producto
  Future<String?> actualizarCantidad(int productoId, int nuevaCantidad) async {
    if (nuevaCantidad < 0) return 'La cantidad no puede ser negativa';

    try {
      await _dbHelper.updateProductoCantidad(productoId, nuevaCantidad);
      return null;
    } catch (e) {
      return 'Error al actualizar: $e';
    }
  }

  // Eliminar un producto
  Future<String?> eliminarProducto(int productoId) async {
    try {
      await _dbHelper.deleteProducto(productoId);
      return null;
    } catch (e) {
      return 'Error al eliminar: $e';
    }
  }
}
