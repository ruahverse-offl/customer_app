import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class CheckoutRepository {
  final Dio _dio;
  const CheckoutRepository(this._dio);

  Future<Map<String, dynamic>> getDeliverySettings() async {
    final res = await _dio.get('/delivery-settings');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final res = await _dio.get('/coupons', queryParameters: {'is_active': 'true'});
    final raw = res.data;
    final items = raw is Map ? (raw['items'] ?? []) : raw;
    return (items as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double orderAmount) async {
    final res = await _dio.post('/coupons/validate', data: {'code': code, 'order_amount': orderAmount});
    return res.data as Map<String, dynamic>;
  }

  Future<String?> uploadPrescription(String filePath, String fileName) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'category': 'prescription',
    });
    final res = await _dio.post('/upload', data: form);
    // Use stored_as (relative path) so backend can validate prescription/ prefix
    return (res.data['stored_as'] ?? res.data['url']) as String?;
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
