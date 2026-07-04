import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.type});

  final String label;
  final StatusType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      StatusType.success => AppColors.success,
      StatusType.warning => AppColors.warning,
      StatusType.danger => AppColors.danger,
      StatusType.neutral => Colors.blueGrey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum StatusType { success, warning, danger, neutral }
