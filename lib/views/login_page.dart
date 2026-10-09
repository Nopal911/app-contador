import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/otp_service.dart';
import 'crud_page.dart';
import 'usuario_page.dart';
import 'registro_page.dart'; // Necesario para poder navegar al formulario de registro
import 'olvide_password_page.dart';
import 'verificacion_otp_page.dart';
import '../services/google_auth_service.dart';
import '../widgets/boton_tema.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _verificando = false;
  bool _googleCargando = false;

  void _mensaje(String texto, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  void _iniciarSesion() async {
    final correo = _correoController.text.trim();
    final pass = _passController.text.trim();

    if (correo.isEmpty || pass.isEmpty) {
      _mensaje('Ingresa correo y contraseña');
      return;
    }

    setState(() => _verificando = true);

    // PASO 1: usuario y contraseña
    final esAdmin = await DatabaseHelper.instance.esAdmin(correo, pass);
    final esUsuario =
        esAdmin ? false : await DatabaseHelper.instance.esUsuario(correo, pass);

    if (!mounted) return;

    if (!esAdmin && !esUsuario) {
      setState(() => _verificando = false);
      _mensaje('Correo o contraseña incorrectos', color: Colors.red);
      return;
    }

    // PASO 2: enviamos el código (OTP) al correo del usuario
    final error = await OtpService.enviarCodigo(correo);

    if (!mounted) return;
    setState(() => _verificando = false);

    if (error != null) {
      _mensaje(error, color: Colors.red);
      return;
    }

    // A dónde entra SOLO si el código es correcto, según su rol
    WidgetBuilder destino;
    if (esAdmin) {
      destino = (_) => const CrudPage();
    } else {
      destino = (_) => ProductosOnlineScreen(correoUsuario: correo);
    }

    _passController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificacionOtpPage(correo: correo, destino: destino),
      ),
    );
  }

  Future<void> _iniciarConGoogle() async {
    setState(() => _googleCargando = true);
    final r = await GoogleAuthService.iniciarSesion();
    if (!mounted) return;
    setState(() => _googleCargando = false);

    if (r.cancelado) return;
    if (r.error != null) {
      _mensaje(r.error!, color: Colors.red);
      return;
    }

    final correo = r.correo!;
    final esAdmin = r.esAdmin;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => esAdmin
            ? const CrudPage()
            : ProductosOnlineScreen(correoUsuario: correo),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        actions: const [BotonTema()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OlvidePasswordPage()),
                  );
                },
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _verificando ? null : _iniciarSesion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _verificando
                  ? const CircularProgressIndicator()
                  : const Text('Ingresar', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('o'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed:
                  (_verificando || _googleCargando) ? null : _iniciarConGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: _googleCargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.account_circle),
              label: const Text('Continuar con Google',
                  style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistroPage()),
                );
              },
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
