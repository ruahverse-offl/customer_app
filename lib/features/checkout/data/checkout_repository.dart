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

  /// Check stock availability for cart items before checkout.
  /// Returns all_available flag and per-item availability details.
  Future<Map<String, dynamic>> validateCart(List<Map<String, dynamic>> items) async {
    final res = await _dio.post('/razorpay/validate-cart', data: {'items': items});
    return res.data as Map<String, dynamic>;
  }

  /// Report checkout abandonment or failure to the backend so the order status
  /// is updated and stock is restored if the payment window has expired.
  Future<void> reportCheckoutOutcome({
    required String orderId,
    required String outcome, // 'abandoned' | 'failed'
    String? errorDescription,
    String? razorpayPaymentId,
  }) async {
    await _dio.post('/razorpay/checkout-outcome', data: {
      'order_id': orderId,
      'outcome': outcome,
      if (errorDescription != null) 'error_description': errorDescription,
      if (razorpayPaymentId != null) 'razorpay_payment_id': razorpayPaymentId,
    });
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(dioProvider));
});
