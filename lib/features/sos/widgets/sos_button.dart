import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Round SOS button that fires [onTriggered] after being held for [holdDuration].
class SosButton extends StatefulWidget {
  const SosButton({super.key, required this.onTriggered, this.holdDuration = const Duration(seconds: 3)});

  final VoidCallback onTriggered;
  final Duration holdDuration;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: widget.holdDuration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _hold.reset();
        widget.onTriggered();
      }
    });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _hold.forward(),
        onTapUp: (_) => _hold.reset(),
        onTapCancel: _hold.reset,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (_, __) => SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200 + 30 * _hold.value,
                  height: 200 + 30 * _hold.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red.withValues(alpha: .12 + .1 * _hold.value),
                  ),
                ),
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: _hold.value,
                    strokeWidth: 4,
                    color: Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red,
                    boxShadow: [BoxShadow(color: AppColors.red.withValues(alpha: .6), blurRadius: 40)],
                  ),
                  alignment: Alignment.center,
                  child: const Text('SOS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      );
}
