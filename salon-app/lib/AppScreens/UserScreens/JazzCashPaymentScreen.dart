import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JazzCashPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final Map<String, String> formData;
  final String returnUrlBase;

  const JazzCashPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.formData,
    required this.returnUrlBase,
  });

  @override
  State<JazzCashPaymentScreen> createState() => _JazzCashPaymentScreenState();
}

class _JazzCashPaymentScreenState extends State<JazzCashPaymentScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() => _isLoading = true);
          if (url.contains('/payment-success') || url.contains('pp_ResponseCode=000') || url.contains('pp_ResponseCode=121')) {
            Navigator.pop(context, 'success');
          } else if (url.contains('/payment-failed')) {
            Navigator.pop(context, 'failed');
          }
        },
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (request) {
          if (request.url.contains(widget.returnUrlBase)) {
            if (request.url.contains('payment-success')) {
              Navigator.pop(context, 'success');
              return NavigationDecision.prevent;
            } else if (request.url.contains('payment-failed')) {
              Navigator.pop(context, 'failed');
              return NavigationDecision.prevent;
            }
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(_buildAutoSubmitForm());
  }

  String _buildAutoSubmitForm() {
    final fields = widget.formData.entries
        .map((e) => '<input type="hidden" name="${e.key}" value="${e.value}" />')
        .join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; font-family: sans-serif; background: #f8f9fa; }
    .loader { text-align: center; }
    .spinner { width: 40px; height: 40px; border: 4px solid #e0e0e0; border-top: 4px solid #FF0068; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 16px; }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="loader">
    <div class="spinner"></div>
    <p>Redirecting to JazzCash...</p>
  </div>
  <form id="jazzcash_form" method="POST" action="${widget.paymentUrl}">
    $fields
  </form>
  <script>document.getElementById('jazzcash_form').submit();</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JazzCash Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, 'cancelled'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFFF0068))),
        ],
      ),
    );
  }
}
