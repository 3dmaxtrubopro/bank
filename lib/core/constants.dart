import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String appTitle = 'PostFinance App';
  static const double gridUnit = 4;
  static const Duration apiDelay = Duration(milliseconds: 700);
  static const String defaultCurrency = 'CHF';
  static const String currencyLocale = 'en_CH';
}

abstract final class AppLayout {
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 20,
  );
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(18));
}

abstract final class AppColors {
  static const Color ink = Color(0xFF121212);
  static const Color steel = Color(0xFF5F6368);
  static const Color line = Color(0xFFE4E7EB);
  static const Color lineSoft = Color(0xFFF0F2F4);
  static const Color background = Color(0xFFFDFDFB);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color panel = Colors.white;
  static const Color accent = Color(0xFFB8A06A);
  static const Color accentDeep = Color(0xFF8F7948);
  static const Color success = Color(0xFF2F6B4F);
  static const Color alert = Color(0xFFB54747);
}
