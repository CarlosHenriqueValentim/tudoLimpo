// lib/presentation/widgets/summary_card.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/store_controller.dart';

class SummaryCard extends StatelessWidget {
  final StoreController controller;

  const SummaryCard({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Resumo da compra',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SummaryRow(
              label: 'Subtotal',
              value: formatMoney(controller.subtotal),
            ),
            SummaryRow(
              label: controller.shipping == 0
                  ? 'Frete (grátis acima de R\$ 150)'
                  : 'Frete',
              value: controller.shipping == 0
                  ? 'GRÁTIS'
                  : formatMoney(controller.shipping),
              highlight: controller.shipping == 0,
              highlightColor: AppColors.success,
            ),
            SummaryRow(
              label: 'Impostos (10%)',
              value: formatMoney(controller.taxes),
            ),
            const Divider(),
            SummaryRow(
              label: 'Total',
              value: formatMoney(controller.total),
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  const SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        highlightColor ?? (highlight ? AppColors.primary : Colors.black87);
    final TextStyle style = TextStyle(
      fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
      fontSize: highlight ? 18 : 15,
      color: color,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style.copyWith(color: Colors.black87)),
          Text(value, style: style),
        ],
      ),
    );
  }
}