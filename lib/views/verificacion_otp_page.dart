import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../services/geolocalizacion_service.dart';

/// Segundo paso del login: el usuario ya validó su contraseña y ahora
/// debe ingresar el código que recibió por correo.
/// [destino] es la pantalla a la que entra si el código es correcto
/// (según su rol: panel de administrador o tienda).
class VerificacionOtpPage extends StatefulWidget {
  final String correo;
  final WidgetBuilder destino;

  const VerificacionOtpPage({
    super.key,
    required this.correo,
    required this.destino,
  });

  @override
  State<VerificacionOtpPage> createState() => _VerificacionOtpPageState();
}

class _VerificacionOtpPageState extends State<VerificacionOtpPage> {
  final TextEditingController _codigoController = TextEditingController();
  bool _verificando = false;
  bool _reenviando = false;

  /// ab***@gmail.com — no mostramos el correo completo.
  String get _correoOculto {
    final partes = widget.correo.split('@');
    if (partes.length != 2 || partes[0].isEmpty) return widget.correo;
    final usuario = partes[0];
    final visible = usuario.length >= 2 ? usuario.substring(0, 2) : usuario;
    return '$visible***@${partes[1]}';
  }

  void _mensaje(String texto, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  Future<void> _verificar() async {
    if (_verificando) return;
    setState(() => _verificando = true);

    final resultado =
        OtpService.verificar(widget.correo, _codigoController.text);

    if (resultado.ok) {
      // Código correcto: antes de entrar, ofrecemos compartir la ubicación
      debugPrint('[OTP] código correcto, pidiendo ubicación');
      try {
        await _compartirUbicacion();
      } catch (_) {
        // Pase lo que pase con la ubicación, el usuario debe poder entrar
      }
      if (!mounted) return;
      debugPrint('[OTP] navegando al destino');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: widget.destino),
        (route) => false,
      );
      return;
    }

    setState(() => _verificando = false);
    _mensaje(resultado.mensaje!, color: Colors.red);
    _codigoController.clear();

    if (resultado.reiniciar) {
      Navigator.pop(context); // Regresa al login
    }
  }

  /// Pide consentimiento y guarda la ubicación actual (una sola vez, sin rastreo).
  Future<void> _compartirUbicacion() async {
    final aceptar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Compartir ubicación'),
        content: const Text(
          'Guardaremos tu ubicación actual en tu perfil para que el '
          'administrador pueda verla. Se toma solo ahora, una vez; '
          'no se rastrea en segundo plano.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
    if (aceptar != true || !mounted) return;

    String? error;
    try {
      error = await GeolocalizacionService.guardarUbicacionUsuario(
              widget.correo)
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      error = 'No se pudo obtener la ubicación a tiempo';
    }
    if (!mounted) return;
    if (error != null) _mensaje(error, color: Colors.orange);
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    final error = await OtpService.reenviarCodigo(widget.correo);
    if (!mounted) return;
    setState(() => _reenviando = false);

    if (error != null) {
      _mensaje(error, color: Colors.red);
    } else {
      _mensaje('Te enviamos un nuevo código');
    }
  }

  @override
  void dispose() {
    // Si sale de esta pantalla sin verificar, el código queda invalidado
    OtpService.cancelar(widget.correo);
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación en dos pasos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.verified_user, size: 72),
            const SizedBox(height: 20),
            Text(
              'Enviamos un código de 6 dígitos a\n$_correoOculto\n'
              'Vence en 5 minutos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verificando ? null : _verificar(),
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _verificando ? null : _verificar,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _verificando
                  ? const CircularProgressIndicator()
                  : const Text('Verificar', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _reenviando ? null : _reenviar,
              child: const Text('Reenviar código'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar y volver al inicio de sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
