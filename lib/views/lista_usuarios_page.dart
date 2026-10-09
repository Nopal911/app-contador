import 'package:flutter/material.dart';
import '../controllers/usuario_controller.dart';
import '../models/usuario.dart';
import 'registro_page.dart';

class ListaUsuariosPage extends StatefulWidget {
  const ListaUsuariosPage({super.key});

  @override
  State<ListaUsuariosPage> createState() => _ListaUsuariosPageState();
}

class _ListaUsuariosPageState extends State<ListaUsuariosPage> {
  final UsuarioController _controller = UsuarioController();
  late Future<List<Usuario>> _usuariosFuture;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() {
    setState(() {
      _usuariosFuture = _controller.listarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios registrados')),
      body: FutureBuilder<List<Usuario>>(
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
                DataColumn(label: Text('Correo')),
                DataColumn(label: Text('Rol')),
              ],
              rows: usuarios.map((u) {
                return DataRow(cells: [
                  DataCell(Text('${u.id}')),
                  DataCell(Text(u.nombre)),
                  DataCell(Text(u.correo)),
                  DataCell(Text(u.rolNombre ?? '')),
                ]);
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Registrar nuevo usuario'),
        onPressed: () async {
          // Navega al formulario y espera a que regrese
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegistroPage()),
          );
          // Al volver, recarga la lista (equivalente a redirigir a /usuarios)
          _cargarUsuarios();
        },
      ),
    );
  }
}