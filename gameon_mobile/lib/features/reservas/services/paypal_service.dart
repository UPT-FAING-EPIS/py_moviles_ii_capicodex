// services/paypal_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PayPalService {
  final SupabaseClient supabase;

  PayPalService(this.supabase);

  Future<Map<String, dynamic>> createOrder({
    required int areaId,
    required String fecha,
    required String inicio,
    required String fin,
  }) async {
    final response = await supabase.functions.invoke('paypal-payment', body: {
      'action': 'create', 'areaId': areaId, 'fecha': fecha,
      'inicio': inicio, 'fin': fin,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw Exception(data['error']);
    return data;
  }

  Future<Map<String, dynamic>> capturePayment(String orderId) async {
    try {
      final response = await supabase.functions.invoke(
        'paypal-payment', body: {'action': 'capture', 'orderId': orderId},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['error'] != null) throw Exception(data['error']);
      return data;
    } catch (e) {
      throw Exception('Error capturando pago: $e');
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    final response = await supabase.functions.invoke('paypal-payment',
      body: {'action': 'cancel', 'orderId': orderId});
    return (response.data as Map?)?['cancelled'] == true;
  }

  Future<Map<String, dynamic>> recoverReservation(int reservationId) async {
    final response = await supabase.functions.invoke('paypal-payment',
      body: {'action': 'recover', 'reservationId': reservationId});
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw Exception(data['error']);
    return data;
  }

}
