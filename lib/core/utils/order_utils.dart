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

String formatOrderDate(DateTime dt) =>
    DateFormat(kOrderDateFormat).format(dt.toLocal());
