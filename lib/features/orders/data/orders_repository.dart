import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'order_models.dart';

class OrdersRepository {
  final Dio _dio;
  const OrdersRepository(this._dio);

  Future<({List<Order> items, int total})> getOrders({int limit = 20, int offset = 0}) async {
    final res = await _dio.get('/orders/', queryParameters: {'limit': limit, 'offset': offset});
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    final total = int.tryParse(data['pagination']?['total']?.toString() ?? '0') ?? 0;
    return (items: items, total: total);
  }

  Future<Order> getOrderDetail(String id) async {
    final res = await _dio.get('/orders/$id/detail');
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> cancelOrder(String id, String reason) async {
    await _dio.post('/orders/$id/cancel', data: {'cancellation_reason': reason});
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(dioProvider));
});
