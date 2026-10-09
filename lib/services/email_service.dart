import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  // ⚠️ Correo desde el que SE ENVÍAN los comprobantes (el de tu tienda)
  static const String _remitente = 'xbox95392@gmail.com';

  // ⚠️ NO es tu contraseña normal: es una "Contraseña de aplicación" de Google
  // (Cuenta Google > Seguridad > Verificación en 2 pasos > Contraseñas de aplicaciones)
  static const String _appPassword = 'dnpq kjou ezat owyz';

  /// Devuelve null si todo salió bien, o un texto con el error.
  static Future<String?> enviarComprobante({
    required String destinatario,
    required List<Map<String, dynamic>> items,
    required double total,
    String? orderId, // ⬅️ NUEVO (opcional)
  }) async {
    final smtpServer = gmail(_remitente, _appPassword);

    final folio = DateTime.now().millisecondsSinceEpoch.toString();
    final fecha = DateTime.now();
    final fechaTexto =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    // Filas de la tabla HTML
    final filas = items.map((item) {
      final nombre = item['nombre_product'] ?? 'Producto';
      final precio = double.tryParse(item['precio'].toString()) ?? 0.0;
      final cantidad = (item['cantidad'] ?? 1) as int;
      final subtotal = precio * cantidad;
      return '''
        <tr>
          <td style="padding:8px;border-bottom:1px solid #ddd;">$nombre</td>
          <td style="padding:8px;border-bottom:1px solid #ddd;text-align:center;">$cantidad</td>
          <td style="padding:8px;border-bottom:1px solid #ddd;text-align:right;">\$${precio.toStringAsFixed(2)}</td>
          <td style="padding:8px;border-bottom:1px solid #ddd;text-align:right;">\$${subtotal.toStringAsFixed(2)}</td>
        </tr>''';
    }).join();

    // ⬅️ NUEVO: línea con el ID de PayPal (solo si existe)
    final lineaPaypal = orderId != null
        ? '<br><b>ID de transacción PayPal:</b> $orderId'
        : '';

    final html =
        '''
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;">
        <h2 style="color:#2e7d32;">¡Gracias por tu compra!</h2>
        <p><b>Comprobante No.:</b> $folio<br>
           <b>Fecha:</b> $fechaTexto<br>
           <b>Cliente:</b> $destinatario$lineaPaypal</p>
        <table style="width:100%;border-collapse:collapse;">
          <tr style="background:#f5f5f5;">
            <th style="padding:8px;text-align:left;">Producto</th>
            <th style="padding:8px;">Cant.</th>
            <th style="padding:8px;text-align:right;">Precio</th>
            <th style="padding:8px;text-align:right;">Subtotal</th>
          </tr>
          $filas
        </table>
        <h3 style="text-align:right;">Total: \$${total.toStringAsFixed(2)} MXN</h3>
        <p style="color:#777;font-size:12px;">Este correo es un comprobante de tu pedido.</p>
      </div>''';

    final mensaje = Message()
      ..from = Address(_remitente, 'Mi Tienda')
      ..recipients.add(destinatario)
      ..subject = 'Comprobante de compra #$folio'
      ..html = html;

    try {
      await send(mensaje, smtpServer);
      return null;
    } on MailerException catch (e) {
      return 'No se pudo enviar el comprobante: ${e.message}';
    } catch (e) {
      return 'Error al enviar el correo: $e';
    }
  }

  /// Envía el código de recuperación de contraseña. Devuelve null si salió bien.
  static Future<String?> enviarCodigoRecuperacion({
    required String destinatario,
    required String codigo,
    required int minutos,
  }) async {
    final smtpServer = gmail(_remitente, _appPassword);

    final html = '''
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;">
        <h2 style="color:#5e35b1;">Recuperación de contraseña</h2>
        <p>Recibimos una solicitud para restablecer tu contraseña.
           Usa este código de verificación:</p>
        <p style="font-size:32px;letter-spacing:8px;font-weight:bold;
                  text-align:center;background:#f5f5f5;padding:12px;">$codigo</p>
        <p>El código vence en $minutos minutos y solo puede usarse una vez.</p>
        <p style="color:#777;font-size:12px;">Si no fuiste tú, ignora este correo:
           tu contraseña no cambiará.</p>
      </div>''';

    final mensaje = Message()
      ..from = Address(_remitente, 'Mi Tienda')
      ..recipients.add(destinatario)
      ..subject = 'Tu código de recuperación'
      ..html = html;

    try {
      await send(mensaje, smtpServer);
      return null;
    } on MailerException catch (e) {
      return 'No se pudo enviar el código: ${e.message}';
    } catch (e) {
      return 'Error al enviar el correo: $e';
    }
  }

  /// Envía el código OTP del segundo factor (2FA) al iniciar sesión.
  /// Devuelve null si salió bien.
  static Future<String?> enviarCodigoVerificacion({
    required String destinatario,
    required String codigo,
    required int minutos,
  }) async {
    final smtpServer = gmail(_remitente, _appPassword);

    final html = '''
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;">
        <h2 style="color:#5e35b1;">Verificación en dos pasos</h2>
        <p>Alguien ingresó tu contraseña para iniciar sesión.
           Para completar el acceso usa este código:</p>
        <p style="font-size:32px;letter-spacing:8px;font-weight:bold;
                  text-align:center;background:#f5f5f5;padding:12px;">$codigo</p>
        <p>El código vence en $minutos minutos y solo puede usarse una vez.</p>
        <p style="color:#777;font-size:12px;">Si no fuiste tú, cambia tu contraseña
           y no compartas este código con nadie.</p>
      </div>''';

    final mensaje = Message()
      ..from = Address(_remitente, 'Mi Tienda')
      ..recipients.add(destinatario)
      ..subject = 'Tu código de acceso'
      ..html = html;

    try {
      await send(mensaje, smtpServer);
      return null;
    } on MailerException catch (e) {
      return 'No se pudo enviar el código: ${e.message}';
    } catch (e) {
      return 'Error al enviar el correo: $e';
    }
  }
}
