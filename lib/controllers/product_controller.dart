import '../models/product.dart';
import '../services/product_service.dart';

class ProductController {
  final ProductService _service = ProductService();

  // Obtener lista de productos
  Future<List<Producto>> listarProductos() async {
    return await _service.obtenerProductos();
  }

  // Agregar un nuevo producto
  Future<String?> agregarProducto({
    required String nombre,
    required double precio,
    required int cantidad,
    String? imagen,
  }) async {
    return await _service.agregarProducto(
      nombre: nombre,
      precio: precio,
      cantidad: cantidad,
      imagen: imagen,
    );
  }

  // Actualizar cantidad
  Future<String?> actualizarCantidad(int productoId, int nuevaCantidad) async {
    return await _service.actualizarCantidad(productoId, nuevaCantidad);
  }

  // Eliminar producto
  Future<String?> eliminarProducto(int productoId) async {
    return await _service.eliminarProducto(productoId);
  }
}
