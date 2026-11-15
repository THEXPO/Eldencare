import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.large = false});

  final OverallTaskStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = StatusPalette.color(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusPalette.icon(status), size: large ? 20 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
