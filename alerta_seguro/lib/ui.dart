import 'package:flutter/material.dart';

const kBg = Color(0xFF0A0B10);
const kCard = Color(0xFF14151F);
const kCyan = Color(0xFF00E5FF);
const kRed = Color(0xFFFF3B30);

Widget sectionLabel(String t) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(t.toUpperCase(),
          style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );

Widget box({required Widget child, EdgeInsets pad = const EdgeInsets.all(14)}) => Container(
      width: double.infinity,
      padding: pad,
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: child,
    );

Widget field(String hint, TextEditingController c, {TextInputType? type}) => TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: kCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );

Widget header(String title, [String? sub]) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        if (sub != null) Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ]),
    );

Widget outlineButton(String label, VoidCallback onTap, {Color color = kCyan}) => SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(side: BorderSide(color: color), foregroundColor: color,
            backgroundColor: color.withOpacity(.08), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
