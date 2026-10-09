import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/paypal_service.dart';

class PaypalCheckoutPage extends StatelessWidget {
  final String approveUrl;
  const PaypalCheckoutPage({super.key, required this.approveUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con PayPal'),
        backgroundColor: Colors.black,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(approveUrl)),
        // IMPORTANTE: sin esto, shouldOverrideUrlLoading no se ejecuta
        initialSettings: InAppWebViewSettings(
          useShouldOverrideUrlLoading: true,
        ),
        shouldOverrideUrlLoading: (controller, action) async {
          final url = action.request.url?.toString() ?? '';

          if (url.startsWith(PaypalService.returnUrl)) {
            // PayPal manda el id de la orden en el parámetro "token"
            final orderId = Uri.parse(url).queryParameters['token'];
            if (context.mounted) Navigator.pop(context, orderId);
            return NavigationActionPolicy.CANCEL;
          }
          if (url.startsWith(PaypalService.cancelUrl)) {
            if (context.mounted) Navigator.pop(context, null);
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
