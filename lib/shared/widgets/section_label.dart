import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      );
}
