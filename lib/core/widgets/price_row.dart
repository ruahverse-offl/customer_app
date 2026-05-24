import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const PriceRow(this.label, this.value, {super.key, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: bold ? AppTextStyles.label : AppTextStyles.body),
      const Spacer(),
      Text(value,
          style: (bold ? AppTextStyles.label : AppTextStyles.body)
              .copyWith(color: valueColor)),
    ]),
  );
}
