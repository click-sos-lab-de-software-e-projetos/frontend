import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
}
