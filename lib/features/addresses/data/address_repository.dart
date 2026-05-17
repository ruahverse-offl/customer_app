import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'address_models.dart';

class AddressRepository {
  final Dio _dio;
  const AddressRepository(this._dio);

  Future<List<Address>> getMyAddresses() async {
    final res = await _dio.get('/addresses/my-addresses');
    final items = res.data['items'] ?? res.data as List;
    return (items as List).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Address> createAddress(Map<String, dynamic> data) async {
    final res = await _dio.post('/addresses', data: data);
    return Address.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Address> updateAddress(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/addresses/$id', data: data);
    return Address.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete('/addresses/$id');
  }

  Future<void> setDefault(String id) async {
    await _dio.patch('/addresses/$id/default');
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(dioProvider));
});
