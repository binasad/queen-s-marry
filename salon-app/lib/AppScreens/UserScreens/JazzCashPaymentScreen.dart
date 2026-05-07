import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JazzCashPaymentScreen extends StatefulWidget {
  final String checkoutHtml;
  final String returnUrlBase;

  const JazzCashPaymentScreen({
    super.key,
    required this.checkoutHtml,
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            if (url.contains('/payment-success') ||
                url.contains('pp_ResponseCode=000') ||
                url.contains('pp_ResponseCode=121')) {
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
        ),
      )
      ..loadHtmlString(widget.checkoutHtml);
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
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF0068)),
            ),
        ],
      ),
    );
  }
}
