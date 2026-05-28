import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

const kOrderDateFormat = 'dd MMM yyyy, hh:mm a';

Color orderStatusColor(String status) {
  final s = status.toUpperCase();
  if (s.contains('CANCEL') || s.contains('FAILED')) return AppColors.danger;
  if (s == 'DELIVERED' || s == 'REFUNDED') return AppColors.secondary;
  if (s.contains('RETURN')) return AppColors.warning;
  return AppColors.primary;
}

/// Friendly label for an order status code. Long codes like
/// `DELIVERY_ASSIGNED` get a short, human-readable name so the UI badge
/// doesn't truncate on narrow phones.
String orderStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PAYMENT_PENDING':
      return 'Payment Pending';
    case 'ORDER_RECEIVED':
      return 'Received';
    case 'ORDER_TAKEN':
      return 'Taken Up';
    case 'ORDER_PROCESSING':
      return 'Processing';
    case 'DELIVERY_ASSIGNED':
      return 'Out for Delivery';
    case 'OUT_FOR_DELIVERY':
      return 'Out for Delivery';
    case 'DELIVERED':
      return 'Delivered';
    case 'CANCELLED':
    case 'ORDER_CANCELLED':
      return 'Cancelled';
    case 'REFUNDED':
      return 'Refunded';
    case 'RETURN_REQUESTED':
      return 'Return Requested';
    case 'RETURNED':
      return 'Returned';
    case 'PAYMENT_FAILED':
      return 'Payment Failed';
    default:
      // Fallback: turn SNAKE_CASE into Title Case.
      return status
          .split('_')
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join(' ');
  }
}

String formatOrderDate(DateTime dt) =>
    DateFormat(kOrderDateFormat).format(dt.toLocal());
