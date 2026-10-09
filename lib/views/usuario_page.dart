import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_contador/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/compartir_service.dart';
import '../widgets/boton_tema.dart';
import 'carrito_page.dart';

/// Colores de esta pantalla según el tema activo.
/// Oscuro = el estilo original (negro + ámbar). Claro = blanco + ámbar oscuro.
class _Paleta {
  final bool oscuro;
  _Paleta(BuildContext context)
      : oscuro = Theme.of(context).brightness == Brightness.dark;

  Color get barra => oscuro ? Colors.black : Colors.white;
  Color get acento => oscuro ? Colors.amber : Colors.amber.shade900;
  Color get sobreAcento => oscuro ? Colors.black : Colors.white;
  Color get tarjeta => oscuro ? Colors.grey.shade900 : Colors.white;
  Color get texto => oscuro ? Colors.white : Colors.black87;
  Color get textoSec => oscuro ? Colors.grey.shade400 : Colors.grey.shade700;
  Color get imagenFondo => oscuro ? Colors.grey.shade800 : Colors.grey.shade200;
}

class ProductosOnlineScreen extends StatefulWidget {
  final Function(List<Map<String, dynamic>>)? updateCart;
  final String correoUsuario;

  const ProductosOnlineScreen({
    super.key,
    this.updateCart,
    required this.correoUsuario,
  });

  @override
  _ProductosOnlineScreenState createState() => _ProductosOnlineScreenState();
}

class _ProductosOnlineScreenState extends State<ProductosOnlineScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cart = [];
  double _total = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartFromPreferences();
    _loadProductosFromDatabase();
  }

  // Cargar productos de la BASE DE DATOS
  Future<void> _loadProductosFromDatabase() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await DatabaseHelper.instance.getProducts();

      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(products);
          _isLoading = false;
        });
      }

      if (_products.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay productos disponibles'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCartFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedCart = prefs.getString('user_cart');
    if (savedCart != null && mounted) {
      setState(() {
        _cart = List<Map<String, dynamic>>.from(
          json.decode(savedCart) as List<dynamic>,
        );
      });
      _calculateTotal();
      widget.updateCart?.call(_cart);
    }
  }

  Future<void> _saveCartToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_cart', json.encode(_cart));
  }

  // Cerrar sesión limpiando el carrito guardado (el tema se conserva)
  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cart');

    if (mounted) {
      // Redirige al login eliminando todo el historial de vistas
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _calculateTotal() {
    if (mounted) {
      setState(() {
        _total = _cart.fold(0.0, (sum, item) {
          double price = double.tryParse(item['precio'].toString()) ?? 0.0;
          int quantity = item['cantidad'] ?? 1;
          return sum + (price * quantity);
        });
      });
    }
  }

  void _addToCart(Map<String, dynamic> product, int quantity) {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa una cantidad válida')),
      );
      return;
    }

    int stockDisponible = product['cantidad'] ?? 0;
    if (quantity > stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solo hay $stockDisponible en stock'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      final existingIndex =
          _cart.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex != -1) {
        _cart[existingIndex]['cantidad'] += quantity;
      } else {
        _cart.add({
          'id': product['id'],
          'nombre_product': product['nombre_product'],
          'precio': product['precio'],
          'cantidad': quantity,
          'imagen': product['imagen'],
        });
      }
    });

    _saveCartToPreferences();
    _calculateTotal();
    widget.updateCart?.call(_cart);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${product['nombre_product']} agregado al carrito (x$quantity)'),
      ),
    );
  }

  void _irAlCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarritoPage(
          cartItems: _cart,
          correoUsuario: widget.correoUsuario,
          onCartUpdated: (nuevoCarrito) {
            setState(() {
              _cart = nuevoCarrito;
            });
            _calculateTotal();
          },
        ),
      ),
    );
  }

  Future<void> _compartir(Map<String, dynamic> product) async {
    final error = await CompartirService.compartirProducto(
      nombre: '${product['nombre_product']}',
      precio: product['precio'],
      imagenUrl: product['imagen']?.toString(),
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _dialogoCerrarSesion(_Paleta p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.tarjeta,
        title: Text(
          'Cerrar sesión',
          style: TextStyle(color: p.acento, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas salir?',
          style: TextStyle(color: p.texto),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: p.acento)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cerrarSesion();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _dialogoCantidad(Map<String, dynamic> product, _Paleta p) {
    final quantityController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.tarjeta,
        title: Text(
          'Seleccionar Cantidad',
          style: TextStyle(color: p.acento, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Cantidad',
            labelStyle: TextStyle(color: p.acento),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: p.acento, width: 2),
            ),
          ),
          style: TextStyle(color: p.texto),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: p.acento)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.acento,
              foregroundColor: p.sobreAcento,
            ),
            onPressed: () {
              int quantity = int.tryParse(quantityController.text) ?? 1;
              Navigator.pop(ctx);
              _addToCart(product, quantity);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Widget _chipCarrito(_Paleta p) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Center(
        child: GestureDetector(
          onTap: _irAlCarrito,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.tarjeta,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.acento, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart, color: p.acento, size: 18),
                const SizedBox(width: 6),
                Text(
                  '\$${_total.toStringAsFixed(2)} MXN',
                  style: TextStyle(
                    color: p.acento,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.acento,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_cart.length}',
                    style: TextStyle(
                      color: p.sobreAcento,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagenProducto(Map<String, dynamic> product, _Paleta p) {
    final tieneImagen =
        product['imagen'] != null && product['imagen'].toString().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: tieneImagen
          ? Image.network(
              product['imagen'] ?? '',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: p.imagenFondo,
                child: const Icon(Icons.broken_image, color: Colors.red),
              ),
            )
          : Container(
              width: 100,
              height: 100,
              color: p.imagenFondo,
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
    );
  }

  Widget _tarjetaProducto(Map<String, dynamic> product, _Paleta p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: p.tarjeta,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _imagenProducto(product, p),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product['nombre_product'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: p.acento,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Precio: \$${product['precio']} MXN',
                      style: TextStyle(
                        color: p.acento,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${product['cantidad']}',
                      style: TextStyle(color: p.textoSec, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.acento,
                    foregroundColor: p.sobreAcento,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _dialogoCantidad(product, p),
                  child: const Text('Comprar'),
                ),
                const SizedBox(height: 8),
                IconButton(
                  tooltip: 'Compartir producto',
                  icon: Icon(Icons.share, color: p.acento),
                  onPressed: () => _compartir(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Productos',
          style: TextStyle(
            color: p.acento,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: p.barra,
        surfaceTintColor: Colors.transparent,
        actions: [
          BotonTema(color: p.acento),
          IconButton(
            icon: Icon(Icons.logout, color: p.acento),
            tooltip: 'Cerrar sesión',
            onPressed: () => _dialogoCerrarSesion(p),
          ),
          _chipCarrito(p),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No hay productos disponibles',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadProductosFromDatabase,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recargar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProductosFromDatabase,
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) =>
                        _tarjetaProducto(_products[index], p),
                  ),
                ),
    );
  }
}
