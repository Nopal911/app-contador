import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/usuario_controller.dart';
import '../controllers/product_controller.dart';
import '../models/usuario.dart';
import '../models/product.dart';
import 'registro_page.dart';
import 'agregar_producto_page.dart';
import 'ubicacion_usuario_page.dart';
import '../services/tema_service.dart';
import '../widgets/boton_tema.dart';

class CrudPage extends StatefulWidget {
  const CrudPage({super.key});

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> with SingleTickerProviderStateMixin {
  final UsuarioController _usuarioController = UsuarioController();
  final ProductController _productoController = ProductController();
    
  late Future<List<Usuario>> _usuariosFuture; 
  late Future<List<Producto>> _productosFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _usuariosFuture = _usuarioController.listarUsuarios();
      _productosFuture = _productoController.listarProductos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Método para cerrar sesión limpiando preferencias y redirigiendo al Login
  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await TemaService.guardar(); // conserva el tema elegido

    if (mounted) {
      // Elimina todo el historial de navegación y te lleva a la pantalla de Login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _eliminarProducto(int productoId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('Esta acción no se puede deshacer'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final error = await _productoController.eliminarProducto(productoId);
      if (!mounted) return;
      
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        automaticallyImplyLeading: false,
        actions: [
          const BotonTema(),
          // Botón de Cerrar Sesión con confirmación
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Estás seguro de que deseas salir?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Cierra el modal
                          _cerrarSesion(); // Cierra sesión y navega al Login
                        },
                        child: const Text('Salir'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Usuarios', icon: Icon(Icons.people)),
            Tab(text: 'Productos', icon: Icon(Icons.shopping_bag)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: GESTIÓN DE USUARIOS
          FutureBuilder<List<Usuario>>(
            future: _usuariosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aún no hay usuarios registrados'));
              }

              final usuarios = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Apellido paterno')),
                    DataColumn(label: Text('Apellido materno')),
                    DataColumn(label: Text('Correo')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Ubicación')),
                  ],
                  rows: usuarios.map((u) {
                    return DataRow(cells: [
                      DataCell(Text('${u.id}')),
                      DataCell(Text(u.nombre)),
                      DataCell(Text(u.apellidoPaterno)),
                      DataCell(Text(u.apellidoMaterno ?? '')),
                      DataCell(Text(u.correo)),
                      DataCell(Text(u.rolNombre ?? '')),
                      DataCell(u.tieneUbicacion
                          ? IconButton(
                              icon: const Icon(Icons.location_on, color: Colors.red),
                              tooltip: 'Ver ubicación',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => UbicacionUsuarioPage(usuario: u)),
                              ),
                            )
                          : const Text('Sin ubicación')),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),

          // TAB 2: GESTIÓN DE PRODUCTOS
          FutureBuilder<List<Producto>>(
            future: _productosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      const Text('Aún no hay productos registrados'),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AgregarProductoPage(),
                            ),
                          );
                          if (resultado == true) {
                            _cargarDatos();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Producto'),
                      ),
                    ],
                  ),
                );
              }

              final productos = snapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Precio')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: productos.map((p) {
                        return DataRow(cells: [
                          DataCell(Text('${p.id}')),
                          DataCell(Text(p.nombreProduct)),
                          DataCell(Text('\$${p.precio}')),
                          DataCell(Text('${p.cantidad}')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarProducto(p.id ?? 0),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AgregarProductoPage(),
                            ),
                          );
                          if (resultado == true) {
                            _cargarDatos();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Nuevo Producto'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: _tabController.index == 0
            ? const Text('Registrar Usuario')
            : const Text('Agregar Producto'),
        onPressed: () async {
          if (_tabController.index == 0) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegistroPage()),
            );
            _cargarDatos();
          } else {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AgregarProductoPage()),
            );
            if (resultado == true) {
              _cargarDatos();
            }
          }
        },
      ),
    );
  }
}