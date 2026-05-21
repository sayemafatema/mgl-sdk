import 'dart:async';

import 'package:flutter/foundation.dart';

import 'driver_app_http.dart';
import 'fleet_bindings_mapper.dart';
import 'fleet_config.dart';
import 'fleet_driver_validation.dart';
import 'fleet_sdk_payload.dart';
import 'fleet_demo_data.dart';
import 'fleet_live_models.dart';
import 'fleetpay_qr.dart';
import 'react_parity_strings.dart';

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
    required this.sessionOtp,
    required this.pairingDigits,
    required this.pairingError,
    required this.pairingAttempts,
    required this.selectedScanBindingId,
    required this.bindings,
    required this.transactions,
    required this.pendingPairingCode,
    required this.useLiveDriverApp,
    required this.otpCountdown,
    required this.scanOtpCountdown,
    required this.apiBanner,
    required this.otpPhaseToken,
    required this.foScopedToken,
    required this.foOrganizations,
    required this.selectedFoCompanyId,
    required this.inviteOtpRef,
    required this.inviteMobileVerificationToken,
    required this.inviteSessionToken,
    required this.invitePreviewDriver,
    required this.invitePreviewFo,
    required this.onboardingBusy,
    required this.fleetPinFoDisplay,
    this.parsedScanQr,
    required this.qrPayBusy,
    this.lastQrPay,
    required this.foPinSubStep,
    required this.forgotFleetPinPhase,
    required this.forgotFleetPinFirst,
    required this.forgotFleetPinSecond,
    required this.forgotFleetPinError,
    required this.profilePinModalOpen,
    required this.profileChangePinPhase,
    required this.profileChangePinFirst,
    required this.profileChangePinSecond,
    required this.profileChangePinError,
    required this.profilePinChanging,
    required this.persistedFoCompanyId,
    this.overlayAssignmentId,
    required this.profileFoName,
    required this.profileDlNumber,
    required this.profileRegistered,
    required this.pairingSuccess,
    this.declineConfirmBindingId,
    required this.loginOtpRefocusKey,
    required this.inviteOtpRefocusKey,
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
  final String sessionOtp;
  final List<String> pairingDigits;
  final String pairingError;
  final int pairingAttempts;
  final String? selectedScanBindingId;
  final List<FleetBinding> bindings;
  final List<FleetTransaction> transactions;
  final String pendingPairingCode;

  /// When true, auth uses [DriverAppHttp] against [FleetConfig.apiBaseUrl].
  final bool useLiveDriverApp;
  final int otpCountdown;
  final int scanOtpCountdown;
  final String? apiBanner;
  final String? otpPhaseToken;
  final String? foScopedToken;
  final List<FoOrganization> foOrganizations;
  final int? selectedFoCompanyId;
  final String? inviteOtpRef;
  final String? inviteMobileVerificationToken;
  final String? inviteSessionToken;
  final String? invitePreviewDriver;
  final String? invitePreviewFo;
  final bool onboardingBusy;
  final String fleetPinFoDisplay;
  final ParsedFleetpayQr? parsedScanQr;
  final bool qrPayBusy;
  final QrPayResultLive? lastQrPay;
  final String foPinSubStep;
  final String forgotFleetPinPhase;
  final String forgotFleetPinFirst;
  final String forgotFleetPinSecond;
  final String forgotFleetPinError;
  final bool profilePinModalOpen;
  final String profileChangePinPhase;
  final String profileChangePinFirst;
  final String profileChangePinSecond;
  final String profileChangePinError;
  final bool profilePinChanging;
  final int? persistedFoCompanyId;
  final String? overlayAssignmentId;
  final String profileFoName;
  final String profileDlNumber;
  final String profileRegistered;
  final bool pairingSuccess;
  final String? declineConfirmBindingId;
  final int loginOtpRefocusKey;
  final int inviteOtpRefocusKey;

  bool get canForgotFleetPin =>
      useLiveDriverApp &&
      selectedFoCompanyId != null &&
      (otpPhaseToken?.isNotEmpty ?? false);

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
    Object? sessionOtp = _kUnset,
    Object? pairingDigits = _kUnset,
    Object? pairingError = _kUnset,
    Object? pairingAttempts = _kUnset,
    Object? selectedScanBindingId = _kUnset,
    Object? bindings = _kUnset,
    Object? transactions = _kUnset,
    Object? pendingPairingCode = _kUnset,
    Object? useLiveDriverApp = _kUnset,
    Object? otpCountdown = _kUnset,
    Object? scanOtpCountdown = _kUnset,
    Object? apiBanner = _kUnset,
    Object? otpPhaseToken = _kUnset,
    Object? foScopedToken = _kUnset,
    Object? foOrganizations = _kUnset,
    Object? selectedFoCompanyId = _kUnset,
    Object? inviteOtpRef = _kUnset,
    Object? inviteMobileVerificationToken = _kUnset,
    Object? inviteSessionToken = _kUnset,
    Object? invitePreviewDriver = _kUnset,
    Object? invitePreviewFo = _kUnset,
    Object? onboardingBusy = _kUnset,
    Object? fleetPinFoDisplay = _kUnset,
    Object? parsedScanQr = _kUnset,
    Object? qrPayBusy = _kUnset,
    Object? lastQrPay = _kUnset,
    Object? foPinSubStep = _kUnset,
    Object? forgotFleetPinPhase = _kUnset,
    Object? forgotFleetPinFirst = _kUnset,
    Object? forgotFleetPinSecond = _kUnset,
    Object? forgotFleetPinError = _kUnset,
    Object? profilePinModalOpen = _kUnset,
    Object? profileChangePinPhase = _kUnset,
    Object? profileChangePinFirst = _kUnset,
    Object? profileChangePinSecond = _kUnset,
    Object? profileChangePinError = _kUnset,
    Object? profilePinChanging = _kUnset,
    Object? persistedFoCompanyId = _kUnset,
    Object? overlayAssignmentId = _kUnset,
    Object? profileFoName = _kUnset,
    Object? profileDlNumber = _kUnset,
    Object? profileRegistered = _kUnset,
    Object? pairingSuccess = _kUnset,
    Object? declineConfirmBindingId = _kUnset,
    Object? loginOtpRefocusKey = _kUnset,
    Object? inviteOtpRefocusKey = _kUnset,
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
      sessionOtp: pick(sessionOtp, this.sessionOtp),
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
      useLiveDriverApp: pick(useLiveDriverApp, this.useLiveDriverApp),
      otpCountdown: pick(otpCountdown, this.otpCountdown),
      scanOtpCountdown: pick(scanOtpCountdown, this.scanOtpCountdown),
      apiBanner: pick(apiBanner, this.apiBanner),
      otpPhaseToken: pick(otpPhaseToken, this.otpPhaseToken),
      foScopedToken: pick(foScopedToken, this.foScopedToken),
      foOrganizations: pick(foOrganizations,
          List<FoOrganization>.from(this.foOrganizations)),
      selectedFoCompanyId:
          pick(selectedFoCompanyId, this.selectedFoCompanyId),
      inviteOtpRef: pick(inviteOtpRef, this.inviteOtpRef),
      inviteMobileVerificationToken:
          pick(inviteMobileVerificationToken, this.inviteMobileVerificationToken),
      inviteSessionToken: pick(inviteSessionToken, this.inviteSessionToken),
      invitePreviewDriver: pick(invitePreviewDriver, this.invitePreviewDriver),
      invitePreviewFo: pick(invitePreviewFo, this.invitePreviewFo),
      onboardingBusy: pick(onboardingBusy, this.onboardingBusy),
      fleetPinFoDisplay: pick(fleetPinFoDisplay, this.fleetPinFoDisplay),
      parsedScanQr: identical(parsedScanQr, _kUnset)
          ? this.parsedScanQr
          : parsedScanQr as ParsedFleetpayQr?,
      qrPayBusy: pick(qrPayBusy, this.qrPayBusy),
      lastQrPay: identical(lastQrPay, _kUnset)
          ? this.lastQrPay
          : lastQrPay as QrPayResultLive?,
      foPinSubStep: pick(foPinSubStep, this.foPinSubStep),
      forgotFleetPinPhase: pick(forgotFleetPinPhase, this.forgotFleetPinPhase),
      forgotFleetPinFirst: pick(forgotFleetPinFirst, this.forgotFleetPinFirst),
      forgotFleetPinSecond: pick(forgotFleetPinSecond, this.forgotFleetPinSecond),
      forgotFleetPinError: pick(forgotFleetPinError, this.forgotFleetPinError),
      profilePinModalOpen: pick(profilePinModalOpen, this.profilePinModalOpen),
      profileChangePinPhase: pick(profileChangePinPhase, this.profileChangePinPhase),
      profileChangePinFirst: pick(profileChangePinFirst, this.profileChangePinFirst),
      profileChangePinSecond: pick(profileChangePinSecond, this.profileChangePinSecond),
      profileChangePinError: pick(profileChangePinError, this.profileChangePinError),
      profilePinChanging: pick(profilePinChanging, this.profilePinChanging),
      persistedFoCompanyId:
          pick(persistedFoCompanyId, this.persistedFoCompanyId),
      overlayAssignmentId: identical(overlayAssignmentId, _kUnset)
          ? this.overlayAssignmentId
          : overlayAssignmentId as String?,
      profileFoName: pick(profileFoName, this.profileFoName),
      profileDlNumber: pick(profileDlNumber, this.profileDlNumber),
      profileRegistered: pick(profileRegistered, this.profileRegistered),
      pairingSuccess: pick(pairingSuccess, this.pairingSuccess),
      declineConfirmBindingId: identical(declineConfirmBindingId, _kUnset)
          ? this.declineConfirmBindingId
          : declineConfirmBindingId as String?,
      loginOtpRefocusKey: pick(loginOtpRefocusKey, this.loginOtpRefocusKey),
      inviteOtpRefocusKey: pick(inviteOtpRefocusKey, this.inviteOtpRefocusKey),
    );
  }

  factory FleetAppSnapshot.initial({
    bool useLive = false,
    int? persistedFoCompanyId,
    String? authStep,
    String? foScopedToken,
  }) {
    return FleetAppSnapshot(
      authStep: authStep ?? 'login',
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
      sessionOtp: '',
      pairingDigits: _cloneOtpSlots(),
      pairingError: '',
      pairingAttempts: 0,
      selectedScanBindingId: null,
      bindings: _cloneBindings(),
      transactions: mockTransactions.map((t) => t.copy()).toList(),
      pendingPairingCode: '234567',
      useLiveDriverApp: useLive,
      otpCountdown: 0,
      scanOtpCountdown: 0,
      apiBanner: null,
      otpPhaseToken: null,
      foScopedToken: foScopedToken,
      foOrganizations: [],
      selectedFoCompanyId: null,
      inviteOtpRef: null,
      inviteMobileVerificationToken: null,
      inviteSessionToken: null,
      invitePreviewDriver: null,
      invitePreviewFo: null,
      onboardingBusy: false,
      fleetPinFoDisplay: '',
      parsedScanQr: null,
      qrPayBusy: false,
      lastQrPay: null,
      foPinSubStep: 'enter',
      forgotFleetPinPhase: 'first',
      forgotFleetPinFirst: '',
      forgotFleetPinSecond: '',
      forgotFleetPinError: '',
      profilePinModalOpen: false,
      profileChangePinPhase: 'first',
      profileChangePinFirst: '',
      profileChangePinSecond: '',
      profileChangePinError: '',
      profilePinChanging: false,
      persistedFoCompanyId: persistedFoCompanyId,
      overlayAssignmentId: null,
      profileFoName: '',
      profileDlNumber: '',
      profileRegistered: '',
      pairingSuccess: false,
      declineConfirmBindingId: null,
      loginOtpRefocusKey: 0,
      inviteOtpRefocusKey: 0,
    );
  }
}

class FleetAppEngine extends ChangeNotifier {
  FleetAppEngine({FleetConfig? config})
      : _config = config ?? const FleetConfig(),
        _s = _initialSnapshot(config ?? const FleetConfig()) {
    if (_live) {
      _http = DriverAppHttp(apiBaseUrl: _config.apiBaseUrl.trim());
      _countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
      if (_s.authStep == 'complete' && (_s.foScopedToken?.isNotEmpty ?? false)) {
        Future.microtask(refreshLiveFleetData);
      }
    }
  }

  static FleetAppSnapshot _initialSnapshot(FleetConfig config) {
    final live = _inferLive(config);
    final token = !config.useMock ? config.authToken?.trim() : null;
    final warm = token != null && token.isNotEmpty;
    return FleetAppSnapshot.initial(
      useLive: live,
      persistedFoCompanyId: config.foCompanyId,
      authStep: warm ? 'complete' : null,
      foScopedToken: warm ? token : null,
    );
  }

  bool get showLoginMobileFormatError =>
      _s.mobileNumber.isNotEmpty && !validIndianMobile10(_s.mobileNumber);

  static bool _inferLive(FleetConfig c) =>
      !c.useMock && c.apiBaseUrl.trim().isNotEmpty;

  final FleetConfig _config;
  DriverAppHttp? _http;
  Timer? _countdownTimer;

  bool get _live => _s.useLiveDriverApp;

  FleetAppSnapshot _s;
  final List<Timer> _timers = [];

  FleetAppSnapshot getSnapshot() => _s;

  int? get _effectiveFoCompanyId =>
      _s.selectedFoCompanyId ?? _s.persistedFoCompanyId ?? _config.foCompanyId;

  FleetBinding? _bindingById(String? id) {
    if (id == null) return null;
    for (final b in _s.bindings) {
      if (b.id == id) return b;
    }
    return null;
  }

  void _tickCountdown() {
    final o = _s.otpCountdown;
    final sc = _s.scanOtpCountdown;
    if (o <= 0 && sc <= 0) return;
    _emit(_s.copy(
      otpCountdown: o > 0 ? o - 1 : 0,
      scanOtpCountdown: sc > 0 ? sc - 1 : 0,
    ));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
    var n = next;
    if (n.apiBanner != null) {
      n = n.copy(successToast: null);
    } else if (n.successToast != null) {
      n = n.copy(apiBanner: null);
    }
    final prevBanner = _s.apiBanner;
    final prevToast = _s.successToast;
    _s = n;
    notifyListeners();
    if (n.apiBanner != null && n.apiBanner != prevBanner) {
      _later(const Duration(seconds: 5), () {
        if (_s.apiBanner == n.apiBanner) dismissApiBanner();
      });
    }
    if (n.successToast != null && n.successToast != prevToast) {
      _later(const Duration(seconds: 5), () {
        if (_s.successToast == n.successToast) {
          _emit(_s.copy(successToast: null));
        }
      });
    }
  }

  static const userCancelledPayload = FleetSdkSuccessPayload(
    event: 'USER_CANCELLED',
    payload: {'code': '1003', 'message': 'Back closed flow.'},
  );

  static const logoutPayload = FleetSdkSuccessPayload(
    event: 'FLEET_FLOW_COMPLETED',
    payload: {'reason': 'logout'},
  );

  void _notifyFlowComplete(FleetSdkSuccessPayload payload) {
    _config.onFlowComplete?.call(payload);
  }

  void skipToMainApp() {
    _emit(_s.copy(
      authStep: 'complete',
      mainOverlay: 'home',
      activeTab: 'card',
      loginPin: '',
      sessionOtp: '',
      otpDigitsLogin: _cloneOtpSlots(),
      apiBanner: null,
      fleetPinFoDisplay: '',
      parsedScanQr: null,
      qrPayBusy: false,
      lastQrPay: null,
    ));
    if (_live) Future.microtask(refreshLiveFleetData);
  }

  void dismissApiBanner() {
    if (_s.apiBanner != null) {
      _emit(_s.copy(apiBanner: null));
    }
  }

  void setMobileNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final slice =
        digits.length <= 10 ? digits : digits.substring(0, 10);
    _emit(_s.copy(mobileNumber: slice, apiBanner: null));
  }

  Future<void> loginSendOtp() async {
    if (!validIndianMobile10(_s.mobileNumber)) return;
    if (!_live) {
      _emit(_s.copy(
        authStep: 'login_otp',
        otpDigitsLogin: _cloneOtpSlots(),
        otpErrorLogin: '',
        otpCountdown: 30,
      ));
      return;
    }
    _emit(_s.copy(
      apiBanner: null,
      onboardingBusy: true,
      otpErrorLogin: '',
    ));
    try {
      final cm = await _http!.driverCheckMobile(_s.mobileNumber);
      if (cm == 'NEW_USER') {
        _emit(_s.copy(
          authStep: '1c',
          apiBanner: ReactParityStrings.newUserContinueInvite,
          mobileNumber: '',
          inviteOtp: '',
          inviteCode: '',
          onboardingBusy: false,
        ));
        return;
      }
      await _http!.driverSendLoginOtp(_s.mobileNumber);
      _emit(_s.copy(
        authStep: 'login_otp',
        otpDigitsLogin: _cloneOtpSlots(),
        otpErrorLogin: '',
        otpCountdown: 60,
        onboardingBusy: false,
      ));
    } catch (e) {
      _emit(_s.copy(
        apiBanner: ReactParityStrings.forGenericFailure(e),
        onboardingBusy: false,
      ));
    }
  }

  Future<void> resendLoginOtp() async {
    if (_s.otpCountdown > 0) return;
    if (!_live) {
      _emit(_s.copy(otpCountdown: 30));
      return;
    }
    try {
      await _http!.driverSendLoginOtp(_s.mobileNumber);
      _emit(_s.copy(otpCountdown: 60, apiBanner: null));
    } catch (e) {
      _emit(_s.copy(apiBanner: ReactParityStrings.forGenericFailure(e)));
    }
  }

  void setLoginOtpDigit(int index, String digit) {
    final d = digit.replaceAll(RegExp(r'\D'), '');
    final ch = d.isEmpty ? '' : d.substring(d.length - 1);
    final next = List<String>.from(_s.otpDigitsLogin);
    next[index] = ch;
    _emit(_s.copy(otpDigitsLogin: next));
    if (next.join().length == 6) {
      if (_live) {
        Future.microtask(_verifyLoginOtpLive);
      } else {
        verifyLoginOtp();
      }
    }
  }

  void verifyLoginOtp() {
    final entered = _s.otpDigitsLogin.join();
    if (entered != _demoOtp) {
      _emit(_s.copy(
        otpErrorLogin: 'Incorrect OTP. Try again.',
        otpDigitsLogin: _cloneOtpSlots(),
        loginOtpRefocusKey: _s.loginOtpRefocusKey + 1,
      ));
      return;
    }
    if (!_s.isNewUser) {
      _emit(_s.copy(
        authStep: 'complete',
        loginPin: '',
        loginPinError: '',
        otpErrorLogin: '',
        otpCountdown: 0,
        otpDigitsLogin: _cloneOtpSlots(),
      ));
      return;
    }
    _emit(_s.copy(
      authStep: 'set_pin',
      newPin: '',
      pinConfirm: '',
      pinError: '',
      otpErrorLogin: '',
      otpCountdown: 0,
      otpDigitsLogin: _cloneOtpSlots(),
    ));
  }

  Future<void> _verifyLoginOtpLive() async {
    final entered = _s.otpDigitsLogin.join();
    if (entered.length != 6 || _http == null) return;
    _emit(_s.copy(onboardingBusy: true, otpErrorLogin: '', apiBanner: null));
    try {
      final partial = await _http!.driverOauthOtpGrant(_s.mobileNumber, entered);
      final fos = await _http!.driverFoList(partial);
      final active =
          fos.where((f) => f.foStatus.toUpperCase() == 'ACTIVE').toList();
      if (active.isEmpty) {
        _emit(_s.copy(
          otpPhaseToken: null,
          otpDigitsLogin: _cloneOtpSlots(),
          apiBanner: ReactParityStrings.noActiveFleet,
          onboardingBusy: false,
        ));
        return;
      }
      if (active.length == 1) {
        _emit(_s.copy(
          otpPhaseToken: partial,
          selectedFoCompanyId: active.first.foCompanyId,
          authStep: 'fo_pin_login',
          loginPin: '',
          otpDigitsLogin: _cloneOtpSlots(),
          otpCountdown: 0,
          onboardingBusy: false,
        ));
      } else {
        _emit(_s.copy(
          otpPhaseToken: partial,
          foOrganizations: fos,
          selectedFoCompanyId: null,
          authStep: 'select_fo',
          loginPin: '',
          otpDigitsLogin: _cloneOtpSlots(),
          otpCountdown: 0,
          onboardingBusy: false,
        ));
      }
    } catch (e) {
      _emit(_s.copy(
        otpDigitsLogin: _cloneOtpSlots(),
        loginOtpRefocusKey: _s.loginOtpRefocusKey + 1,
        apiBanner: ReactParityStrings.forGenericFailure(e),
        onboardingBusy: false,
      ));
    }
  }

  void selectFoOrganization(int foCompanyId) {
    var name = '';
    for (final f in _s.foOrganizations) {
      if (f.foCompanyId == foCompanyId) {
        name = f.foName;
        break;
      }
    }
    _emit(_s.copy(
      selectedFoCompanyId: foCompanyId,
      authStep: 'fo_pin_login',
      loginPin: '',
      fleetPinFoDisplay: name,
    ));
  }

  Future<void> submitFoUnlock() async {
    if (!_live || _http == null) return;
    final phase = _s.otpPhaseToken;
    final id = _s.selectedFoCompanyId;
    final pin = _s.loginPin;
    if (phase == null || id == null || pin.length != 6) return;
    _emit(_s.copy(onboardingBusy: true, apiBanner: null));
    try {
      final tok = await _http!.driverFoSelect(
        bearerPartial: phase,
        foCompanyId: id,
        pin: pin,
      );
      var foDisp = _s.fleetPinFoDisplay;
      if (foDisp.isEmpty) {
        for (final f in _s.foOrganizations) {
          if (f.foCompanyId == id) {
            foDisp = f.foName;
            break;
          }
        }
      }
      _emit(_s.copy(
        foScopedToken: tok,
        otpPhaseToken: null,
        authStep: 'complete',
        loginPin: '',
        fleetPinFoDisplay: foDisp,
        persistedFoCompanyId: id,
        onboardingBusy: false,
      ));
      await refreshLiveFleetData();
    } catch (e) {
      _emit(_s.copy(
        loginPin: '',
        apiBanner: ReactParityStrings.forPinFailure(e),
        onboardingBusy: false,
      ));
    }
  }

  void loginPinAppend(String digit) {
    if (_s.disableLoginNumpad || _s.onboardingBusy || _s.loginPin.length >= 6) {
      return;
    }
    _emit(_s.copy(loginPin: _s.loginPin + digit, loginPinError: ''));
  }

  Future<void> unlockApp() async {
    if (_s.loginPin.length != 6 || _s.onboardingBusy) return;
    if (_live) {
      await submitFoUnlock();
    } else {
      _submitLoginPin(_s.loginPin);
    }
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
      foPinSubStep: 'forgot',
      forgotFleetPinPhase: 'first',
      forgotFleetPinFirst: '',
      forgotFleetPinSecond: '',
      forgotFleetPinError: '',
      loginPin: '',
      loginPinError: '',
    ));
  }

  void cancelForgotPin() {
    _emit(_s.copy(
      foPinSubStep: 'enter',
      forgotFleetPinPhase: 'first',
      forgotFleetPinFirst: '',
      forgotFleetPinSecond: '',
      forgotFleetPinError: '',
      loginPin: '',
    ));
  }

  void forgotFleetPinAppend(String digit) {
    if (_s.forgotFleetPinPhase == 'first') {
      if (_s.forgotFleetPinFirst.length >= 6) return;
      _emit(_s.copy(
        forgotFleetPinFirst: _s.forgotFleetPinFirst + digit,
        forgotFleetPinError: '',
      ));
    } else {
      if (_s.forgotFleetPinSecond.length >= 6) return;
      _emit(_s.copy(
        forgotFleetPinSecond: _s.forgotFleetPinSecond + digit,
        forgotFleetPinError: '',
      ));
    }
  }

  void forgotFleetPinBackspace() {
    if (_s.forgotFleetPinPhase == 'first') {
      if (_s.forgotFleetPinFirst.isEmpty) return;
      _emit(_s.copy(
        forgotFleetPinFirst:
            _s.forgotFleetPinFirst.substring(0, _s.forgotFleetPinFirst.length - 1),
      ));
    } else {
      if (_s.forgotFleetPinSecond.isEmpty) return;
      _emit(_s.copy(
        forgotFleetPinSecond: _s.forgotFleetPinSecond
            .substring(0, _s.forgotFleetPinSecond.length - 1),
      ));
    }
  }

  Future<void> submitForgotFleetPinStep() async {
    if (_s.foPinSubStep != 'forgot') return;
    if (_s.forgotFleetPinPhase == 'first') {
      if (_s.forgotFleetPinFirst.length != 6) return;
      _emit(_s.copy(
        forgotFleetPinPhase: 'second',
        forgotFleetPinSecond: '',
        forgotFleetPinError: '',
      ));
      return;
    }
    if (_s.forgotFleetPinSecond.length != 6) return;
    if (_s.forgotFleetPinSecond != _s.forgotFleetPinFirst) {
      _emit(_s.copy(
        forgotFleetPinError: ReactParityStrings.pinsDidntMatchConfirm,
        forgotFleetPinSecond: '',
      ));
      return;
    }
    final foId = _effectiveFoCompanyId;
    if (_live && _http != null && foId != null) {
      final phase = _s.otpPhaseToken;
      if (phase == null || phase.isEmpty) {
        _emit(_s.copy(apiBanner: ReactParityStrings.inviteIncompleteMobile));
        return;
      }
      _emit(_s.copy(onboardingBusy: true, forgotFleetPinError: ''));
      try {
        await _http!.driverPinReset(
          bearerPartial: phase,
          foCompanyId: foId,
          newPin: _s.forgotFleetPinSecond,
        );
        _emit(_s.copy(
          authStep: 'login',
          foPinSubStep: 'enter',
          otpPhaseToken: null,
          foScopedToken: null,
          foOrganizations: [],
          selectedFoCompanyId: null,
          persistedFoCompanyId: null,
          fleetPinFoDisplay: '',
          loginPin: '',
          mobileNumber: _s.mobileNumber,
          forgotFleetPinPhase: 'first',
          forgotFleetPinFirst: '',
          forgotFleetPinSecond: '',
          successToast:
              'PIN changed successfully. Tap Send OTP and sign in with your new PIN.',
          onboardingBusy: false,
        ));
      } catch (e) {
        _emit(_s.copy(
          forgotFleetPinSecond: '',
          apiBanner: ReactParityStrings.forPinFailure(e),
          onboardingBusy: false,
        ));
      }
      return;
    }
    _emit(_s.copy(
      foPinSubStep: 'enter',
      forgotFleetPinPhase: 'first',
      forgotFleetPinFirst: '',
      forgotFleetPinSecond: '',
      successToast: 'PIN updated successfully',
    ));
  }

  void openProfileChangePin() {
    _emit(_s.copy(
      profilePinModalOpen: true,
      profileChangePinPhase: 'first',
      profileChangePinFirst: '',
      profileChangePinSecond: '',
      profileChangePinError: '',
      apiBanner: null,
    ));
  }

  void closeProfileChangePin() {
    _emit(_s.copy(
      profilePinModalOpen: false,
      profileChangePinPhase: 'first',
      profileChangePinFirst: '',
      profileChangePinSecond: '',
      profileChangePinError: '',
    ));
  }

  void profileChangePinAppend(String digit) {
    if (_s.profileChangePinPhase == 'first') {
      if (_s.profileChangePinFirst.length >= 6) return;
      _emit(_s.copy(
        profileChangePinFirst: _s.profileChangePinFirst + digit,
        profileChangePinError: '',
      ));
    } else {
      if (_s.profileChangePinSecond.length >= 6) return;
      _emit(_s.copy(
        profileChangePinSecond: _s.profileChangePinSecond + digit,
        profileChangePinError: '',
      ));
    }
  }

  void profileChangePinBackspace() {
    if (_s.profileChangePinPhase == 'first') {
      if (_s.profileChangePinFirst.isEmpty) return;
      _emit(_s.copy(
        profileChangePinFirst: _s.profileChangePinFirst
            .substring(0, _s.profileChangePinFirst.length - 1),
      ));
    } else {
      if (_s.profileChangePinSecond.isEmpty) return;
      _emit(_s.copy(
        profileChangePinSecond: _s.profileChangePinSecond
            .substring(0, _s.profileChangePinSecond.length - 1),
      ));
    }
  }

  Future<void> submitProfileChangePinStep() async {
    if (!_s.profilePinModalOpen) return;
    if (_s.profileChangePinPhase == 'first') {
      if (_s.profileChangePinFirst.length != 6) return;
      _emit(_s.copy(
        profileChangePinPhase: 'second',
        profileChangePinSecond: '',
        profileChangePinError: '',
      ));
      return;
    }
    if (_s.profileChangePinSecond.length != 6) return;
    if (_s.profileChangePinSecond != _s.profileChangePinFirst) {
      _emit(_s.copy(
        profileChangePinError: ReactParityStrings.pinsDidntMatchConfirm,
        profileChangePinSecond: '',
        profileChangePinPhase: 'first',
        profileChangePinFirst: '',
      ));
      return;
    }
    final tok = _s.foScopedToken;
    final foId = _effectiveFoCompanyId;
    if (_live && _http != null && tok != null && foId != null) {
      _emit(_s.copy(profilePinChanging: true, profileChangePinError: ''));
      try {
        await _http!.driverPinReset(
          bearerPartial: tok,
          foCompanyId: foId,
          newPin: _s.profileChangePinSecond,
        );
        closeProfileChangePin();
        _emit(_s.copy(
          successToast: 'PIN updated successfully',
          profilePinChanging: false,
        ));
      } catch (e) {
        _emit(_s.copy(
          profileChangePinSecond: '',
          profileChangePinError: ReactParityStrings.forPinFailure(e),
          profilePinChanging: false,
        ));
      }
      return;
    }
    closeProfileChangePin();
    _emit(_s.copy(successToast: 'PIN updated successfully'));
  }

  bool canChangeProfilePin() =>
      _s.authStep == 'complete' &&
      (!_live || (_s.foScopedToken != null && _effectiveFoCompanyId != null));

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
        pinError: ReactParityStrings.pinsDidntMatchConfirm,
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
        authStep: 'fo_pin_login',
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
      _emit(_s.copy(
        authStep: 'login',
        otpCountdown: 0,
        otpDigitsLogin: _cloneOtpSlots(),
      ));
    } else if (step == 'select_fo') {
      _emit(_s.copy(
        authStep: 'login_otp',
        otpPhaseToken: null,
        foOrganizations: [],
      ));
    } else if (step == 'fo_pin_login') {
      if (_s.foPinSubStep == 'forgot') {
        cancelForgotPin();
        return;
      }
      _emit(_s.copy(
        loginPin: '',
        authStep: _s.foOrganizations.length > 1 ? 'select_fo' : 'login_otp',
        otpPhaseToken: _s.foOrganizations.length > 1 ? _s.otpPhaseToken : null,
      ));
    } else if (step == '1b') {
      _emit(_s.copy(authStep: _live ? '1d' : 'login'));
    } else if (step == '1c') {
      _emit(_s.copy(authStep: 'login'));
    } else if (step == '1d') {
      _emit(_s.copy(authStep: '1c'));
    } else if (step == 'forgot_otp') {
      _emit(_s.copy(authStep: 'forgot_pin'));
    } else if (step == 'forgot_pin') {
      _emit(_s.copy(authStep: 'fo_pin_login', inviteOtp: ''));
    }
  }

  Future<void> inviteSendOtpFromMobileScreen() async {
    if (!validIndianMobile10(_s.mobileNumber)) return;
    if (!_live) {
      inviteSendOtp();
      return;
    }
    _emit(_s.copy(onboardingBusy: true, apiBanner: null));
    try {
      final cm = await _http!.driverCheckMobile(_s.mobileNumber);
      if (cm != 'NEW_USER') {
        _emit(_s.copy(
          apiBanner: ReactParityStrings.useSendOtpLogin,
          onboardingBusy: false,
        ));
        return;
      }
      final ref = await _http!.driverInviteMobileSendOtp(_s.mobileNumber);
      _emit(_s.copy(
        inviteOtpRef: ref,
        authStep: '1d',
        inviteOtp: '',
        otpCountdown: 60,
        onboardingBusy: false,
      ));
    } catch (e) {
      _emit(_s.copy(apiBanner: ReactParityStrings.forGenericFailure(e), onboardingBusy: false));
    }
  }

  Future<void> resendInviteOtp() async {
    if (_s.otpCountdown > 0) return;
    if (!_live) {
      _emit(_s.copy(otpCountdown: 30));
      return;
    }
    try {
      final ref = await _http!.driverInviteMobileSendOtp(_s.mobileNumber);
      _emit(_s.copy(
        inviteOtpRef: ref,
        otpCountdown: 60,
        apiBanner: null,
      ));
    } catch (e) {
      _emit(_s.copy(apiBanner: ReactParityStrings.forGenericFailure(e)));
    }
  }

  void goInviteSignup() {
    _emit(_s.copy(
      authStep: _live ? '1c' : '1b',
      mobileNumber: _live ? '' : _s.mobileNumber,
      inviteOtp: '',
      inviteCode: '',
      inviteOtpRef: null,
      inviteMobileVerificationToken: null,
      apiBanner: null,
    ));
  }

  void setInviteCode(String raw) {
    final upper = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final slice =
        upper.length <= 24 ? upper : upper.substring(0, 24);
    _emit(_s.copy(inviteCode: slice));
  }

  Future<void> inviteContinue() async {
    final code = _s.inviteCode;
    if (code.length < 6) return;
    if (!_live) {
      if (mockInviteCompanies[code] == null) return;
      _emit(_s.copy(
        authStep: '1e',
        invitePin: '',
        invitePinConfirm: '',
        pinError: '',
      ));
      return;
    }
    final tok = _s.inviteMobileVerificationToken;
    if (tok == null || tok.isEmpty) {
      _emit(_s.copy(apiBanner: ReactParityStrings.inviteIncompleteMobile));
      return;
    }
    _emit(_s.copy(onboardingBusy: true, apiBanner: null));
    try {
      final v = await _http!.driverInviteValidate(
        mobile: _s.mobileNumber,
        inviteCode: code,
        mobileVerificationToken: tok,
      );
      _emit(_s.copy(
        inviteSessionToken: v.sessionToken,
        invitePreviewDriver: v.driverName,
        invitePreviewFo: v.foName,
        fleetPinFoDisplay: v.foName.trim(),
        persistedFoCompanyId:
            v.foCompanyId > 0 ? v.foCompanyId : _s.persistedFoCompanyId,
        authStep: '1e',
        invitePin: '',
        invitePinConfirm: '',
        pinError: '',
        onboardingBusy: false,
      ));
    } catch (e) {
      _emit(_s.copy(apiBanner: ReactParityStrings.forGenericFailure(e), onboardingBusy: false));
    }
  }

  void inviteSendOtp() {
    if (_s.mobileNumber.length != 10) return;
    _emit(_s.copy(authStep: '1d', inviteOtp: '', otpCountdown: 30));
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
      if (_live) {
        Future.microtask(_verifyInviteOtpLive);
      } else {
        verifyInviteOtp();
      }
    }
  }

  void verifyInviteOtp() {
    if (_s.inviteOtp != _demoOtp) return;
    _emit(_s.copy(
      authStep: '1b',
      inviteCode: '',
    ));
  }

  Future<void> _verifyInviteOtpLive() async {
    final otp = _s.inviteOtp;
    final ref = _s.inviteOtpRef;
    if (ref == null || otp.length != 6 || _http == null) return;
    _emit(_s.copy(onboardingBusy: true));
    try {
      final t = await _http!.driverInviteMobileVerifyOtp(
        mobile: _s.mobileNumber,
        otpRefNumber: ref,
        otp: otp,
      );
      _emit(_s.copy(
        inviteMobileVerificationToken: t,
        authStep: '1b',
        inviteCode: '',
        inviteOtp: '',
        onboardingBusy: false,
      ));
    } catch (e) {
      _emit(_s.copy(apiBanner: ReactParityStrings.forGenericFailure(e), onboardingBusy: false));
    }
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
      authStep: '1f',
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

  Future<void> inviteConfirmSubmit() async {
    if (_s.invitePinConfirm.length != 6) return;
    if (_s.invitePin != _s.invitePinConfirm) {
      _emit(_s.copy(
        pinError: ReactParityStrings.pinsDontMatch1f,
        invitePinConfirm: '',
      ));
      return;
    }
    if (!_live) {
      _emit(_s.copy(
        authStep: 'complete',
        pinError: '',
        isNewUser: true,
      ));
      return;
    }
    final sess = _s.inviteSessionToken;
    if (sess == null || sess.isEmpty) {
      _emit(_s.copy(apiBanner: ReactParityStrings.sessionMissingInvite));
      return;
    }
    _emit(_s.copy(onboardingBusy: true, apiBanner: null));
    try {
      final tok =
          await _http!.driverInviteSetPin(sess, _s.invitePin);
      final foDisp = (_s.invitePreviewFo ?? '').trim();
      _emit(_s.copy(
        foScopedToken: tok,
        authStep: 'complete',
        pinError: '',
        isNewUser: true,
        inviteSessionToken: null,
        invitePin: '',
        invitePinConfirm: '',
        fleetPinFoDisplay: foDisp.isNotEmpty ? foDisp : _s.fleetPinFoDisplay,
        persistedFoCompanyId: _s.persistedFoCompanyId ?? _effectiveFoCompanyId,
        onboardingBusy: false,
      ));
      await refreshLiveFleetData();
    } catch (e) {
      _emit(_s.copy(
        apiBanner: ReactParityStrings.forPinFailure(e),
        invitePinConfirm: '',
        onboardingBusy: false,
      ));
    }
  }

  void setTab(String tab) {
    var sel = _s.selectedScanBindingId;
    if (tab == 'scan') {
      final avail = scanAvailableBindings();
      if (avail.isNotEmpty && sel == null) {
        sel = avail.first.id;
      }
    }
       final wasComplete = _s.authStep == 'complete';
    _emit(_s.copy(activeTab: tab, selectedScanBindingId: sel));
    if (_live &&
        wasComplete &&
        (tab == 'card' || tab == 'assignments' || tab == 'transactions')) {
      Future.microtask(refreshLiveFleetData);
    }
  }

  void setMainOverlay(String o) {
    _emit(_s.copy(
      mainOverlay: o,
      overlayAssignmentId: o == 'home' ? null : _s.overlayAssignmentId,
      pairingSuccess: o == 'pairing_code' ? _s.pairingSuccess : false,
    ));
  }

  /// Android/iOS `BackHandler` parity. Returns `true` if back was consumed.
  bool handleBack() {
    if (_s.authStep != 'complete') {
      if (_s.authStep == 'login') return false;
      authBack();
      return true;
    }
    if (_s.profilePinModalOpen) {
      closeProfileChangePin();
      return true;
    }
    if (_s.declineConfirmBindingId != null) {
      cancelDeclineConfirm();
      return true;
    }
    if (_s.mainOverlay == 'assignment_accepted') {
      _emit(_s.copy(mainOverlay: 'home', overlayAssignmentId: null));
      return true;
    }
    if (_s.mainOverlay == 'pairing_code') {
      pairingBackFromOverlay();
      return true;
    }
    if (_s.mainOverlay == 'assignment_notification') {
      _emit(_s.copy(mainOverlay: 'home', overlayAssignmentId: null));
      return true;
    }
    if (_s.sessionState != 'idle') {
      switch (_s.sessionState) {
        case 'confirmation':
          scanCancelConfirmation();
          return true;
        case 'pin_confirm':
          scanBackFromPin();
          return true;
        case 'otp_entry':
          scanBackFromOtpEntry();
          return true;
        case 'authorized':
          return true;
        case 'complete':
          scanDismissSessionComplete();
          return true;
        default:
          return true;
      }
    }
    if (_s.activeTab != 'card') {
      _emit(_s.copy(activeTab: 'card'));
      return true;
    }
    return false;
  }

  void requestDeclineConfirm(String? bindingId) {
    _emit(_s.copy(declineConfirmBindingId: bindingId ?? _s.overlayAssignmentId));
  }

  void cancelDeclineConfirm() {
    _emit(_s.copy(declineConfirmBindingId: null));
  }

  void confirmDecline() {
    final id = _s.declineConfirmBindingId;
    if (_s.mainOverlay == 'assignment_notification') {
      _emit(_s.copy(
        mainOverlay: 'home',
        overlayAssignmentId: null,
        declineConfirmBindingId: null,
        successToast: 'Assignment declined',
      ));
      return;
    }
    if (id != null && !_live) {
      final next = _s.bindings.where((b) => b.id != id).toList();
      _emit(_s.copy(
        bindings: next.isEmpty ? _cloneBindings() : next,
        declineConfirmBindingId: null,
        successToast: 'Assignment declined',
      ));
      return;
    }
    _emit(_s.copy(
      mainOverlay: 'home',
      overlayAssignmentId: null,
      declineConfirmBindingId: null,
    ));
  }

  void pairingBackFromOverlay() {
    if (_s.overlayAssignmentId != null) {
      _emit(_s.copy(
        mainOverlay: 'assignment_notification',
        pairingDigits: _cloneOtpSlots(),
        pairingError: '',
        pairingSuccess: false,
        pairingAttempts: 0,
      ));
    } else {
      _emit(_s.copy(
        mainOverlay: 'home',
        pairingDigits: _cloneOtpSlots(),
        pairingError: '',
        pairingSuccess: false,
      ));
    }
  }

  void _completePairingSuccess() {
    final fromAssignment = _s.overlayAssignmentId != null;
    final assignId = _s.overlayAssignmentId;
    var bindings = _s.bindings;
    if (!_live && assignId != null) {
      bindings = bindings
          .map((b) => b.id == assignId
              ? b.copyWith(
                  paired: true,
                  state: 'ACTIVE',
                  scanPayStatus: 'always_available',
                )
              : b)
          .toList();
    }
    _emit(_s.copy(
      pairingSuccess: false,
      pairingDigits: _cloneOtpSlots(),
      pairingAttempts: 0,
      pairingError: '',
      bindings: bindings,
      mainOverlay: fromAssignment ? 'assignment_accepted' : 'home',
      activeTab: fromAssignment ? _s.activeTab : 'assignments',
      onboardingBusy: false,
    ));
    if (_live) Future.microtask(refreshLiveFleetData);
  }

  void openAssignmentForBinding(String bindingId) {
    _emit(_s.copy(
      mainOverlay: 'assignment_notification',
      overlayAssignmentId: bindingId,
      activeTab: 'card',
    ));
  }

  void openAssignmentDemo() {
    final b = assignmentDemoBinding();
    openAssignmentForBinding(b.id);
  }

  void acceptAssignmentOverlay() {
    final b = assignmentOverlayBinding();
    final needsPair =
        b.state == 'PENDING_ACCEPTANCE' || b.scanPayStatus == 'locked_unpaired';
    if (needsPair) {
      _emit(_s.copy(
        mainOverlay: 'pairing_code',
        pairingDigits: _cloneOtpSlots(),
        pairingError: '',
        overlayAssignmentId: b.id,
      ));
    } else {
      acceptAssignmentDemo();
    }
  }

  void openPairingForBinding(String bindingId) {
    _emit(_s.copy(
      mainOverlay: 'pairing_code',
      overlayAssignmentId: bindingId,
      pairingDigits: _cloneOtpSlots(),
      pairingError: '',
    ));
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

  Future<void> submitPairingCode() async {
    final code = _s.pairingDigits.join();
    if (code.length != 6 || _s.pairingSuccess) return;
    if (_live && _http != null && _s.foScopedToken != null) {
      _emit(_s.copy(onboardingBusy: true, pairingError: ''));
      try {
        await _http!.driverAcceptPairing(_s.foScopedToken!, code);
        _emit(_s.copy(pairingSuccess: true, onboardingBusy: false, pairingError: ''));
        _later(const Duration(milliseconds: 900), _completePairingSuccess);
      } catch (e) {
        final attempts = _s.pairingAttempts + 1;
        _emit(_s.copy(
          apiBanner: ReactParityStrings.forGenericFailure(e),
          pairingAttempts: attempts,
          pairingDigits: _cloneOtpSlots(),
          pairingError: 'Invalid pairing code',
          onboardingBusy: false,
        ));
      }
      return;
    }
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
    _emit(_s.copy(pairingSuccess: true, pairingError: ''));
    _later(const Duration(milliseconds: 900), _completePairingSuccess);
  }

  void setActiveCardIndex(int i) {
    final active = activeCards();
    if (i >= 0 && i < active.length) {
      _emit(_s.copy(activeCardIndex: i));
      if (_live && _s.authStep == 'complete') {
        Future.microtask(refreshLiveTransactions);
      }
    }
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
                b.scanPayStatus == 'in_window' ||
                b.scanPayStatus == 'trip_window'))
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

  FleetBinding assignmentOverlayBinding() {
    final picked = _bindingById(_s.overlayAssignmentId);
    if (picked != null) return picked;
    return assignmentDemoBinding();
  }

  FleetBinding assignmentDemoBinding() {
    for (final b in _s.bindings) {
      if (b.state == 'PENDING_ACCEPTANCE') return b;
    }
    for (final b in _s.bindings) {
      if (!b.paired && b.state == 'ACTIVE') return b;
    }
    return _s.bindings.isNotEmpty ? _s.bindings.first : mockBindings.first;
  }

  void scanPickBinding(String id) {
    _emit(_s.copy(selectedScanBindingId: id));
  }

  void scanBeginConfirmation() {
    final avail = scanAvailableBindings();
    if (avail.isEmpty) return;
    final id = _s.selectedScanBindingId ?? avail.first.id;
    _emit(_s.copy(
        selectedScanBindingId: id, sessionState: 'confirmation', sessionPin: ''));
  }

  void scanContinueToPin() {
    if (_s.sessionState != 'confirmation') return;
    if (_live && _s.parsedScanQr == null) {
      _emit(_s.copy(apiBanner: ReactParityStrings.invalidFleetpayQr));
      return;
    }
    _emit(_s.copy(sessionState: 'pin_confirm', sessionPin: ''));
  }

  void scanSimulateDemoQr() {
    final p = parseFleetpayPayUri(kSimulatedFleetpayUri);
    if (p == null) {
      _emit(_s.copy(apiBanner: ReactParityStrings.invalidFleetpayQr));
      return;
    }
    _emit(_s.copy(
      parsedScanQr: p,
      sessionState: 'confirmation',
      sessionPin: '',
      sessionOtp: '',
      apiBanner: null,
    ));
  }

  void applyFleetpayQrRaw(String raw) {
    final p = parseFleetpayPayUri(raw);
    if (p == null) {
      _emit(_s.copy(apiBanner: ReactParityStrings.invalidFleetpayQr));
      return;
    }
    _emit(_s.copy(
      parsedScanQr: p,
      sessionState: 'confirmation',
      sessionPin: '',
      sessionOtp: '',
      apiBanner: null,
    ));
  }

  void scanBackFromPin() {
    if (_s.sessionState != 'pin_confirm') return;
    _emit(_s.copy(sessionState: 'confirmation', sessionPin: ''));
  }

  void scanCancelConfirmation() {
    _emit(_s.copy(
      sessionState: 'idle',
      sessionPin: '',
      sessionOtp: '',
      parsedScanQr: null,
      lastQrPay: null,
    ));
  }

  void scanVerifyPin() {
    if (_s.sessionState != 'pin_confirm') return;
    final sel = selectedScanBinding();
    final qr = _s.parsedScanQr;
    if (_live && _http != null && _s.foScopedToken != null && sel != null && qr != null) {
      if (_s.sessionPin.length != 6) return;
      Future.microtask(() async {
        _emit(_s.copy(qrPayBusy: true, apiBanner: null));
        try {
          final vrn = normVrnPublic(sel.vrn).replaceAll(' ', '');
          final pay = await _http!.driverQrPay(
            token: _s.foScopedToken!,
            txnId: qr.txnId,
            vehicleRegNoNorm: vrn,
            pin: _s.sessionPin,
            mid: qr.mid,
            terminalId: qr.terminalId,
            amountPaise: qr.amountPaise,
            expiryEpoch: qr.expiryEpoch,
            sign: qr.sign,
          );
          _emit(_s.copy(
            sessionState: 'complete',
            sessionPin: '',
            lastQrPay: pay,
            parsedScanQr: null,
            qrPayBusy: false,
          ));
          await refreshLiveFleetData();
        } catch (e) {
          _emit(_s.copy(
            sessionPin: '',
            qrPayBusy: false,
            apiBanner: ReactParityStrings.forPinFailure(e),
          ));
        }
      });
      return;
    }
    if (_s.sessionPin != _demoPin) {
      _emit(_s.copy(sessionPin: ''));
      return;
    }
    _emit(_s.copy(
      sessionState: 'otp_entry',
      sessionPin: '',
      sessionOtp: '',
      scanOtpCountdown: 60,
    ));
  }

  void setScanSessionOtp(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    final slice =
        d.length <= 6 ? d : d.substring(0, 6);
    _emit(_s.copy(sessionOtp: slice, apiBanner: null));
  }

  void resendScanSessionOtp() {
    if (_s.scanOtpCountdown > 0) return;
    _emit(_s.copy(scanOtpCountdown: 60, apiBanner: null));
  }

  void scanBackFromOtpEntry() {
    if (_s.sessionState != 'otp_entry') return;
    _emit(_s.copy(
      sessionState: 'pin_confirm',
      sessionOtp: '',
      scanOtpCountdown: 0,
    ));
  }

  void verifyScanSessionOtp() {
    if (_s.sessionState != 'otp_entry') return;
    if (_s.sessionOtp != _demoOtp) return;
    _emit(_s.copy(
      sessionState: 'authorized',
      sessionOtp: '',
      scanOtpCountdown: 0,
    ));
    _later(const Duration(milliseconds: 600), () {
      _emit(_s.copy(sessionState: 'complete'));
    });
  }

  void scanDismissSessionComplete() {
    if (_s.sessionState != 'complete') return;
    _emit(
      _s.copy(
        sessionState: 'idle',
        sessionPin: '',
        sessionOtp: '',
        mainOverlay: 'home',
        activeTab: 'card',
        parsedScanQr: null,
        lastQrPay: null,
      ),
    );
  }

  void setSessionPin(String pin) {
    final digits = pin.replaceAll(RegExp(r'\D'), '');
    final slice =
        digits.length <= 6 ? digits : digits.substring(0, 6);
    _emit(_s.copy(sessionPin: slice));
  }

  void logout() {
    _notifyFlowComplete(logoutPayload);
    _cancelTimers();
    _emit(_initialSnapshot(_config));
  }

  void toggleDemoUserMode() {
    _emit(_s.copy(isNewUser: !_s.isNewUser));
  }

  void openScanForBinding(String bindingId) {
    _emit(_s.copy(
      selectedScanBindingId: bindingId,
      activeTab: 'scan',
      mainOverlay: 'home',
      sessionState: 'idle',
      sessionPin: '',
      sessionOtp: '',
      parsedScanQr: null,
      lastQrPay: null,
      scanOtpCountdown: 0,
    ));
  }

  void openTransactionsForBinding(String bindingId) {
    final cards = activeCards();
    var idx = -1;
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].id == bindingId) {
        idx = i;
        break;
      }
    }
    if (idx < 0) {
      for (var i = 0; i < _s.bindings.length; i++) {
        if (_s.bindings[i].id == bindingId) {
          _emit(_s.copy(activeTab: 'transactions'));
          if (_live) Future.microtask(refreshLiveTransactions);
          return;
        }
      }
      return;
    }
    _emit(_s.copy(activeCardIndex: idx, activeTab: 'transactions'));
    if (_live) Future.microtask(refreshLiveTransactions);
  }

  Future<void> refreshLiveFleetData() async {
    final tok = _s.foScopedToken;
    final http = _http;
    if (!_live || tok == null || tok.isEmpty || http == null) return;
    if (_s.authStep != 'complete') return;
    try {
      final home = await http.driverGetHome(tok);
      final prof = await http.driverGetProfile(tok);
      final rows = await http.driverGetAssignments(tok);
      var mapped = mapAssignmentsToFleetBindings(home, rows);
      try {
        final bal = await http.driverGetBalance(tok);
        final vid = home?.vehicleId;
        if (vid != null && vid.isNotEmpty && bal.isFinite) {
          mapped = mapped
              .map((b) => b.vehicleId == vid
                  ? b.copyWith(balance: bal.round(), cardBalance: bal.round())
                  : b)
              .toList();
        }
      } catch (_) {}
      final mappedFinal = mapped;
      final profile = mapLiveProfile(prof, _s.mobileNumber);
      final foName = home?.foName?.trim() ?? '';
      final dl = prof.dlNumber?.trim() ?? '';
      final reg = rows.isNotEmpty ? 'Yes' : (prof.foStatus?.trim().isNotEmpty == true ? prof.foStatus! : 'Yes');
      _emit(_s.copy(
        bindings: mappedFinal,
        profile: profile,
        profileFoName: foName.isNotEmpty ? foName : _s.fleetPinFoDisplay,
        profileDlNumber: dl.isNotEmpty ? dl : '—',
        profileRegistered: reg,
      ));
      await refreshLiveTransactions();
    } catch (e) {
      _emit(_s.copy(apiBanner: ReactParityStrings.forGenericFailure(e)));
    }
  }

  Future<void> refreshLiveTransactions() async {
    final tok = _s.foScopedToken;
    final http = _http;
    if (!_live || tok == null || http == null || _s.authStep != 'complete') {
      return;
    }
    final vid = _vehicleIdForActiveCard();
    if (vid == null || vid.isEmpty) return;
    try {
      final page = await http.driverGetTransactions(tok, vid, 0);
      final tx = page.rows.map((r) {
        final credit = r.status.toUpperCase().contains('CREDIT');
        return FleetTransaction(
          id: r.serverTxnId.isEmpty ? '-' : r.serverTxnId,
          station: r.status.isEmpty ? 'Fueling' : r.status,
          vrn: r.vehicleRegNo,
          amount: r.amountINR.abs().round(),
          date: r.createdOn,
          type: credit ? 'Credit' : 'Fueling',
          status: r.status,
          quantity: '',
        );
      }).toList();
      _emit(_s.copy(transactions: tx));
    } catch (_) {}
  }

  String? _vehicleIdForActiveCard() {
    final c = currentCard();
    final id = c?.vehicleId;
    if (id != null && id.isNotEmpty) return id;
    return null;
  }
}
