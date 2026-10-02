import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailService {
  // TODO: Reemplazar con tus credenciales de EmailJS
  // Regístrate gratis en https://www.emailjs.com/
  static const String _serviceId = 'service_j0l0fuj';
  static const String _templateIdComplaint = 'template_0og34u4';
  static const String _templateIdBusiness = 'template_i15v02c';
  static const String _userId = 'OvvmscnBHpnqgC7DV'; // Public Key
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  Future<bool> sendComplaint({
    required String name,
    required String docType,
    required String docNumber,
    required String email,
    required String phone,
    required String type,
    required String detail,
  }) async {
    final params = {
      'to_name': 'Admin',
      'from_name': name,
      'doc_type': docType,
      'doc_number': docNumber,
      'reply_to': email,
      'phone': phone,
      'complaint_type': type,
      'message': detail,
    };

    return _sendEmail(_templateIdComplaint, params);
  }

  Future<bool> sendBusinessRegistration({
    required String businessName,
    required String contactName,
    required String phone,
    required String city,
  }) async {
    final params = {
      'to_name': 'Admin',
      'business_name': businessName,
      'contact_name': contactName,
      'phone': phone,
      'city': city,
      'message': 'Nueva solicitud de registro de negocio.',
    };

    return _sendEmail(_templateIdBusiness, params);
  }

  Future<bool> _sendEmail(
    String templateId,
    Map<String, dynamic> templateParams,
  ) async {
    try {
      final url = Uri.parse(_apiUrl);
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': templateId,
          'user_id': _userId,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Error enviando email: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción enviando email: $e');
      return false;
    }
  }
}
