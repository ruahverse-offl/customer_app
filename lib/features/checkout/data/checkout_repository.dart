import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class CheckoutRepository {
  final Dio _dio;
  const CheckoutRepository(this._dio);

  Future<Map<String, dynamic>> getDeliverySettings() async {
    final res = await _dio.get('/delivery-settings/');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final res = await _dio.get('/coupons/');
    final items = res.data['items'] ?? res.data as List;
    return (items as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal) async {
    final res = await _dio.post('/coupons/validate', data: {'code': code, 'subtotal': subtotal});
    return res.data as Map<String, dynamic>;
  }

  Future<String?> uploadPrescription(String filePath, String fileName) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await _dio.post('/upload', data: form);
    return res.data['url'] as String?;
  }

  Future<Map<String, dynamic>> initiatePayment(Map<String, dynamic> orderPayload) async {
    final res = await _dio.post('/razorpay/initiate', data: orderPayload);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> payload) async {
    final res = await _dio.post('/razorpay/verify', data: payload);
    return res.data as Map<String, dynamic>;
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(dioProvider));
});
