import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalWebView extends StatefulWidget {
  final String paypalUrl;
  final String productName;
  final double amount;
  final Function(String orderId, String payerId)? onPaymentApproved;

  const PayPalWebView({
    super.key,
    required this.paypalUrl,
    required this.productName,
    required this.amount,
    this.onPaymentApproved,
  });

  @override
  State<PayPalWebView> createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  DateTime? _firstThanksDetection;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.193 Mobile Safari/537.36',
      )
      ..addJavaScriptChannel(
        'PayPalHandler',
        onMessageReceived: (message) {
          final msg = message.message;
          print('Mensaje JS recibido: $msg');
          if (msg == 'PAYPAL_THANKS') {
            if (_firstThanksDetection == null) {
              _firstThanksDetection = DateTime.now();
            }
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                print('Closing WebView after PayPal final screen.');
                Navigator.pop(context, true);
              }
            });
          }
        },
      )
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress >= 95 && _isLoading) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            print('Página iniciando: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            print('Página terminada: $url');

            _injectCompatibilityScript();
            _checkForPaymentCompletion(url);
            _injectThanksDetector();
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navegando a: ${request.url}');

            // 🔥 INTERCEPTAR LA REDIRECCIÓN DE PAYPAL
            if (_isPaymentReturnUrl(request.url)) {
              print('🔗 URL de retorno de PayPal detectada: ${request.url}');

              // Extraer orderId y payerId de la URL
              final uri = Uri.parse(request.url);
              final token = uri.queryParameters['token'];
              final payerId = uri.queryParameters['PayerID'];

              print('📝 Token: $token, PayerID: $payerId');

              if (token != null && payerId != null && !_paymentCompleted) {
                _paymentCompleted = true;

                // Notificar que el pago fue aprobado
                if (widget.onPaymentApproved != null) {
                  widget.onPaymentApproved!(token, payerId);
                }

                // Cerrar el WebView y retornar éxito
                Future.delayed(Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                });

                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('Error en WebView: ${error.description}');
            if (error.description.toLowerCase().contains('cors') ||
                error.description.toLowerCase().contains('xmlhttprequest') ||
                error.description.toLowerCase().contains('access-control')) {
              print(
                'Error de CORS detectado (normal en PayPal): ${error.description}',
              );
            } else {
              print('Error de WebView: ${error.description}');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paypalUrl));
  }

  // Detectar URLs de retorno de PayPal
  bool _isPaymentReturnUrl(String url) {
    return url.contains('https://www.paypal.com/checkoutnow/approved') ||
        url.contains('https://www.paypal.com/checkoutnow/error') ||
        url.contains('success') && url.contains('token') ||
        url.contains('return') && url.contains('token');
  }

  // Inyectar JavaScript básico para logging
  void _injectCompatibilityScript() {
    const compatibilityScript = '''
      (function() {
        console.log('PayPal WebView Script loaded');
        
        window.addEventListener('error', function(e) {
          console.log('JavaScript error:', e.message);
        });
        
        console.log('PayPal WebView Script initialized');
      })();
    ''';

    _controller.runJavaScript(compatibilityScript).catchError((error) {
      print('Error inyectando script: $error');
    });
  }

  // Detectar pantalla final de agradecimiento de PayPal
  void _injectThanksDetector() {
    const detectScript = '''(function(){
      if (window.__paypal_thanks_detector_installed) return; 
      window.__paypal_thanks_detector_installed = true;
      function check(){
        try {
          const txt = document.body.innerText.toLowerCase();
          if (txt.includes('thanks for using paypal') || 
              txt.includes('gracias por usar paypal') ||
              txt.includes('pago completado') ||
              txt.includes('payment complete')) {
            PayPalHandler.postMessage('PAYPAL_THANKS');
          }
        } catch(e) { /* ignore */ }
      }
      setInterval(check, 1200);
      check();
    })();''';
    _controller.runJavaScript(detectScript).catchError((e) {
      print('Error inyectando detector de thanks: $e');
    });
  }

  void _checkForPaymentCompletion(String url) {
    print('Revisando URL para completación de pago: $url');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Header moderno con gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF0070BA), const Color(0xFF003087)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0070BA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // AppBar personalizado
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () {
                              print('Usuario cerró el WebView de PayPal');
                              Navigator.pop(context, null);
                            },
                            tooltip: 'Cerrar',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Pago con PayPal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_user,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Conexión segura',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    print(
                                      'Usuario recargó la página de PayPal',
                                    );
                                    _controller.reload();
                                  },
                            tooltip: 'Recargar',
                          ),
                        ],
                      ),
                    ),

                    // Información del producto
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.sports_soccer,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.productName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total a pagar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[400]!,
                                  Colors.green[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'S/. ${widget.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // WebView con sombra superior
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRect(child: WebViewWidget(controller: _controller)),
              ),
            ),

            // Barra inferior moderna
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pago seguro con encriptación',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (_currentUrl.isNotEmpty)
                            Text(
                              Uri.parse(_currentUrl).host,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Badge de PayPal
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0070BA),
                            const Color(0xFF003087),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PayPal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
