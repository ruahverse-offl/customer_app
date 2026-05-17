class OrderItem {
  final String id;
  final String medicineName;
  final String? brandName;
  final String? packLabel;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.medicineName,
    this.brandName,
    this.packLabel,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    id: j['id'].toString(),
    medicineName: j['medicine_name']?.toString() ?? '',
    brandName: j['brand_name']?.toString(),
    packLabel: j['pack_label']?.toString(),
    quantity: int.tryParse(j['quantity']?.toString() ?? '1') ?? 1,
    unitPrice: double.tryParse(j['unit_price']?.toString() ?? '0') ?? 0,
    totalPrice: double.tryParse(j['total_price']?.toString() ?? '0') ?? 0,
  );
}

class OrderPayment {
  final String paymentStatus;
  final String? refundStatus;
  final double? refundAmount;

  const OrderPayment({required this.paymentStatus, this.refundStatus, this.refundAmount});

  factory OrderPayment.fromJson(Map<String, dynamic> j) => OrderPayment(
    paymentStatus: j['payment_status']?.toString() ?? '',
    refundStatus: j['refund_status']?.toString(),
    refundAmount: double.tryParse(j['refund_amount']?.toString() ?? ''),
  );
}

class Order {
  final String id;
  final String? orderReference;
  final String orderStatus;
  final double finalAmount;
  final double subtotal;
  final double deliveryFee;
  final String? deliveryAddress;
  final String? cancellationReason;
  final String? returnReason;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final OrderPayment? payment;

  const Order({
    required this.id,
    this.orderReference,
    required this.orderStatus,
    required this.finalAmount,
    required this.subtotal,
    required this.deliveryFee,
    this.deliveryAddress,
    this.cancellationReason,
    this.returnReason,
    this.createdAt,
    this.items = const [],
    this.payment,
  });

  factory Order.fromJson(Map<String, dynamic> j) {
    final order = j['order'] as Map<String, dynamic>? ?? j;
    final itemsRaw = j['items'] as List? ?? [];
    final paymentRaw = j['payment'] as Map<String, dynamic>?;
    return Order(
      id: order['id'].toString(),
      orderReference: order['order_reference']?.toString(),
      orderStatus: order['order_status']?.toString() ?? '',
      finalAmount: double.tryParse(order['final_amount']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0,
      deliveryFee: double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0,
      deliveryAddress: order['delivery_address']?.toString(),
      cancellationReason: order['cancellation_reason']?.toString(),
      returnReason: order['return_reason']?.toString(),
      createdAt: order['created_at'] != null ? DateTime.tryParse(order['created_at'].toString()) : null,
      items: itemsRaw.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      payment: paymentRaw != null ? OrderPayment.fromJson(paymentRaw) : null,
    );
  }
}
