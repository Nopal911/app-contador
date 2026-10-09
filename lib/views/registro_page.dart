import 'package:flutter/material.dart';
import '../controllers/usuario_controller.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final UsuarioController _controller = UsuarioController();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apPaternoController = TextEditingController();
  final TextEditingController _apMaternoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _guardando = false;
  bool _verPass = false;

  void _registrarUsuario() async {
    setState(() => _guardando = true);

    // Ya no mandamos roleId: el servicio decide el rol automáticamente
    final error = await _controller.registrar(
      nombre: _nombreController.text,
      apellidoPaterno: _apPaternoController.text,
      apellidoMaterno: _apMaternoController.text,
      correo: _correoController.text,
      pass: _passController.text,
      confirmarPass: _confirmPassController.text,
      desc: _descController.text,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _nombreController.clear();
    _apPaternoController.clear();
    _apMaternoController.clear();
    _correoController.clear();
    _passController.clear();
    _confirmPassController.clear();
    _descController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Usuario registrado correctamente!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apPaternoController.dispose();
    _apMaternoController.dispose();
    _correoController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _apPaternoController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Apellido paterno *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _apMaternoController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Apellido materno (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: !_verPass,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Contraseña * (mín. 6 caracteres)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip:
                      _verPass ? 'Ocultar contraseñas' : 'Mostrar contraseñas',
                  icon: Icon(
                      _verPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verPass = !_verPass),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPassController,
              obscureText: !_verPass,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Descripción (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _guardando ? null : _registrarUsuario,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _guardando
                  ? const CircularProgressIndicator()
                  : const Text('Registrar', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
