// lib/presentation/widgets/product_icon_widget.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/product.dart';

class ProductIconWidget extends StatelessWidget {
  final Product product;
  final double size;

  const ProductIconWidget({
    required this.product,
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        productIconData(product.icon),
        size: size * 0.55,
        color: AppColors.primaryDark,
      ),
    );
  }
}