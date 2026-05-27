// lib/presentation/widgets/quantity_control.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: onDecrease,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(Icons.remove, size: 18, color: AppColors.primary),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: onIncrease,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(Icons.add, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}