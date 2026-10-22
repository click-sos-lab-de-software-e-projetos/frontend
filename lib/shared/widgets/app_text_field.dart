import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AppTextField extends StatelessWidget {
  const AppTextField(
    this.hint,
    this.controller, {
    super.key,
    this.keyboardType,
    this.obscure = false,
    this.validator,
  });

  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );
}
