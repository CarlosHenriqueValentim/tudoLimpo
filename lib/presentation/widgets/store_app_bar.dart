// lib/presentation/widgets/store_app_bar.dart

import 'package:flutter/material.dart';
import '../../data/repositories/store_controller.dart';

class StoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final StoreController controller;
  final String title;
  final bool showBack;

  const StoreAppBar({
    required this.controller,
    required this.title,
    this.showBack = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Text(title),
      actions: <Widget>[
        AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Badge(
                label: Text('${controller.cartItemCount}'),
                isLabelVisible: controller.cartItemCount > 0,
                child: IconButton(
                  tooltip: 'Carrinho de Compras',
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => openCart(context, controller),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

void openCart(BuildContext context, StoreController controller) {
  Navigator.pushNamed(context, '/cart', arguments: controller);
}

void showAppMessage(
    BuildContext context,
    String message, {
      bool success = false,
    }) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? const Color(0xFF2EAD55) : null,
      content: Text(message),
    ),
  );
}