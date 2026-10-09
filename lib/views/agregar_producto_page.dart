import 'package:flutter/material.dart';
import '../controllers/product_controller.dart';

class AgregarProductoPage extends StatefulWidget {
  const AgregarProductoPage({super.key});

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final ProductController _controller = ProductController();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();

  bool _guardando = false;

  void _agregarProducto() async {
    final nombre = _nombreController.text.trim();
    final precioText = _precioController.text.trim();
    final cantidadText = _cantidadController.text.trim();
    final imagen = _imagenController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError('El nombre del producto es obligatorio');
      return;
    }

    if (precioText.isEmpty) {
      _mostrarError('El precio es obligatorio');
      return;
    }

    if (cantidadText.isEmpty) {
      _mostrarError('La cantidad es obligatoria');
      return;
    }

    final precio = double.tryParse(precioText);
    final cantidad = int.tryParse(cantidadText);

    if (precio == null || precio <= 0) {
      _mostrarError('El precio debe ser un número mayor a 0');
      return;
    }

    if (cantidad == null || cantidad <= 0) {
      _mostrarError('La cantidad debe ser un número entero mayor a 0');
      return;
    }

    setState(() => _guardando = true);

    final error = await _controller.agregarProducto(
      nombre: nombre,
      precio: precio,
      cantidad: cantidad,
      imagen: imagen.isNotEmpty ? imagen : null,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      _mostrarError(error);
      return;
    }

    _nombreController.clear();
    _precioController.clear();
    _cantidadController.clear();
    _imagenController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Producto agregado correctamente!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true); // Vuelve y señala que se agregó un producto
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    _imagenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto *',
                border: OutlineInputBorder(),
                hintText: 'Ej: Laptop',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio (MXN) *',
                border: OutlineInputBorder(),
                hintText: 'Ej: 1500.50',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad en Stock *',
                border: OutlineInputBorder(),
                hintText: 'Ej: 10',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _imagenController,
              decoration: const InputDecoration(
                labelText: 'URL de la imagen (Opcional)',
                border: OutlineInputBorder(),
                hintText: 'https://ejemplo.com/imagen.jpg',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _guardando ? null : _agregarProducto,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _guardando
                  ? const CircularProgressIndicator()
                  : const Text('Agregar Producto', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            Text(
              'Los campos marcados con * son obligatorios',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
