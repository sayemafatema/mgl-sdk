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

/// Fixed amber API error strip matching `app/page.tsx` (`apiBanner` alert).
class FleetReactApiBanner extends StatelessWidget {
  const FleetReactApiBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  static const Color _amber50 = Color(0xfffffbeb);
  static const Color _amber200 = Color(0xfffde68a);
  static const Color _amber700 = Color(0xffb45309);
  static const Color _amber900 = Color(0xff78350f);
  static const Color _amber950 = Color(0xff451a03);

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final maxH = (screenH * 0.4).clamp(80.0, 220.0);
    return Material(
      color: _amber50,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _amber200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: _amber700),
            const SizedBox(width: 8),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: FleetReactTheme.caption,
                      height: 1.35,
                      color: _amber950,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _amber900,
              ),
              child: const Text(
                'Dismiss',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: FleetReactTheme.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
