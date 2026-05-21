import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tokens aligned with Android `FleetReactTokens` + `FleetDriverScreens` Compose.
abstract final class FleetReactTheme {
  // Android Green700 / primary actions (Confirm PIN, Continue, nav selected)
  static const Color green700 = Color(0xff047857);
  static const Color green600 = Color(0xff2e7d32);
  // Send OTP — ReactGreenBtn
  static const Color primaryCta = Color(0xff43a047);

  static const Color gray50 = Color(0xfff9fafb);
  static const Color gray100 = Color(0xfff3f4f6);
  static const Color gray500 = Color(0xff6b7280);
  static const Color gray600 = Color(0xff4b5563);
  static const Color tabShellBg = Color(0xffeceff1);

  static const Color textPrimary = Color(0xff1a202c);
  static const Color textMuted = Color(0xff718096);
  static const Color textCaption = Color(0xff6b7280);
  static const Color placeholder = Color(0xff94a3b8);

  static const Color headerBg = Color(0xff1a3020);
  static const Color headerMuted = Color(0xffc8e6c9);
  static const Color headerAvatarBg = Color(0xff2d4a36);

  static const Color cardBorder = Color(0xffe5e7eb);
  static const Color logoBg = Color(0xff3f3f46);
  static const Color logoBorder = Color(0xff52525b);

  static const Color blue50 = Color(0xffeff6ff);
  static const Color blue200 = Color(0xffbfdbfe);
  static const Color blue900 = Color(0xff1e3a8a);

  static const Color redBg = Color(0xfffef2f2);
  static const Color redBorder = Color(0xfffecaca);
  static const Color redText = Color(0xff7f1d1d);
  static const Color red600 = Color(0xffdc2626);
  static const Color warning = Color(0xffd97706);

  static const Color disabledBg = Color(0xffe2e8f0);
  static const Color disabledText = Color(0xff94a3b8);

  static const Color numpadBackspaceBg = Color(0xfffee2e2);
  static const Color receiptFooterBg = Color(0xff064e3b);

  static const double radiusLg = 16;
  static const double radiusMd = 12;
  static const double radiusSm = 10;
  static const double spacePage = 20;
  static const double spaceBlock = 16;
  static const double caption = 12;
  static const double body = 14;
  static const double title = 18;

  static ButtonStyle filledGreen700({bool enabled = true}) =>
      FilledButton.styleFrom(
        backgroundColor: green700,
        disabledBackgroundColor: const Color(0xffd1d5db),
        foregroundColor: Colors.white,
        disabledForegroundColor: disabledText,
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      );

  static ButtonStyle filledSendOtp({bool enabled = true}) =>
      FilledButton.styleFrom(
        backgroundColor: primaryCta,
        disabledBackgroundColor: disabledBg,
        foregroundColor: Colors.white,
        disabledForegroundColor: disabledText,
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      );

  static ThemeData materialTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: gray100,
      colorScheme: const ColorScheme.light(
        primary: green700,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: textPrimary,
        outline: cardBorder,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: body, color: textPrimary),
        titleMedium: TextStyle(
          fontSize: title,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      dividerColor: cardBorder,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: green700, width: 2),
        ),
        hintStyle: const TextStyle(color: placeholder, fontSize: body),
      ),
      filledButtonTheme: FilledButtonThemeData(style: filledGreen700()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
    );
  }
}

/// Amber API error strip (`apiBanner`).
class FleetReactApiBanner extends StatelessWidget {
  const FleetReactApiBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xfffffbeb),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: Color(0xffb45309)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xff451a03)),
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              child: const Text('Dismiss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green success strip (Android `successBanner`).
class FleetReactSuccessBanner extends StatelessWidget {
  const FleetReactSuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: FleetReactTheme.green700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
      ),
    );
  }
}
