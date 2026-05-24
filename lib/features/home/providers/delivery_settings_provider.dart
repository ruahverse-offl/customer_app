import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class DeliverySettings {
  final double freeDeliveryMinAmount;
  final double deliveryFee;
  final bool isEnabled;

  const DeliverySettings({
    required this.freeDeliveryMinAmount,
    required this.deliveryFee,
    required this.isEnabled,
  });

  factory DeliverySettings.fromJson(Map<String, dynamic> json) => DeliverySettings(
        freeDeliveryMinAmount:
            ((json['free_delivery_min_amount'] ?? json['free_delivery_threshold'] ?? 500) as num)
                .toDouble(),
        deliveryFee: ((json['delivery_fee'] ?? 40) as num).toDouble(),
        isEnabled: (json['is_enabled'] ?? true) as bool,
      );
}

final deliverySettingsProvider = FutureProvider<DeliverySettings>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/delivery-settings');
  return DeliverySettings.fromJson(res.data as Map<String, dynamic>);
});
