import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CartItem {
  final String medicineId;
  final String medicineName;
  final String brandOfferingId;
  final String packLabel;
  final double price;
  final double mrp;
  int quantity;
  final bool requiresPrescription;
  final String? imageUrl;

  CartItem({
    required this.medicineId,
    required this.medicineName,
    required this.brandOfferingId,
    required this.packLabel,
    required this.price,
    required this.mrp,
    required this.quantity,
    required this.requiresPrescription,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'medicineName': medicineName,
    'brandOfferingId': brandOfferingId,
    'packLabel': packLabel,
    'price': price,
    'mrp': mrp,
    'quantity': quantity,
    'requiresPrescription': requiresPrescription,
    'imageUrl': imageUrl,
  };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    medicineId: j['medicineId'] as String,
    medicineName: j['medicineName'] as String,
    brandOfferingId: j['brandOfferingId'] as String,
    packLabel: j['packLabel'] as String,
    price: (j['price'] as num).toDouble(),
    mrp: (j['mrp'] as num).toDouble(),
    quantity: j['quantity'] as int,
    requiresPrescription: j['requiresPrescription'] as bool? ?? false,
    imageUrl: j['imageUrl'] as String?,
  );
}

class CartState {
  final List<CartItem> items;
  const CartState({this.items = const []});

  double get subtotal => items.fold(0, (s, i) => s + i.price * i.quantity);
  int get totalItems => items.fold(0, (s, i) => s + i.quantity);
  bool get hasPrescriptionItems => items.any((i) => i.requiresPrescription);
}

class CartNotifier extends StateNotifier<CartState> {
  static const _boxKey = 'cart_items';
  late Box _box;

  CartNotifier() : super(const CartState()) {
    _load();
  }

  Future<void> _load() async {
    _box = await Hive.openBox(_boxKey);
    final raw = _box.get('items') as String?;
    if (raw != null) {
      final list = (jsonDecode(raw) as List).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
      state = CartState(items: list);
    }
  }

  Future<void> _persist() async {
    await _box.put('items', jsonEncode(state.items.map((e) => e.toJson()).toList()));
  }

  void addItem(CartItem item) {
    final existing = state.items.indexWhere((i) => i.brandOfferingId == item.brandOfferingId);
    if (existing >= 0) {
      final updated = [...state.items];
      updated[existing].quantity += item.quantity;
      state = CartState(items: updated);
    } else {
      state = CartState(items: [...state.items, item]);
    }
    _persist();
  }

  void updateQuantity(String brandOfferingId, int qty) {
    if (qty <= 0) {
      removeItem(brandOfferingId);
      return;
    }
    final updated = state.items.map((i) {
      if (i.brandOfferingId == brandOfferingId) i.quantity = qty;
      return i;
    }).toList();
    state = CartState(items: updated);
    _persist();
  }

  void removeItem(String brandOfferingId) {
    state = CartState(items: state.items.where((i) => i.brandOfferingId != brandOfferingId).toList());
    _persist();
  }

  void clear() {
    state = const CartState();
    _persist();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
