import 'package:flutter/material.dart';
import '../services/recuperacion_service.dart';

class RestablecerPasswordPage extends StatefulWidget {
  final String correo;
  const RestablecerPasswordPage({super.key, required this.correo});

  @override
  State<RestablecerPasswordPage> createState() =>
      _RestablecerPasswordPageState();
}

class _RestablecerPasswordPageState extends State<RestablecerPasswordPage> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _guardando = false;
  bool _reenviando = false;
  bool _verPass = false;

  void _mensaje(String texto, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  Future<void> _restablecer() async {
    if (_passController.text.trim() != _confirmController.text.trim()) {
      _mensaje('Las contraseñas no coinciden', color: Colors.red);
      return;
    }

    setState(() => _guardando = true);
    final error = await RecuperacionService.restablecer(
      correo: widget.correo,
      codigo: _codigoController.text,
      nuevaPass: _passController.text,
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      _mensaje(error, color: Colors.red);
      return;
    }

    _mensaje('¡Contraseña actualizada! Ya puedes iniciar sesión',
        color: Colors.green);
    // Regresa a la pantalla de login (la primera de la pila)
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    final error = await RecuperacionService.solicitarCodigo(widget.correo);
    if (!mounted) return;
    setState(() => _reenviando = false);

    if (error != null) {
      _mensaje(error, color: Colors.red);
    } else {
      _mensaje('Si el correo está registrado, te enviamos un nuevo código');
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Enviamos un código de 6 dígitos a:\n${widget.correo}\n'
              'Vence en 10 minutos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: !_verPass,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña (mín. 6 caracteres)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _verPass ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  icon: Icon(
                      _verPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verPass = !_verPass),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmController,
              obscureText: !_verPass,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardando ? null : _restablecer(),
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _guardando ? null : _restablecer,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _guardando
                  ? const CircularProgressIndicator()
                  : const Text('Cambiar contraseña',
                      style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _reenviando ? null : _reenviar,
              child: const Text('Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }
}