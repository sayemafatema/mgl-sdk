/// User-visible copy aligned with `app/page.tsx`.
abstract final class ReactParityStrings {
  static const invalidFleetpayQr =
      'Invalid Fleetpay QR. Point at the station QR (must include tid).';
  static const selectVehicleFirst = 'Select a vehicle first.';
  static const pinsDontMatch1f = "PINs don't match. Try again.";
  static const pinsDidntMatchConfirm = "PINs didn't match. Try again.";
  static const newUserContinueInvite =
      'New user — continue with invite code.';
  static const noActiveFleet = 'No active fleet — use your invite code.';
  static const useSendOtpLogin = 'Use “Send OTP” on the login screen.';
  static const inviteIncompleteMobile =
      'Invite flow incomplete — verify mobile first.';
  static const sessionMissingInvite =
      'Session missing — go back to invite step.';

  static const int bannerMaxLen = 280;

  /// Mirrors `bannerFromThrownError` in `app/page.tsx`.
  static String bannerFromThrown(Object? e, String transportFallback) {
    final m = e?.toString().trim() ?? '';
    if (_likelyNetwork(m)) return transportFallback;
    if (m.isEmpty) return 'Request failed.';
    if (m.length <= bannerMaxLen) return m;
    return '${m.substring(0, bannerMaxLen - 1)}…';
  }

  static bool _likelyNetwork(String msg) {
    final l = msg.toLowerCase();
    return RegExp(
      r'network|fetch|failed to fetch|timeout|502|503|504|econn|aborted',
    ).hasMatch(l);
  }

  static String forOtpFailure(Object? e) => bannerFromThrown(
        e,
        'Could not verify OTP. Check your connection and try again.',
      );

  static String forPinFailure(Object? e) => bannerFromThrown(
        e,
        'Could not verify PIN. Check your connection and try again.',
      );

  static String forGenericFailure(Object? e) => bannerFromThrown(
        e,
        'Something went wrong. Check your connection and try again.',
      );
}
