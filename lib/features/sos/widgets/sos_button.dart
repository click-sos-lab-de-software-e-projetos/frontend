import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Round SOS button. One tap calls [onPressed]; `null` disables it.
class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onPressed, this.label = 'SOS'});

  final VoidCallback? onPressed;

  /// Shows the countdown while the alert can still be cancelled.
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Enviar alerta de emergência',
      child: GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.red.withValues(alpha: .15)),
              ),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? AppColors.red : AppColors.red.withValues(alpha: .5),
                  boxShadow: [BoxShadow(color: AppColors.red.withValues(alpha: .6), blurRadius: 40)],
                ),
                alignment: Alignment.center,
                child: Text(label, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
