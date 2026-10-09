import 'package:flutter/material.dart';
import '../services/recuperacion_service.dart';
import 'restablecer_password_page.dart';

class OlvidePasswordPage extends StatefulWidget {
  const OlvidePasswordPage({super.key});

  @override
  State<OlvidePasswordPage> createState() => _OlvidePasswordPageState();
}

class _OlvidePasswordPageState extends State<OlvidePasswordPage> {
  final TextEditingController _correoController = TextEditingController();
  bool _enviando = false;

  Future<void> _enviarCodigo() async {  
    setState(() => _enviando = true);
    final error =
        await RecuperacionService.solicitarCodigo(_correoController.text);
    if (!mounted) return;
    setState(() => _enviando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    } 

    // Mensaje neutro: no revela si el correo existe o no
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Si el correo está registrado, te enviamos un código de verificación'),
      ),
    );
    _irARestablecer();
  }
   
  void _irARestablecer() {
    final correo = _correoController.text.trim();
    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo electrónico')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestablecerPasswordPage(correo: correo),
      ),
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.lock_reset, size: 72),
            const SizedBox(height: 20),
            const Text(
              'Ingresa el correo con el que te registraste y te enviaremos '
              'un código de verificación.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _enviando ? null : _enviarCodigo(),
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _enviando ? null : _enviarCodigo,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _enviando
                  ? const CircularProgressIndicator()
                  : const Text('Enviar código', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _irARestablecer,
              child: const Text('Ya tengo un código'),
            ),
          ],
        ),
      ),
    );
  }
}