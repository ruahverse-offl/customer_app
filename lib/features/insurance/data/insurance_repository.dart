import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class InsuranceRepository {
  final Dio _dio;
  const InsuranceRepository(this._dio);

  Future<void> submitEnquiry({
    required String customerName,
    required String customerPhone,
    int? customerAge,
    int? familySize,
    String? planType,
    String? message,
  }) async {
    await _dio.post('/insurance-enquiries', data: {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (customerAge != null) 'customer_age': customerAge,
      if (familySize != null) 'family_size': familySize,
      if (planType != null && planType.isNotEmpty) 'plan_type': planType,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }
}

final insuranceRepositoryProvider = Provider<InsuranceRepository>((ref) {
  return InsuranceRepository(ref.watch(dioProvider));
});
