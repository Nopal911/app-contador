import 'dart:convert';
import 'package:http/http.dart' as http;

class PaypalService {
  // Credenciales SANDBOX de developer.paypal.com > Apps & Credentials
  static const String _clientId = 'AfBe-M354fCqjzPU-UVPtpZnCGW3CaNjiY8Aysb39pFKsALrJBFckaJKii7Gf2EmnEHxmx4obXRjbPEl';
  static const String _secret = 'EC1mAKj4HfT7Vy8fXv6nQZC4iUEvIbW8tKk0ATNGaQI2BV4k3JVcZYK6c73Pu0M6tlInFC1moYP_aoY4';

  static const String _api = 'https://api-m.sandbox.paypal.com';

  // Las inventas; solo deben ser iguales aquí y en la página del WebView
  static const String returnUrl = 'https://example.com/paypal/return';
  static const String cancelUrl = 'https://example.com/paypal/cancel';

  static Future<String?> _getToken() async {
    try {
      final auth = base64Encode(utf8.encode('$_clientId:$_secret'));
      final res = await http.post(
        Uri.parse('$_api/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body)['access_token'];
    } catch (_) {
      return null;
    }
  }

  /// Devuelve {'orderId': ..., 'approveUrl': ...} o null si falla.
  static Future<Map<String, String>?> crearOrden(double total) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.post(
        Uri.parse('$_api/v2/checkout/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'amount': {
                'currency_code': 'MXN',
                'value': total.toStringAsFixed(2),
              },
            }
          ],
          'application_context': {
            'return_url': returnUrl,
            'cancel_url': cancelUrl,
            'user_action': 'PAY_NOW',
          },
        }),
      );
      if (res.statusCode != 200 && res.statusCode != 201) return null;

      final data = jsonDecode(res.body);
      final links = data['links'] as List;
      final approve = links.firstWhere(
        (l) => l['rel'] == 'approve' || l['rel'] == 'payer-action',
        orElse: () => null,
      );
      if (approve == null) return null;

      return {
        'orderId': data['id'].toString(),
        'approveUrl': approve['href'].toString(),
      };
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el ID de la transacción (captura) si PayPal responde COMPLETED,
  /// o null si algo falló.
  static Future<String?> capturarOrden(String orderId) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.post(
        Uri.parse('$_api/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200 && res.statusCode != 201) return null;

      final data = jsonDecode(res.body);
      if (data['status'] != 'COMPLETED') return null;

      // El ID de la transacción está dentro de la primera captura
      final captura = data['purchase_units'][0]['payments']['captures'][0];
      return captura['id'].toString();
    } catch (_) {
      return null;
    }
  }
}
