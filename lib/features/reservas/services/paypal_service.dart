// services/paypal_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PayPalService {
  final SupabaseClient supabase;

  PayPalService(this.supabase);

  Future<Map<String, dynamic>> createOrder(
    double amount, {
    String currency = 'USD',
  }) async {
    try {
      final formattedAmount = amount.toStringAsFixed(2);

      final response = await supabase.functions.invoke(
        'paypal-payment',
        body: {'amount': formattedAmount, 'currency': currency},
      );

      return response.data;
    } catch (e) {
      throw Exception('Error creando orden: $e');
    }
  }

  Future<Map<String, dynamic>> capturePayment(String orderId) async {
    try {
      final response = await supabase.functions.invoke(
        'paypal-payment/capture',
        body: {'orderId': orderId},
      );

      return response.data;
    } catch (e) {
      throw Exception('Error capturando pago: $e');
    }
  }

  // Método para verificar el estado de una orden
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      // Esta función necesitarías crearla en tu Edge Function
      final response = await supabase.functions.invoke(
        'paypal-payment/order-details',
        body: {'orderId': orderId},
      );

      return response.data;
    } catch (e) {
      throw Exception('Error obteniendo detalles: $e');
    }
  }
}
