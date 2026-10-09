import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/email_service.dart';
import '../services/paypal_service.dart'; // ⬅️ NUEVO
import 'paypal_checkout_page.dart'; // ⬅️ NUEVO

class CarritoPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdated;
  final String correoUsuario;

  const CarritoPage({
    super.key,
    required this.cartItems,
    required this.onCartUpdated,
    required this.correoUsuario,
  });

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  late List<Map<String, dynamic>> _cart;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _cart = List<Map<String, dynamic>>.from(widget.cartItems);
    _calcularTotal();
  }

  void _calcularTotal() {
    setState(() {
      _total = _cart.fold(0.0, (sum, item) {
        double price = double.tryParse(item['precio'].toString()) ?? 0.0;
        int quantity = item['cantidad'] ?? 1;
        return sum + (price * quantity);
      });
    });
  }

  void _modificarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarDelCarrito(index);
      return;
    }

    setState(() {
      _cart[index]['cantidad'] = nuevaCantidad;
    });
    _calcularTotal();
    _guardarCarrito();
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _cart.removeAt(index);
    });
    _calcularTotal();
    _guardarCarrito();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto eliminado del carrito')),
    );
  }

  Future<void> _guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_cart', jsonEncode(_cart));
    widget.onCartUpdated(_cart);
  }

  // ⬅️ NUEVO: flujo completo de pago con PayPal
  Future<void> _pagarConPaypal() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conectando con PayPal...')),
    );

    // 1) Crear la orden en PayPal
    final orden = await PaypalService.crearOrden(_total);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (orden == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar el pago con PayPal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2) Abrir el WebView para que el usuario apruebe el pago
    final orderId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => PaypalCheckoutPage(approveUrl: orden['approveUrl']!),
      ),
    );
    if (!mounted) return;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago cancelado')),
      );
      return;
    }

    // 3) Capturar el pago
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Confirmando pago...')),
    );
    // Devuelve el ID de la transacción (captura) o null si falló
    final idTransaccion = await PaypalService.capturarOrden(orderId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (idTransaccion != null) {
      _confirmarCompra(idTransaccion); // correo + limpiar carrito + diálogo de éxito
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pago no pudo completarse'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _realizarCompra() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Compra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total a pagar: \$${_total.toStringAsFixed(2)} MXN',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 15),
              // ⬅️ CAMBIO: texto actualizado
              const Text(
                'Serás redirigido a PayPal para completar el pago de forma segura.',
              ),
              const SizedBox(height: 15),
              Text(
                'Artículos: ${_cart.length}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Comprobante a: ${widget.correoUsuario}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _pagarConPaypal(); // ⬅️ CAMBIO: antes llamaba _confirmarCompra()
              },
              child: const Text('Pagar con PayPal'),
            ),
          ],
        );
      },
    );
  }

  // Se ejecuta SOLO después de que PayPal confirmó el pago
  void _confirmarCompra(String idTransaccion) async {
    // 1) Copia de los datos antes de vaciar el carrito
    final itemsComprados =
        _cart.map((e) => Map<String, dynamic>.from(e)).toList();
    final totalPagado = _total;

    // 2) Indicador de envío de correo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enviando comprobante a tu correo...')),
    );

    // 3) Llamada al servicio asíncrono
    final errorCorreo = await EmailService.enviarComprobante(
      destinatario: widget.correoUsuario,
      items: itemsComprados,
      total: totalPagado,
      orderId: idTransaccion, // ID de transacción de PayPal
    );

    // 4) Limpieza del almacenamiento local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cart');

    if (!mounted) return;

    setState(() {
      _cart.clear();
      _total = 0.0;
    });
    widget.onCartUpdated([]);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 5) Diálogo con el estado de la transacción
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¡Compra Exitosa!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Total pagado: \$${totalPagado.toStringAsFixed(2)} MXN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID de transacción PayPal:\n$idTransaccion',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 15),
              Text(
                errorCorreo == null
                    ? 'Te enviamos el comprobante a:\n${widget.correoUsuario}'
                    : 'Tu pedido fue registrado, pero no pudimos enviar el correo.\n$errorCorreo',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Cierra el diálogo de éxito
                Navigator.pop(context); // Regresa a la pantalla principal
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _vaciarCarrito() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Vaciar carrito?'),
          content: const Text(
              '¿Estás seguro de que quieres eliminar todos los productos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() => _cart.clear());
                _calcularTotal();
                _guardarCarrito();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carrito vacío')),
                );
              },
              child: const Text('Vaciar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.black,
      ),
      body: _cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tu carrito está vacío',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continuar comprando'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        _cart.length,
                        (index) {
                          final item = _cart[index];
                          final precioItem =
                              double.tryParse(item['precio'].toString()) ?? 0.0;
                          final cantidadItem = (item['cantidad'] ?? 1) as int;

                          return Card(
                            margin: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Imagen
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item['imagen'] != null &&
                                            item['imagen']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                            item['imagen'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.red,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[800],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Detalles del producto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['nombre_product'] ?? 'Producto',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Precio: \$${item['precio']} MXN',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                _modificarCantidad(
                                                  index,
                                                  cantidadItem - 1,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '$cantidadItem',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            IconButton(
                                              onPressed: () {
                                                _modificarCantidad(
                                                  index,
                                                  cantidadItem + 1,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.add_circle,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Total individual (Precio x Cantidad)
                                  Column(
                                    children: [
                                      Text(
                                        '\$${(precioItem * cantidadItem).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IconButton(
                                        onPressed: () =>
                                            _eliminarDelCarrito(index),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Footer con totales y acciones
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border(
                      top: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '\$${_total.toStringAsFixed(2)} MXN',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _vaciarCarrito,
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Vaciar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _realizarCompra,
                              icon: const Icon(Icons.payment),
                              label: const Text('Comprar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
