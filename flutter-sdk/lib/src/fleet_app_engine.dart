import 'dart:async';

import 'package:flutter/foundation.dart';

import 'fleet_demo_data.dart';

const _kUnset = Object();

const _demoOtp = '123456';
const _demoPin = '123456';

List<String> _cloneOtpSlots() => List<String>.filled(6, '');

List<FleetBinding> _cloneBindings() =>
    mockBindings.map((b) => b.copy()).toList();

class FleetAppSnapshot {
  FleetAppSnapshot({
    required this.authStep,
    required this.profile,
    required this.mobileNumber,
    required this.otpDigitsLogin,
    required this.otpErrorLogin,
    required this.inviteCode,
    required this.inviteOtp,
    required this.invitePin,
    required this.invitePinConfirm,
    required this.loginPin,
    required this.loginPinError,
    required this.wrongAttempts,
    required this.disableLoginNumpad,
    required this.newPin,
    required this.pinConfirm,
    required this.pinError,
    required this.isNewUser,
    required this.successToast,
    required this.mainOverlay,
    required this.activeTab,
    required this.activeCardIndex,
    required this.sessionState,
    required this.sessionPin,
    required this.pairingDigits,
    required this.pairingError,
    required this.pairingAttempts,
    required this.selectedScanBindingId,
    required this.bindings,
    required this.transactions,
    required this.pendingPairingCode,
  });

  final String authStep;
  final FleetDriverProfile profile;
  final String mobileNumber;
  final List<String> otpDigitsLogin;
  final String otpErrorLogin;
  final String inviteCode;
  final String inviteOtp;
  final String invitePin;
  final String invitePinConfirm;
  final String loginPin;
  final String loginPinError;
  final int wrongAttempts;
  final bool disableLoginNumpad;
  final String newPin;
  final String pinConfirm;
  final String pinError;
  final bool isNewUser;
  final String? successToast;
  final String mainOverlay;
  final String activeTab;
  final int activeCardIndex;
  final String sessionState;
  final String sessionPin;
  final List<String> pairingDigits;
  final String pairingError;
  final int pairingAttempts;
  final String? selectedScanBindingId;
  final List<FleetBinding> bindings;
  final List<FleetTransaction> transactions;
  final String pendingPairingCode;

  FleetAppSnapshot copy({
    Object? authStep = _kUnset,
    Object? profile = _kUnset,
    Object? mobileNumber = _kUnset,
    Object? otpDigitsLogin = _kUnset,
    Object? otpErrorLogin = _kUnset,
    Object? inviteCode = _kUnset,
    Object? inviteOtp = _kUnset,
    Object? invitePin = _kUnset,
    Object? invitePinConfirm = _kUnset,
    Object? loginPin = _kUnset,
    Object? loginPinError = _kUnset,
    Object? wrongAttempts = _kUnset,
    Object? disableLoginNumpad = _kUnset,
    Object? newPin = _kUnset,
    Object? pinConfirm = _kUnset,
    Object? pinError = _kUnset,
    Object? isNewUser = _kUnset,
    Object? successToast = _kUnset,
    Object? mainOverlay = _kUnset,
    Object? activeTab = _kUnset,
    Object? activeCardIndex = _kUnset,
    Object? sessionState = _kUnset,
    Object? sessionPin = _kUnset,
    Object? pairingDigits = _kUnset,
    Object? pairingError = _kUnset,
    Object? pairingAttempts = _kUnset,
    Object? selectedScanBindingId = _kUnset,
    Object? bindings = _kUnset,
    Object? transactions = _kUnset,
    Object? pendingPairingCode = _kUnset,
  }) {
    T pick<T>(Object? v, T cur) =>
        identical(v, _kUnset) ? cur : v as T;

    return FleetAppSnapshot(
      authStep: pick(authStep, this.authStep),
      profile: pick(profile, this.profile),
      mobileNumber: pick(mobileNumber, this.mobileNumber),
      otpDigitsLogin: pick(
          otpDigitsLogin,
          List<String>.from(this.otpDigitsLogin)),
      otpErrorLogin: pick(otpErrorLogin, this.otpErrorLogin),
      inviteCode: pick(inviteCode, this.inviteCode),
      inviteOtp: pick(inviteOtp, this.inviteOtp),
      invitePin: pick(invitePin, this.invitePin),
      invitePinConfirm:
          pick(invitePinConfirm, this.invitePinConfirm),
      loginPin: pick(loginPin, this.loginPin),
      loginPinError: pick(loginPinError, this.loginPinError),
      wrongAttempts: pick(wrongAttempts, this.wrongAttempts),
      disableLoginNumpad:
          pick(disableLoginNumpad, this.disableLoginNumpad),
      newPin: pick(newPin, this.newPin),
      pinConfirm: pick(pinConfirm, this.pinConfirm),
      pinError: pick(pinError, this.pinError),
      isNewUser: pick(isNewUser, this.isNewUser),
      successToast: pick(successToast, this.successToast),
      mainOverlay: pick(mainOverlay, this.mainOverlay),
      activeTab: pick(activeTab, this.activeTab),
      activeCardIndex: pick(activeCardIndex, this.activeCardIndex),
      sessionState: pick(sessionState, this.sessionState),
      sessionPin: pick(sessionPin, this.sessionPin),
      pairingDigits:
          pick(pairingDigits, List<String>.from(this.pairingDigits)),
      pairingError: pick(pairingError, this.pairingError),
      pairingAttempts: pick(pairingAttempts, this.pairingAttempts),
      selectedScanBindingId:
          pick(selectedScanBindingId, this.selectedScanBindingId),
      bindings: pick(bindings,
          this.bindings.map((b) => b.copy()).toList()),
      transactions: pick(transactions,
          this.transactions.map((t) => t.copy()).toList()),
      pendingPairingCode:
          pick(pendingPairingCode, this.pendingPairingCode),
    );
  }

  factory FleetAppSnapshot.initial() {
    return FleetAppSnapshot(
      authStep: 'login',
      profile: mockFleetProfile,
      mobileNumber: '',
      otpDigitsLogin: _cloneOtpSlots(),
      otpErrorLogin: '',
      inviteCode: '',
      inviteOtp: '',
      invitePin: '',
      invitePinConfirm: '',
      loginPin: '',
      loginPinError: '',
      wrongAttempts: 0,
      disableLoginNumpad: false,
      newPin: '',
      pinConfirm: '',
      pinError: '',
      isNewUser: false,
      successToast: null,
      mainOverlay: 'home',
      activeTab: 'card',
      activeCardIndex: 0,
      sessionState: 'idle',
      sessionPin: '',
      pairingDigits: _cloneOtpSlots(),
      pairingError: '',
      pairingAttempts: 0,
      selectedScanBindingId: null,
      bindings: _cloneBindings(),
      transactions: mockTransactions.map((t) => t.copy()).toList(),
      pendingPairingCode: '234567',
    );
  }
}

class FleetAppEngine extends ChangeNotifier {
  FleetAppSnapshot _s = FleetAppSnapshot.initial();
  final List<Timer> _timers = [];

  FleetAppSnapshot getSnapshot() => _s;

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }

  void _later(Duration d, void Function() fn) {
    _timers.add(Timer(d, fn));
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _emit(FleetAppSnapshot next) {
    _s = next;
    notifyListeners();
  }

  void skipToMainApp() {
    _emit(_s.copy(
      authStep: 'complete',
      mainOverlay: 'home',
      activeTab: 'card',
      loginPin: '',
      otpDigitsLogin: _cloneOtpSlots(),
    ));
  }

  void setMobileNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final slice =
        digits.length <= 10 ? digits : digits.substring(0, 10);
    _emit(_s.copy(mobileNumber: slice));
  }

  void loginSendOtp() {
    if (_s.mobileNumber.length != 10) return;
    _emit(_s.copy(
      authStep: 'login_otp',
      otpDigitsLogin: _cloneOtpSlots(),
      otpErrorLogin: '',
    ));
  }

  void setLoginOtpDigit(int index, String digit) {
    final d = digit.replaceAll(RegExp(r'\D'), '');
    final ch = d.isEmpty ? '' : d.substring(d.length - 1);
    final next = List<String>.from(_s.otpDigitsLogin);
    next[index] = ch;
    _emit(_s.copy(otpDigitsLogin: next));
    if (next.join().length == 6) verifyLoginOtp();
  }

  void verifyLoginOtp() {
    final entered = _s.otpDigitsLogin.join();
    if (entered != _demoOtp) {
      _emit(_s.copy(otpErrorLogin: 'Incorrect OTP. Try again.'));
      _later(const Duration(milliseconds: 1200), () {
        _emit(_s.copy(
          otpDigitsLogin: _cloneOtpSlots(),
          otpErrorLogin: '',
        ));
      });
      return;
    }
    _emit(_s.copy(
      authStep: 'pin_login',
      loginPin: '',
      loginPinError: '',
      otpErrorLogin: '',
    ));
  }

  void loginPinAppend(String digit) {
    if (_s.disableLoginNumpad || _s.loginPin.length >= 6) return;
    final next = _s.loginPin + digit;
    _emit(_s.copy(loginPin: next, loginPinError: ''));
    if (next.length == 6) _submitLoginPin(next);
  }

  void loginPinBackspace() {
    if (_s.disableLoginNumpad) return;
    if (_s.loginPin.isEmpty) return;
    _emit(_s.copy(
        loginPin: _s.loginPin.substring(0, _s.loginPin.length - 1)));
  }

  void _submitLoginPin(String pin) {
    if (pin == _demoPin) {
      _emit(_s.copy(
        authStep: 'complete',
        loginPinError: '',
        wrongAttempts: 0,
        disableLoginNumpad: false,
      ));
      return;
    }
    final attempts = _s.wrongAttempts + 1;
    final disable = attempts >= 3;
    _emit(_s.copy(
      loginPinError: 'Incorrect PIN',
      loginPin: '',
      wrongAttempts: attempts,
      disableLoginNumpad: disable,
    ));
  }

  void goToForgotPin() {
    _emit(_s.copy(
      authStep: 'forgot_pin',
      inviteOtp: '',
      otpDigitsLogin: _cloneOtpSlots(),
    ));
  }

  void forgotPinSendOtp() {
    _emit(_s.copy(authStep: 'forgot_otp', inviteOtp: ''));
  }

  void setForgotOtpDigit(int index, String digit) {
    final d = digit.replaceAll(RegExp(r'\D'), '');
    final ch = d.isEmpty ? '' : d.substring(d.length - 1);
    final chars = _s.inviteOtp.split('');
    while (chars.length < 6) {
      chars.add('');
    }
    if (chars.length > 6) {
      chars.removeRange(6, chars.length);
    }
    chars[index] = ch;
    final otp = chars.take(6).join();
    _emit(_s.copy(inviteOtp: otp));
  }

  void verifyForgotOtp() {
    if (_s.inviteOtp != _demoOtp) return;
    _emit(_s.copy(
      authStep: 'set_pin',
      inviteOtp: '',
      newPin: '',
      pinConfirm: '',
      pinError: '',
      isNewUser: false,
    ));
  }

  void newPinAppend(String digit) {
    if (_s.newPin.length >= 6) return;
    _emit(_s.copy(newPin: _s.newPin + digit));
  }

  void newPinBackspace() {
    if (_s.newPin.isEmpty) return;
    _emit(_s.copy(
        newPin: _s.newPin.substring(0, _s.newPin.length - 1)));
  }

  void goConfirmNewPin() {
    if (_s.newPin.length != 6) return;
    _emit(_s.copy(authStep: 'confirm_pin', pinConfirm: '', pinError: ''));
  }

  void confirmPinAppend(String digit) {
    if (_s.pinConfirm.length >= 6) return;
    _emit(_s.copy(pinConfirm: _s.pinConfirm + digit));
  }

  void confirmPinBackspace() {
    if (_s.pinConfirm.isEmpty) return;
    _emit(_s.copy(
        pinConfirm:
            _s.pinConfirm.substring(0, _s.pinConfirm.length - 1)));
  }

  void submitConfirmPin() {
    if (_s.pinConfirm.length != 6) return;
    if (_s.newPin != _s.pinConfirm) {
      _emit(_s.copy(
        pinError: "PINs didn't match. Try again.",
        pinConfirm: '',
        authStep: 'set_pin',
      ));
      return;
    }
    if (_s.isNewUser) {
      _emit(_s.copy(authStep: 'registered', pinError: ''));
    } else {
      _emit(_s.copy(
        successToast: 'PIN updated successfully',
        newPin: '',
        pinConfirm: '',
        pinError: '',
        authStep: 'pin_login',
      ));
      _later(const Duration(seconds: 2), () {
        _emit(_s.copy(successToast: null));
      });
    }
  }

  void registeredContinueHome() {
    _emit(_s.copy(
      authStep: 'complete',
      isNewUser: false,
      newPin: '',
      pinConfirm: '',
    ));
  }

  void authBack() {
    final step = _s.authStep;
    if (step == 'login_otp') {
      _emit(_s.copy(authStep: 'login'));
    } else if (step == 'invite_code') {
      _emit(_s.copy(authStep: 'invite_otp'));
    } else if (step == 'invite_mobile') {
      _emit(_s.copy(authStep: 'login'));
    } else if (step == 'invite_otp') {
      _emit(_s.copy(authStep: 'invite_mobile'));
    } else if (step == 'forgot_otp') {
      _emit(_s.copy(authStep: 'forgot_pin'));
    } else if (step == 'forgot_pin') {
      _emit(_s.copy(authStep: 'pin_login', inviteOtp: ''));
    }
  }

  void goInviteSignup() {
    _emit(_s.copy(
      authStep: 'invite_mobile',
      mobileNumber: '',
      inviteOtp: '',
      inviteCode: '',
    ));
  }

  void setInviteCode(String raw) {
    final upper = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final slice =
        upper.length <= 6 ? upper : upper.substring(0, 6);
    _emit(_s.copy(inviteCode: slice));
  }

  void inviteContinue() {
    final code = _s.inviteCode;
    if (code.length != 6 || mockInviteCompanies[code] == null) return;
    _emit(_s.copy(
      authStep: 'invite_pin',
      invitePin: '',
      invitePinConfirm: '',
      pinError: '',
    ));
  }

  void inviteSendOtp() {
    if (_s.mobileNumber.length != 10) return;
    _emit(_s.copy(authStep: 'invite_otp', inviteOtp: ''));
  }

  void setInviteOtpDigit(int index, String digit) {
    final d = digit.replaceAll(RegExp(r'\D'), '');
    final ch = d.isEmpty ? '' : d.substring(d.length - 1);
    final chars = _s.inviteOtp.split('');
    while (chars.length < 6) {
      chars.add('');
    }
    if (chars.length > 6) {
      chars.removeRange(6, chars.length);
    }
    chars[index] = ch;
    final otp = chars.take(6).join();
    _emit(_s.copy(inviteOtp: otp));
    if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
      verifyInviteOtp();
    }
  }

  void verifyInviteOtp() {
    if (_s.inviteOtp != _demoOtp) return;
    _emit(_s.copy(
      authStep: 'invite_code',
      inviteCode: '',
    ));
  }

  void invitePinAppend(String digit) {
    if (_s.invitePin.length >= 6) return;
    _emit(_s.copy(invitePin: _s.invitePin + digit));
  }

  void invitePinBackspace() {
    if (_s.invitePin.isEmpty) return;
    _emit(_s.copy(
        invitePin:
            _s.invitePin.substring(0, _s.invitePin.length - 1)));
  }

  void invitePinNext() {
    if (_s.invitePin.length != 6) return;
    _emit(_s.copy(
      authStep: 'invite_confirm_pin',
      invitePinConfirm: '',
      pinError: '',
    ));
  }

  void invitePinConfirmAppend(String digit) {
    if (_s.invitePinConfirm.length >= 6) return;
    _emit(_s.copy(invitePinConfirm: _s.invitePinConfirm + digit));
  }

  void invitePinConfirmBackspace() {
    if (_s.invitePinConfirm.isEmpty) return;
    _emit(_s.copy(
      invitePinConfirm: _s.invitePinConfirm.substring(
          0, _s.invitePinConfirm.length - 1),
    ));
  }

  void inviteConfirmSubmit() {
    if (_s.invitePinConfirm.length != 6) return;
    if (_s.invitePin != _s.invitePinConfirm) {
      _emit(_s.copy(
        pinError: "PINs don't match, try again",
        invitePinConfirm: '',
      ));
      return;
    }
    _emit(_s.copy(
      authStep: 'complete',
      pinError: '',
      isNewUser: true,
    ));
  }

  void setTab(String tab) {
    var sel = _s.selectedScanBindingId;
    if (tab == 'scan') {
      final avail = scanAvailableBindings();
      if (avail.isNotEmpty && sel == null) {
        sel = avail.first.id;
      }
    }
    _emit(_s.copy(activeTab: tab, selectedScanBindingId: sel));
  }

  void setMainOverlay(String o) {
    _emit(_s.copy(mainOverlay: o));
  }

  void openAssignmentDemo() {
    _emit(_s.copy(mainOverlay: 'assignment_notification', activeTab: 'card'));
  }

  void acceptAssignmentDemo() {
    _emit(_s.copy(mainOverlay: 'assignment_accepted'));
  }

  void dismissAssignmentFlow() {
    _emit(_s.copy(mainOverlay: 'home', activeTab: 'assignments'));
  }

  void openPairingDemo() {
    _emit(_s.copy(
      mainOverlay: 'pairing_code',
      pairingDigits: _cloneOtpSlots(),
      pairingError: '',
    ));
  }

  void setPairingDigit(int i, String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    final ch = d.isEmpty ? '' : d.substring(d.length - 1);
    final next = List<String>.from(_s.pairingDigits);
    next[i] = ch;
    _emit(_s.copy(pairingDigits: next));
  }

  void submitPairingCode() {
    final code = _s.pairingDigits.join();
    if (code.length != 6) return;
    final info = mockPairingCodes[code];
    if (info == null) {
      final attempts = _s.pairingAttempts + 1;
      _emit(_s.copy(
        pairingError: 'Invalid pairing code',
        pairingAttempts: attempts,
        pairingDigits: _cloneOtpSlots(),
      ));
      return;
    }
    _emit(_s.copy(
      mainOverlay: 'home',
      pairingError: '',
      activeTab: 'assignments',
    ));
  }

  void setActiveCardIndex(int i) {
    final active = activeCards();
    if (i >= 0 && i < active.length) _emit(_s.copy(activeCardIndex: i));
  }

  List<FleetBinding> activeCards() {
    return _s.bindings
        .where((b) => b.paired && b.state == 'ACTIVE')
        .toList();
  }

  List<FleetBinding> scanAvailableBindings() {
    return _s.bindings
        .where((b) =>
            b.paired &&
            b.state == 'ACTIVE' &&
            (b.scanPayStatus == 'always_available' ||
                b.scanPayStatus == 'in_window'))
        .toList();
  }

  FleetBinding? selectedScanBinding() {
    final id = _s.selectedScanBindingId;
    if (id == null) return null;
    for (final b in _s.bindings) {
      if (b.id == id) return b;
    }
    return null;
  }

  FleetBinding? currentCard() {
    final cards = activeCards();
    if (cards.isEmpty) return null;
    final i = _s.activeCardIndex;
    return (i >= 0 && i < cards.length) ? cards[i] : cards[0];
  }

  int pendingAssignmentCount() {
    return _s.bindings
        .where((b) =>
            b.state == 'PENDING_ACCEPTANCE' ||
            (!b.paired && b.state == 'ACTIVE'))
        .length;
  }

  FleetBinding assignmentDemoBinding() {
    for (final b in _s.bindings) {
      if (b.state == 'PENDING_ACCEPTANCE') return b;
    }
    return _s.bindings.length > 3 ? _s.bindings[3] : _s.bindings.first;
  }

  void scanPickBinding(String id) {
    _emit(_s.copy(selectedScanBindingId: id));
  }

  void scanBeginConfirmation() {
    final avail = scanAvailableBindings();
    if (avail.isEmpty) return;
    final id = _s.selectedScanBindingId ?? avail.first.id;
    _emit(_s.copy(
        selectedScanBindingId: id, sessionState: 'confirmation'));
  }

  void scanCancelConfirmation() {
    _emit(_s.copy(sessionState: 'idle'));
  }

  void scanConfirmAuthorize() {
    if (_s.sessionPin != _demoPin) return;
    _emit(_s.copy(sessionState: 'idle', sessionPin: ''));
  }

  void setSessionPin(String pin) {
    final digits = pin.replaceAll(RegExp(r'\D'), '');
    final slice =
        digits.length <= 6 ? digits : digits.substring(0, 6);
    _emit(_s.copy(sessionPin: slice));
  }

  void logout() {
    _cancelTimers();
    _emit(FleetAppSnapshot.initial());
  }
}
