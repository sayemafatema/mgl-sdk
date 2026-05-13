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

  /// Mirrors `errTxt` in `app/page.tsx` (prefer clean API/exception message).
  static String _errTxt(Object? e) {
    if (e == null) return '';
    if (e is String) return e.trim();
    final s = e.toString().trim();
    const strips = [
      'Exception: ',
      'FormatException: ',
      'ClientException: ',
      'SocketException: ',
      'HandshakeException: ',
    ];
    for (final p in strips) {
      if (s.startsWith(p)) return s.substring(p.length).trim();
    }
    return s;
  }

  /// Mirrors `bannerFromThrownError` in `app/page.tsx`.
  static String bannerFromThrown(Object? e, String transportFallback) {
    final m = _errTxt(e);
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

  static const _otpVerifyBannerFallback =
      'Could not verify OTP. Check your connection and try again.';
  static const _pinVerifyBannerFallback =
      'Could not verify PIN. Check your connection and try again.';

  static final _otpAuthNoise = RegExp(
    r'unauthori[sz]ed|invalid[_\s-]?grant|invalid[_\s-]?token|\b401\b|bad\s*credentials|access\s*denied|^oauth\s+failed|^http\s*401|authentication\s*failed|full\s*authentication',
    caseSensitive: false,
  );

  static final _pinAuthNoise = RegExp(
    r'unauthori[sz]ed|invalid[_\s-]?grant|\b401\b|bad\s*credentials|access\s*denied|^oauth\s+failed|^http\s*401|wrong\s*pin|incorrect\s*pin|invalid\s*pin|authentication\s*failed',
    caseSensitive: false,
  );

  static String _humanizeOtpVerifyBanner(String base, String transportFallback) {
    if (base == transportFallback) return base;
    final t = base.trim();
    if (t.isEmpty || t == 'Request failed.') return 'Incorrect OTP. Try again.';
    if (_otpAuthNoise.hasMatch(t)) return 'Incorrect OTP. Try again.';
    return base;
  }

  static String _humanizePinVerifyBanner(String base, String transportFallback) {
    if (base == transportFallback) return base;
    final t = base.trim();
    if (t.isEmpty || t == 'Request failed.') return 'Incorrect PIN. Try again.';
    if (_pinAuthNoise.hasMatch(t)) return 'Incorrect PIN. Try again.';
    return base;
  }

  static String forOtpFailure(Object? e) => _humanizeOtpVerifyBanner(
        bannerFromThrown(e, _otpVerifyBannerFallback),
        _otpVerifyBannerFallback,
      );

  static String forPinFailure(Object? e) => _humanizePinVerifyBanner(
        bannerFromThrown(e, _pinVerifyBannerFallback),
        _pinVerifyBannerFallback,
      );

  static String forGenericFailure(Object? e) => bannerFromThrown(
        e,
        'Something went wrong. Check your connection and try again.',
      );
}
