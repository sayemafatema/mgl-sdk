import 'package:flutter/material.dart';

/// Tailwind / `app/page.tsx` tokens (`green-700`, `#43a047` Send OTP, `#1A202C` text, `rounded-2xl`).
abstract final class FleetReactTheme {
  static const Color gray50 = Color(0xfff9fafb);
  static const Color gray100 = Color(0xfff3f4f6);
  static const Color gray500 = Color(0xff6b7280);
  static const Color gray600 = Color(0xff4b5563);
  /// Tailwind `green-700` — primary outline / links.
  static const Color green700 = Color(0xff15803d);
  /// Material green from login “Send OTP” (`bg-[#43a047]`).
  static const Color primaryCta = Color(0xff43a047);
  static const Color green800 = Color(0xff166534);
  static const Color blue50 = Color(0xffeff6ff);
  static const Color blue200 = Color(0xffbfdbfe);
  static const Color blue900 = Color(0xff1e3a8a);
  static const Color textPrimary = Color(0xff1a202c);
  static const Color textMuted = Color(0xff718096);
  static const Color textCaption = Color(0xff6b7280);

  static const double radiusLg = 16; // rounded-2xl
  static const double radiusMd = 12;
  static const double spacePage = 20;
  static const double spaceBlock = 16;
  static const double caption = 12;
  static const double body = 14;
  static const double title = 18;

  static ThemeData materialTheme() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: FleetReactTheme.primaryCta,
        brightness: Brightness.light,
        primary: FleetReactTheme.primaryCta,
        onPrimary: Colors.white,
      ),
      useMaterial3: true,
    );
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryCta,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: green700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),
    );
  }
}
