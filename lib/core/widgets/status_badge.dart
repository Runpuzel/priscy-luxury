import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case OrderStatus.pendingPayment:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
      case OrderStatus.confirmed:
        bg = AppColors.goldLight;
        fg = AppColors.espresso;
      case OrderStatus.processing:
        bg = AppColors.sand;
        fg = AppColors.espresso;
      case OrderStatus.dispatched:
        bg = const Color(0xFFE6F0FA);
        fg = const Color(0xFF1A5692);
      case OrderStatus.delivered:
        bg = AppColors.successSoft;
        fg = AppColors.success;
      case OrderStatus.cancelled:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      PaymentStatus.paid => (AppColors.successSoft, AppColors.success),
      PaymentStatus.unpaid => (AppColors.warningSoft, AppColors.warning),
      PaymentStatus.failed => (AppColors.dangerSoft, AppColors.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
