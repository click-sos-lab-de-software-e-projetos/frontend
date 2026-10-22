import 'package:flutter/material.dart';

import '../../app/theme.dart';

class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton(this.label, this.onPressed, {super.key, this.color = AppColors.cyan});

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            foregroundColor: color,
            backgroundColor: color.withValues(alpha: .08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}
