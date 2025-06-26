import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: AppColors.secondary,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.background,
    background: AppColors.secondary,
    onPrimary: Colors.white,
    onSurface: AppColors.text,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.glass,
    labelStyle: TextStyle(color: Colors.grey[400]),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.text,
    ),
    bodyMedium: TextStyle(fontSize: 16, color: AppColors.text),
    bodySmall: TextStyle(fontSize: 14, color: Colors.grey),
  ),
);
