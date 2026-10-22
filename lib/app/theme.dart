import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg = Color(0xFF0A0B10);
  static const card = Color(0xFF14151F);
  static const cyan = Color(0xFF00E5FF);
  static const red = Color(0xFFFF3B30);
}

ThemeData buildAppTheme() => ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(primary: AppColors.cyan, surface: AppColors.bg),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bg,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
      ),
    );
