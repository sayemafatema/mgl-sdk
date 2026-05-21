import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fleet_app_engine.dart';
import 'fleet_assignments_tab.dart';
import 'fleet_demo_data.dart';
import 'fleet_sdk_payload.dart';
import 'fleet_inline_qr_scanner.dart';
import 'fleet_compose_ui.dart';
import 'fleet_driver_validation.dart';
import 'fleet_qr_scan_screen.dart';
import 'fleet_react_theme.dart';
import 'fleet_scan_receipt.dart';
import 'fleetpay_qr.dart';
import 'react_parity_strings.dart';

/// Full-screen flow matching Angular `FleetFlowHostComponent` / TS `FleetAppEngine`.
class FleetFlowScreen extends StatefulWidget {
  const FleetFlowScreen({
    super.key,
    required this.engine,
    this.onFlowComplete,
  });

  final FleetAppEngine engine;
  final void Function(FleetSdkSuccessPayload payload)? onFlowComplete;

  @override
  State<FleetFlowScreen> createState() => _FleetFlowScreenState();
}

class _FleetFlowScreenState extends State<FleetFlowScreen> {
  late final TextEditingController _mobileCtrl = TextEditingController();
  late final TextEditingController _inviteCodeCtrl = TextEditingController();
  bool _showDevMenu = false;

  @override
  void initState() {
    super.initState();
    final snap = widget.engine.getSnapshot();
    _mobileCtrl.text = snap.mobileNumber;
    _inviteCodeCtrl.text = snap.inviteCode;
    widget.engine.addListener(_onEngine);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngine);
    _mobileCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  void _onEngine() {
    final s = widget.engine.getSnapshot();
    if (_mobileCtrl.text != s.mobileNumber) {
      _mobileCtrl.value = TextEditingValue(
        text: s.mobileNumber,
        selection: TextSelection.collapsed(offset: s.mobileNumber.length),
      );
    }
    if (_inviteCodeCtrl.text != s.inviteCode) {
      _inviteCodeCtrl.value = TextEditingValue(
        text: s.inviteCode,
        selection: TextSelection.collapsed(offset: s.inviteCode.length),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.engine.getSnapshot();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final handled = widget.engine.handleBack();
        if (!handled && context.mounted) {
          widget.onFlowComplete?.call(FleetAppEngine.userCancelledPayload);
          Navigator.of(context).maybePop(FleetAppEngine.userCancelledPayload);
        }
      },
      child: Scaffold(
      backgroundColor: FleetReactTheme.gray100,
      body: SafeArea(
        child: Stack(
        children: [
          if (_showDevMenu)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xff111827),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _showDevMenu = false);
                        widget.engine.skipToMainApp();
                      },
                      child: const Text('Skip to Main App',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.engine.toggleDemoUserMode();
                        setState(() => _showDevMenu = false);
                      },
                      child: Text(
                        s.isNewUser ? 'Mode: new user ✓' : 'Mode: returning user ✓',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned.fill(
            child: ColoredBox(
              color: FleetReactTheme.gray100,
              child: s.authStep != 'complete'
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(FleetReactTheme.spacePage),
                      child: _AuthPane(
                        engine: widget.engine,
                        s: s,
                        mobileCtrl: _mobileCtrl,
                        inviteCodeCtrl: _inviteCodeCtrl,
                      ),
                    )
                  : _MainPane(
                      engine: widget.engine,
                      s: s,
                      onFlowComplete: widget.onFlowComplete,
                    ),
            ),
          ),
          if (s.authStep != 'complete' && s.apiBanner != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 52,
              child: FleetReactApiBanner(
                message: s.apiBanner!,
                onDismiss: widget.engine.dismissApiBanner,
              ),
            ),
          if (s.authStep != 'complete')
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
                color: const Color(0xfff3f4f6),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _showDevMenu = !_showDevMenu),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(child: Text('⋮', style: TextStyle(fontSize: 16))),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
      ),
    );
  }
}

class _AuthPane extends StatelessWidget {
  const _AuthPane({
    required this.engine,
    required this.s,
    required this.mobileCtrl,
    required this.inviteCodeCtrl,
  });

  final FleetAppEngine engine;
  final FleetAppSnapshot s;
  final TextEditingController mobileCtrl;
  final TextEditingController inviteCodeCtrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.onboardingBusy)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2, color: FleetReactTheme.green700),
            ),
          if (s.successToast != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FleetReactSuccessBanner(message: s.successToast!),
            ),
          _authBody(context),
        ],
      ),
    );
  }

  Widget _authBody(BuildContext context) {
    switch (s.authStep) {
      case 'login':
        return _login(context);
      case 'login_otp':
        return _loginOtp(context);
      case 'fo_pin_login':
        return _pinLogin(context);
      case 'select_fo':
        return _selectFo(context);
      case 'set_pin':
        return _setPin(context);
      case 'confirm_pin':
        return _confirmPin(context);
      case 'registered':
        return _registered(context);
      case '1c':
        return _inviteMobile(context);
      case '1d':
        return _inviteOtp(context);
      case '1b':
        return _inviteCode(context);
      case '1e':
        return _invitePin(context);
      case '1f':
        return _inviteConfirmPin(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _login(BuildContext context) {
    return FleetAuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FleetBrandHeader(),
          const SizedBox(height: 24),
          const Text('Mobile number',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: FleetReactTheme.textPrimary)),
          const SizedBox(height: 8),
          FleetMobileInputRow(
            controller: mobileCtrl,
            onChanged: engine.setMobileNumber,
            errorText: engine.showLoginMobileFormatError
                ? 'Enter a valid 10-digit Indian mobile number (starts with 6–9).'
                : null,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: validIndianMobile10(s.mobileNumber) && !s.onboardingBusy
                ? engine.loginSendOtp
                : null,
            style: FleetReactTheme.filledSendOtp(
              enabled: validIndianMobile10(s.mobileNumber) && !s.onboardingBusy,
            ),
            child: Text(s.onboardingBusy ? 'Sending…' : 'Send OTP'),
          ),
          const SizedBox(height: 16),
          const Text('or', textAlign: TextAlign.center, style: TextStyle(color: FleetReactTheme.placeholder)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: engine.goInviteSignup,
            child: const Text('New user? I have an invite code'),
          ),
          if (!s.useLiveDriverApp) ...[
            const SizedBox(height: 16),
            Text(
              'Demo OTP: 123456 · Dev ⋮ toggles new/returning user',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _loginOtp(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text(
          'Verify mobile',
          style: TextStyle(fontSize: FleetReactTheme.title, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        FleetOtpInfoBanner(
          message: s.useLiveDriverApp
              ? 'OTP sent to your mobile. Enter the code from SMS.'
              : 'OTP sent (demo — enter 123456)',
        ),
        const SizedBox(height: 12),
        FleetOtpFields(
          key: ValueKey('login-otp-${s.loginOtpRefocusKey}'),
          refocusKey: s.loginOtpRefocusKey,
          onDigit: engine.setLoginOtpDigit,
        ),
        if (s.otpErrorLogin.isNotEmpty)
          Text(s.otpErrorLogin, style: const TextStyle(color: FleetReactTheme.red600)),
        const SizedBox(height: 8),
        if (s.otpCountdown > 0)
          Text(
            'Resend OTP in ${s.otpCountdown}s',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: FleetReactTheme.caption, color: FleetReactTheme.gray500),
          )
        else
          TextButton(
            onPressed: engine.resendLoginOtp,
            child: const Text('Resend OTP'),
          ),
      ],
    );
  }

  Widget _pinLogin(BuildContext context) {
    if (s.foPinSubStep == 'forgot') {
      final phase = s.forgotFleetPinPhase;
      final filled = phase == 'first' ? s.forgotFleetPinFirst.length : s.forgotFleetPinSecond.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: engine.cancelForgotPin, child: const Text('← Back')),
          ),
          const Text('Reset fleet PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            phase == 'first' ? 'Enter new PIN' : 'Confirm new PIN',
            style: const TextStyle(color: FleetReactTheme.textMuted),
          ),
          const SizedBox(height: 8),
          FleetPinDots(filled: filled, bad: s.forgotFleetPinError.isNotEmpty),
          if (s.forgotFleetPinError.isNotEmpty)
            Text(s.forgotFleetPinError, style: const TextStyle(color: FleetReactTheme.red600)),
          FleetNumpad(
            disabled: s.onboardingBusy,
            onDigit: engine.forgotFleetPinAppend,
            onBackspace: engine.forgotFleetPinBackspace,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: filled == 6 && !s.onboardingBusy ? engine.submitForgotFleetPinStep : null,
            style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
            child: Text(
              s.onboardingBusy
                  ? 'Resetting…'
                  : (phase == 'first' ? 'Confirm PIN' : 'Reset PIN'),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FleetBrandHeader(compact: true),
        Text(s.profile.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        if (s.fleetPinFoDisplay.isNotEmpty)
          Text(s.fleetPinFoDisplay, textAlign: TextAlign.center, style: const TextStyle(color: FleetReactTheme.textMuted)),
        const SizedBox(height: 12),
        Text(
          s.useLiveDriverApp ? 'Fleet PIN' : 'Enter PIN (demo 123456)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        FleetPinDots(filled: s.loginPin.length, bad: s.loginPinError.isNotEmpty),
        if (s.loginPinError.isNotEmpty)
          Text(s.loginPinError, style: const TextStyle(color: FleetReactTheme.red600)),
        FleetNumpad(
          disabled: s.disableLoginNumpad || s.onboardingBusy,
          onDigit: engine.loginPinAppend,
          onBackspace: engine.loginPinBackspace,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: s.loginPin.length == 6 && !s.onboardingBusy ? engine.unlockApp : null,
          style: FleetReactTheme.filledGreen700(
            enabled: s.loginPin.length == 6 && !s.onboardingBusy,
          ),
          child: Text(s.onboardingBusy ? 'Unlocking…' : 'Unlock app'),
        ),
        TextButton(
          onPressed: s.canForgotFleetPin ? engine.goToForgotPin : null,
          child: const Text('Forgot PIN?'),
        ),
      ],
    );
  }

  Widget _selectFo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text(
          'Choose fleet operator',
          style: TextStyle(fontSize: FleetReactTheme.title, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...s.foOrganizations.where((f) => f.foStatus.toUpperCase() == 'ACTIVE').map((f) {
          final sel = s.selectedFoCompanyId == f.foCompanyId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
              child: InkWell(
                borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
                onTap: () => engine.selectFoOrganization(f.foCompanyId),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
                    border: Border.all(
                      color: sel ? FleetReactTheme.green700 : const Color(0xffe5e7eb),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.foName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'Fleet ID #${f.foCompanyId}',
                        style: const TextStyle(fontSize: 11, color: FleetReactTheme.gray500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _setPin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create PIN'),
        const Text('6 digits', style: TextStyle(color: FleetReactTheme.textMuted)),
        FleetPinDots(filled: s.newPin.length),
        FleetNumpad(onDigit: engine.newPinAppend, onBackspace: engine.newPinBackspace),
        FilledButton(
          onPressed: s.newPin.length == 6 ? engine.goConfirmNewPin : null,
          style: FleetReactTheme.filledGreen700(enabled: s.newPin.length == 6),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _confirmPin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Confirm PIN'),
        if (s.pinError.isNotEmpty) Text(s.pinError, style: const TextStyle(color: FleetReactTheme.red600)),
        FleetPinDots(filled: s.pinConfirm.length),
        FleetNumpad(onDigit: engine.confirmPinAppend, onBackspace: engine.confirmPinBackspace),
        FilledButton(
          onPressed: s.pinConfirm.length == 6 ? engine.submitConfirmPin : null,
          style: FleetReactTheme.filledGreen700(enabled: s.pinConfirm.length == 6),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _registered(BuildContext context) {
    return Column(
      children: [
        const Text('PIN created', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('Continue to the driver home.'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: engine.registeredContinueHome,
          style: FleetReactTheme.filledGreen700(),
          child: const Text('Continue to Home'),
        ),
      ],
    );
  }

  Widget _inviteCode(BuildContext context) {
    final okMock =
        s.inviteCode.length == 6 && mockInviteCompanies[s.inviteCode] != null;
    final okLive = s.useLiveDriverApp &&
        s.inviteCode.length >= 6 &&
        (s.inviteMobileVerificationToken?.isNotEmpty ?? false);
    final ok = s.useLiveDriverApp ? okLive : okMock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text('Invite code'),
        TextField(
          textCapitalization: TextCapitalization.characters,
          maxLength: 24,
          decoration: _inpDec('A3K9M2…'),
          controller: inviteCodeCtrl,
          onChanged: engine.setInviteCode,
        ),
        if (!s.useLiveDriverApp && okMock)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xffecfdf5),
              border: Border.all(color: const Color(0xff6ee7b7)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('✓ ${mockInviteCompanies[s.inviteCode]}'),
          ),
        FilledButton(
          onPressed: ok ? () => engine.inviteContinue() : null,
          style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _inviteMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text('Mobile verification'),
        const SizedBox(height: 8),
        FleetMobileInputRow(
          controller: mobileCtrl,
          onChanged: engine.setMobileNumber,
          errorText: engine.showLoginMobileFormatError
              ? 'Enter a valid 10-digit Indian mobile number (starts with 6–9).'
              : null,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: validIndianMobile10(s.mobileNumber) && !s.onboardingBusy
              ? engine.inviteSendOtpFromMobileScreen
              : null,
          style: FleetReactTheme.filledGreen700(
            enabled: validIndianMobile10(s.mobileNumber) && !s.onboardingBusy,
          ),
          child: Text(s.onboardingBusy ? 'Sending…' : 'Send OTP'),
        ),
      ],
    );
  }

  Widget _inviteOtp(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FleetOtpInfoBanner(
          message:
              'OTP sent to +91 …${s.mobileNumber.length >= 4 ? s.mobileNumber.substring(s.mobileNumber.length - 4).padLeft(10, '•') : s.mobileNumber}',
        ),
        const SizedBox(height: 12),
        FleetOtpFields(
          key: ValueKey('invite-otp-${s.inviteOtpRefocusKey}'),
          refocusKey: s.inviteOtpRefocusKey,
          onDigit: engine.setInviteOtpDigit,
        ),
        const SizedBox(height: 8),
        if (!s.useLiveDriverApp)
          const Text('Auto-advances on 123456', style: TextStyle(fontSize: 11)),
        if (s.otpCountdown > 0)
          Text(
            'Resend OTP in ${s.otpCountdown}s',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: FleetReactTheme.caption, color: FleetReactTheme.gray500),
          )
        else
          TextButton(
            onPressed: engine.resendInviteOtp,
            child: const Text('Resend OTP'),
          ),
      ],
    );
  }

  Widget _invitePin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if ((s.invitePreviewDriver ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.invitePreviewDriver!,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if ((s.invitePreviewFo ?? '').isNotEmpty)
                  Text(
                    s.invitePreviewFo!,
                    style: const TextStyle(fontSize: 13, color: FleetReactTheme.gray600),
                  ),
              ],
            ),
          ),
        const Text('Create app PIN'),
        FleetPinDots(filled: s.invitePin.length),
        FleetNumpad(onDigit: engine.invitePinAppend, onBackspace: engine.invitePinBackspace),
        FilledButton(
          onPressed: s.invitePin.length == 6 ? engine.invitePinNext : null,
          style: FleetReactTheme.filledGreen700(enabled: s.invitePin.length == 6),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _inviteConfirmPin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Confirm PIN'),
        if (s.pinError.isNotEmpty) Text(s.pinError, style: const TextStyle(color: FleetReactTheme.red600)),
        FleetPinDots(filled: s.invitePinConfirm.length),
        FleetNumpad(
          onDigit: engine.invitePinConfirmAppend,
          onBackspace: engine.invitePinConfirmBackspace,
        ),
        FilledButton(
          onPressed: s.invitePinConfirm.length == 6 ? engine.inviteConfirmSubmit : null,
          style: FleetReactTheme.filledGreen700(enabled: s.invitePinConfirm.length == 6),
          child: const Text('Finish signup'),
        ),
      ],
    );
  }

  InputDecoration _inpDec(String hint) => InputDecoration(
        hintText: hint,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class _MainPane extends StatefulWidget {
  const _MainPane({
    required this.engine,
    required this.s,
    this.onFlowComplete,
  });

  final FleetAppEngine engine;
  final FleetAppSnapshot s;
  final void Function(FleetSdkSuccessPayload payload)? onFlowComplete;

  @override
  State<_MainPane> createState() => _MainPaneState();
}

class _MainPaneState extends State<_MainPane> {
  String _txnFilter = 'all';
  bool _showPairingHelp = false;

  FleetAppEngine get engine => widget.engine;
  FleetAppSnapshot get s => widget.s;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: s.mainOverlay != 'home' ? _overlay(context) : _home(context),
              ),
            ],
          ),
          if (s.profilePinModalOpen) _profileChangePinModal(context),
          if (s.declineConfirmBindingId != null) _declineConfirmDialog(context),
          if (_showPairingHelp) _pairingHelpSheet(context),
        ],
      ),
    );
  }

  Widget _pairingHelpSheet(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Pairing code help',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _showPairingHelp = false),
                    ),
                  ],
                ),
                const Text(
                  'Ask your Fleet Operator to share the 6-digit pairing code for this assignment.',
                  style: TextStyle(fontSize: 14, color: Color(0xff374151)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'They can find it in the MGL Fleet portal under Driver Management.',
                  style: TextStyle(fontSize: 14, color: Color(0xff374151)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _declineConfirmDialog(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: AlertDialog(
          title: const Text('Decline this assignment?'),
          content: const Text('Your Fleet Operator will be notified.'),
          actions: [
            TextButton(onPressed: engine.cancelDeclineConfirm, child: const Text('Cancel')),
            TextButton(
              onPressed: engine.confirmDecline,
              child: const Text('Yes, decline', style: TextStyle(color: Color(0xffdc2626))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileChangePinModal(BuildContext context) {
    final phase = s.profileChangePinPhase;
    final filled =
        phase == 'first' ? s.profileChangePinFirst.length : s.profileChangePinSecond.length;
    return Material(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Change fleet PIN',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      IconButton(
                        onPressed: engine.closeProfileChangePin,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    phase == 'first' ? 'Enter new PIN' : 'Confirm new PIN',
                    style: const TextStyle(color: Color(0xff64748b)),
                  ),
                  const SizedBox(height: 8),
                  FleetPinDots(filled: filled, bad: s.profileChangePinError.isNotEmpty),
                  if (s.profileChangePinError.isNotEmpty)
                    Text(s.profileChangePinError,
                        style: const TextStyle(color: Color(0xffb91c1c))),
                  FleetNumpad(
                    disabled: s.profilePinChanging,
                    onDigit: engine.profileChangePinAppend,
                    onBackspace: engine.profileChangePinBackspace,
                  ),
                  FilledButton(
                    onPressed: filled == 6 && !s.profilePinChanging
                        ? engine.submitProfileChangePinStep
                        : null,
                    style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
                    child: Text(s.profilePinChanging ? 'Saving…' : (phase == 'first' ? 'Next' : 'Save PIN')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    switch (s.mainOverlay) {
      case 'assignment_notification':
        final a = engine.assignmentOverlayBinding();
        return Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => engine.setMainOverlay('home'),
              ),
              title: const Text('New assignment'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: const Color(0xfffffbeb),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pairing required',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff78350f))),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter the 6-digit code from your Fleet Operator to activate fueling.',
                            style: TextStyle(fontSize: 13, color: Color(0xff78350f)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(a.vrn,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  Text(a.fo, style: const TextStyle(color: Color(0xff64748b))),
                  if (a.assignedBy != null && a.assignedBy!.isNotEmpty)
                    Text('Assigned by ${a.assignedBy}', style: const TextStyle(fontSize: 12, color: Color(0xff94a3b8))),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: engine.acceptAssignmentOverlay,
                    style: FilledButton.styleFrom(
                      backgroundColor: FleetReactTheme.green700,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Accept & Pair'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => engine.requestDeclineConfirm(a.id),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Decline', style: TextStyle(color: Color(0xffdc2626))),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'pairing_code':
        if (s.pairingAttempts >= 3) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Too many attempts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text('Please try again later or contact your fleet operator.'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => engine.setMainOverlay('home'),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        final assign = engine.assignmentOverlayBinding();
        return Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: engine.pairingBackFromOverlay,
              ),
              title: const Text('Enter pairing code'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: FleetReactTheme.gray100,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assign.vrn,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(assign.fo, style: const TextStyle(fontSize: 12, color: Color(0xff64748b))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter the 6-digit code your Fleet Operator shared with you',
                    style: TextStyle(color: Color(0xff64748b), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (s.pairingSuccess) ...[
                    const Icon(Icons.check_circle, color: FleetReactTheme.green700, size: 48),
                    const Text('Pairing successful!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: FleetReactTheme.green700)),
                    const Text('Activating your assignment…',
                        style: TextStyle(color: Color(0xff64748b), fontSize: 13)),
                  ] else ...[
                    FleetOtpFields(
                      key: ValueKey('pair-${s.pairingAttempts}'),
                      refocusKey: s.pairingAttempts,
                      onDigit: engine.setPairingDigit,
                    ),
                    if (s.pairingError.isNotEmpty)
                      Text(s.pairingError, style: const TextStyle(color: Color(0xffb91c1c))),
                    if (!s.useLiveDriverApp)
                      const Text('Demo: 123456, 789012',
                          style: TextStyle(fontSize: 11, color: Color(0xff94a3b8))),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: s.onboardingBusy || s.pairingDigits.join().length != 6
                          ? null
                          : engine.submitPairingCode,
                      style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
                      child: Text(s.onboardingBusy ? 'Verifying…' : 'Verify & Activate'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showPairingHelp = true),
                      child: const Text('Haven\'t received your code?',
                          style: TextStyle(color: FleetReactTheme.green700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      case 'assignment_accepted':
        final a = engine.assignmentOverlayBinding();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: FleetReactTheme.green700, size: 80),
              const SizedBox(height: 16),
              const Text('Assignment activated!',
                  style: TextStyle(
                      color: Color(0xff047857), fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(a.vrn,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              Text(a.fo, style: const TextStyle(color: Color(0xff64748b))),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: engine.dismissAssignmentFlow,
                style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
                child: const Text('Go to My Assignments'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _home(BuildContext context) {
    final onTransactions = s.activeTab == 'transactions';

    return Column(
      children: [
        FleetMainHeader(
          greeting: fleetIndiaGreeting(),
          driverName: s.profile.name,
          initials: s.profile.initials,
        ),
        if (s.apiBanner != null)
          FleetReactApiBanner(
            message: s.apiBanner!,
            onDismiss: engine.dismissApiBanner,
          ),
        if (s.successToast != null) FleetReactSuccessBanner(message: s.successToast!),
        if (!s.useLiveDriverApp)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                    onPressed: engine.openAssignmentDemo,
                    child: const Text('Demo: assignment push')),
                OutlinedButton(
                    onPressed: engine.openPairingDemo, child: const Text('Demo: pairing')),
              ],
            ),
          ),
        Expanded(
          child: ColoredBox(
            color: (s.activeTab == 'card' || s.activeTab == 'assignments')
                ? FleetReactTheme.tabShellBg
                : Colors.white,
            child: _tabBody(context),
          ),
        ),
        FleetBottomNav(
          currentTab: onTransactions ? '' : s.activeTab,
          onTab: engine.setTab,
        ),
      ],
    );
  }

  Widget _tabBody(BuildContext context) {
    switch (s.activeTab) {
      case 'card':
        return _tabCard(context);
      case 'scan':
        return _tabScan(context);
      case 'assignments':
        return FleetAssignmentsTab(engine: engine, snapshot: s);
      case 'transactions':
        return _tabTxns(context);
      case 'profile':
        return _tabProfile(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _walletAuthBadge(FleetBinding c) {
    late Color bg;
    late Color fg;
    late String label;
    switch (c.authMode) {
      case 'vehicle_linked':
        bg = const Color(0xffe8f5e9);
        fg = const Color(0xff1b5e20);
        label = 'Vehicle-linked';
        break;
      case 'shift_based':
        bg = const Color(0xfffef3c7);
        fg = const Color(0xff78350f);
        label = 'Shift · ends ${c.shiftEnd ?? ''}';
        break;
      case 'trip_linked':
        bg = const Color(0xffdbeafe);
        fg = const Color(0xff1e3a8a);
        label = 'Trip · ends ${c.tripEnd ?? ''}';
        break;
      default:
        bg = const Color(0xfff3f4f6);
        fg = const Color(0xff374151);
        label = c.authMode;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _tabCard(BuildContext context) {
    final c = engine.currentCard();
    final pending = engine.pendingAssignmentCount();
    final cards = engine.activeCards();
    final noV = cards.isEmpty;
    final noTx = s.transactions.isEmpty;
    final scanGreen = FleetReactTheme.primaryCta;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (s.bindings.isNotEmpty && pending > 0)
          Material(
            color: const Color(0xfffffbeb),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xfffde68a)),
            ),
            child: ListTile(
              title: Text(
                '$pending assignment${pending > 1 ? 's' : ''} need your attention',
                style: const TextStyle(color: Color(0xff78350f), fontSize: 14),
              ),
              trailing: TextButton(
                onPressed: () => engine.setTab('assignments'),
                child: const Text('View', style: TextStyle(color: Color(0xff2e7d32), fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        if (noV && noTx) ...[
          _emptyBigCard(context, pending, scanGreen),
        ] else if (noV) ...[
          _emptyNoVehicleCard(context, pending, scanGreen),
          _recentSection(context, scanGreen),
        ] else if (c != null) ...[
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffe5e7eb)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0a000000), blurRadius: 12, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            s.fleetPinFoDisplay.isEmpty ? c.fo : s.fleetPinFoDisplay,
                            style: TextStyle(fontSize: 14, height: 1.35, color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _walletAuthBadge(c),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      c.vrn,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xff111827),
                        fontFamily: 'monospace',
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.only(top: 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xfff3f4f6))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VEHICLE BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.2,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${c.balance}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: Color(0xff111827),
                            ),
                          ),
                          if ((c.incentiveBalance ?? 0) > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Card ₹${c.cardBalance} · Incentive ₹${c.incentiveBalance}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (s.activeCardIndex > 0)
                Positioned(
                  left: 0,
                  child: IconButton(
                    onPressed: () => engine.setActiveCardIndex(s.activeCardIndex - 1),
                    icon: const Icon(Icons.chevron_left, color: Color(0xff718096)),
                  ),
                ),
              if (s.activeCardIndex < cards.length - 1)
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () => engine.setActiveCardIndex(s.activeCardIndex + 1),
                    icon: const Icon(Icons.chevron_right, color: Color(0xff718096)),
                  ),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (i) {
              return GestureDetector(
                onTap: () => engine.setActiveCardIndex(i),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  width: i == s.activeCardIndex ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: i == s.activeCardIndex ? scanGreen : const Color(0xffd1d5db),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scanGreen,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: c.scanPayStatus == 'out_window' ? null : () => engine.setTab('scan'),
            child: const Text('Scan & Pay', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          _recentSection(context, scanGreen),
        ],
      ],
    );
  }

  Widget _emptyBigCard(BuildContext context, int pending, Color scanGreen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xffe5e7eb))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined, size: 36, color: const Color(0xff7d9188)),
            const SizedBox(height: 20),
            const Text('No vehicles or transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              "There's nothing to show yet. When your fleet operator assigns you a vehicle and you use Scan & Pay, your balance and activity will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff718096), fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (pending > 0)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: scanGreen),
                onPressed: () => engine.setTab('assignments'),
                child: const Text('Go to vehicles'),
              )
            else
              TextButton(
                onPressed: () => engine.setTab('assignments'),
                child: const Text('Browse vehicles', style: TextStyle(color: Color(0xff2e7d32), fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyNoVehicleCard(BuildContext context, int pending, Color scanGreen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xffe5e7eb))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined, color: const Color(0xff7d9188)),
            const SizedBox(height: 12),
            const Text('No active vehicle', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              "You don't have a paired vehicle right now. Accept an assignment to unlock Scan & Pay.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff718096)),
            ),
            if (pending > 0) ...[
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: scanGreen),
                onPressed: () => engine.setTab('assignments'),
                child: const Text('View vehicles'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _txnCredit(FleetTransaction t) {
    if (t.type.toLowerCase() == 'credit') return true;
    return RegExp(r'credit|top-up|wallet|neft', caseSensitive: false).hasMatch(t.status);
  }

  Widget _recentSection(BuildContext context, Color scanGreen) {
    final rows = s.transactions.take(3).toList();
    final empty = s.transactions.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              if (!empty)
                TextButton(
                  onPressed: () => engine.setTab('transactions'),
                  child: const Text('View all', style: TextStyle(color: Color(0xff2e7d32), fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        if (empty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xfff3f4f6))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 14),
              child: Column(
                children: [
                  const Icon(Icons.history, color: Color(0xff9ca3af), size: 28),
                  const SizedBox(height: 16),
                  const Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    'Fuel payments and wallet activity will show here once you use Scan & Pay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...rows.map((t) {
            final credit = _txnCredit(t);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xfff3f4f6))),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: credit ? const Color(0xfff0fdf4) : const Color(0xfffef2f2),
                  child: Text(credit ? '↑' : '↓', style: TextStyle(color: credit ? const Color(0xff15803d) : const Color(0xffdc2626), fontWeight: FontWeight.bold)),
                ),
                title: Text(t.station, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${t.vrn} · ${t.date}', style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  '${credit ? '+' : '-'}₹${t.amount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: credit ? const Color(0xff16a34a) : const Color(0xff111827),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _tabScan(BuildContext context) {
    final avail = engine.scanAvailableBindings();
    final sel = engine.selectedScanBinding();
    if (avail.isEmpty) {
      final locked = s.bindings
          .where((b) =>
              b.scanPayStatus == 'locked_unpaired' ||
              b.scanPayStatus == 'locked_repair' ||
              b.scanPayStatus == 'out_window')
          .toList();
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Scan & Pay unavailable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('No vehicles available for scanning right now.', style: TextStyle(color: Color(0xff718096))),
          if (locked.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              color: const Color(0xfff9fafb),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: locked.map((b) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.vrn, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          Text(
                            switch (b.scanPayStatus) {
                              'locked_unpaired' => 'Pair to unlock',
                              'locked_repair' => 'Re-pair required',
                              'out_window' => 'Outside shift/trip window',
                              _ => b.scanPayStatus.replaceAll('_', ' '),
                            },
                            style: const TextStyle(fontSize: 14, color: Color(0xff6b7280)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => engine.setTab('assignments'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff047857),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Go to My Vehicles'),
          ),
        ],
      );
    }
    if (s.sessionState == 'confirmation' && sel != null) {
      final qr = s.parsedScanQr;
      final station = qr?.merchantName?.trim().isNotEmpty == true
          ? qr!.merchantName!
          : (s.useLiveDriverApp ? '—' : 'MGL Hind CNG Filling Station');
      final midLine = qr?.mid?.trim().isNotEmpty == true
          ? 'MID ${qr!.mid}'
          : (s.useLiveDriverApp ? '—' : 'Andheri, Mumbai');
      return ListView(
        padding: const EdgeInsets.all(FleetReactTheme.spacePage),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confirm fueling',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: FleetReactTheme.title)),
              IconButton(onPressed: engine.scanCancelConfirmation, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xffe5e7eb)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Color(0xff15803d)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(station,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(midLine, style: const TextStyle(color: FleetReactTheme.textMuted)),
                        const SizedBox(height: 12),
                        Text('${sel.vrn} · ₹${qr != null ? paiseToInrDisplay(qr.amountPaise) : '—'}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FleetReactTheme.primaryCta,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FleetReactTheme.radiusLg)),
            ),
            onPressed: engine.scanContinueToPin,
            child:
                const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }
    if (s.sessionState == 'pin_confirm' && sel != null) {
      return ListView(
        padding: const EdgeInsets.all(FleetReactTheme.spacePage),
        children: [
          Row(
            children: [
              IconButton(onPressed: engine.scanBackFromPin, icon: const Icon(Icons.arrow_back)),
              const Expanded(
                child: Text('Verify PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: engine.scanCancelConfirmation, icon: const Icon(Icons.close)),
            ],
          ),
          const Text('Enter your PIN to confirm',
              style: TextStyle(color: FleetReactTheme.textMuted)),
          const SizedBox(height: 8),
          FleetPinDots(filled: s.sessionPin.length),
          FleetNumpad(
            disabled: s.qrPayBusy,
            onDigit: (d) {
              final next = '${s.sessionPin}$d';
              if (next.length <= 6) {
                engine.setSessionPin(next);
                if (next.length == 6) engine.scanVerifyPin();
              }
            },
            onBackspace: () {
              if (s.sessionPin.isNotEmpty) {
                engine.setSessionPin(
                    s.sessionPin.substring(0, s.sessionPin.length - 1));
              }
            },
          ),
          if (s.qrPayBusy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(color: FleetReactTheme.green700),
            ),
        ],
      );
    }
    if (s.sessionState == 'otp_entry' && sel != null) {
      final tail = s.mobileNumber.length >= 10
          ? s.mobileNumber.substring(s.mobileNumber.length - 4)
          : '••••';
      return ListView(
        padding: const EdgeInsets.all(FleetReactTheme.spacePage),
        children: [
          Row(
            children: [
              IconButton(onPressed: engine.scanBackFromOtpEntry, icon: const Icon(Icons.arrow_back)),
              const Expanded(
                child: Text('One-time password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FleetReactTheme.blue50,
              border: Border.all(color: FleetReactTheme.blue200),
              borderRadius: BorderRadius.circular(FleetReactTheme.radiusLg),
            ),
            child: Text(
              'OTP sent to +91 ${tail.padLeft(10, '•')}',
              style: const TextStyle(fontSize: FleetReactTheme.body, color: FleetReactTheme.blue900),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Enter OTP',
              counterText: '',
            ),
            onChanged: engine.setScanSessionOtp,
          ),
          if (s.scanOtpCountdown > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'Resend OTP in ${s.scanOtpCountdown}s',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: FleetReactTheme.caption,
                  color: FleetReactTheme.textCaption,
                ),
              ),
            )
          else
            TextButton(
              onPressed: engine.resendScanSessionOtp,
              child:
                  const Text('Resend OTP', style: TextStyle(color: FleetReactTheme.green700)),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FleetReactTheme.green700,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(FleetReactTheme.radiusLg),
              ),
            ),
            onPressed: s.sessionOtp.length == 6 ? engine.verifyScanSessionOtp : null,
            child: const Text('Verify & Authorize'),
          ),
        ],
      );
    }
    if (s.sessionState == 'authorized' && sel != null) {
      final amt = s.parsedScanQr != null
          ? paiseToInrDisplay(s.parsedScanQr!.amountPaise)
          : (s.lastQrPay?.amountINR != null ? '₹${s.lastQrPay!.amountINR}' : '—');
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.local_gas_station, size: 48, color: FleetReactTheme.green700),
          const SizedBox(height: 12),
          const Text('Fueling authorized',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text(sel.vrn, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w600)),
          Text('Amount $amt', style: const TextStyle(color: Color(0xff64748b))),
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator(color: FleetReactTheme.green700)),
          const SizedBox(height: 8),
          const Text('Completing transaction…', textAlign: TextAlign.center),
        ],
      );
    }
    if (s.sessionState == 'complete') {
      final pay = s.lastQrPay;
      if (pay != null) {
        return FleetScanReceiptView(
          pay: pay,
          vrn: pay.vehicleRegNo?.trim().isNotEmpty == true
              ? pay.vehicleRegNo!
              : (sel?.vrn ?? '—'),
          driverName: s.profile.name,
          onDone: engine.scanDismissSessionComplete,
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.check_circle, color: FleetReactTheme.green700, size: 48),
          const Text('Payment complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: engine.scanDismissSessionComplete,
            style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
            child: const Text('Done'),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 8,
          children: avail.map((b) {
            final on = sel?.id == b.id;
            return ChoiceChip(
              label: Text(b.vrn),
              selected: on,
              onSelected: (_) => engine.scanPickBinding(b.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text('Fueling: ${(sel ?? avail.first).vrn}', style: const TextStyle(fontWeight: FontWeight.w600)),
        if (sel != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available balance', style: TextStyle(color: FleetReactTheme.textMuted)),
              Text(
                '₹${sel.balance ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xff15803d)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: FleetInlineQrScanner(
            active: s.sessionState == 'idle',
            scanResetKey: '${sel?.id ?? ''}|${s.sessionState}',
            onBarcodeRaw: engine.applyFleetpayQrRaw,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Point camera at the QR on the POS screen',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: FleetReactTheme.textMuted),
        ),
        if (!s.useLiveDriverApp) ...[
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
            onPressed: engine.scanBeginConfirmation,
            child: const Text('Simulate Scan'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final raw = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const FleetpayQrScanScreen()),
            );
            if (!context.mounted || raw == null) return;
            engine.applyFleetpayQrRaw(raw);
          },
          child: const Text('Open full-screen scanner'),
        ),
      ],
    );
  }

  Widget _tabTxns(BuildContext context) {
    final rows = s.transactions.where((t) {
      switch (_txnFilter) {
        case 'successful':
          return _txnStatusOk(t.status);
        case 'failed':
          return !_txnStatusOk(t.status);
        default:
          return true;
      }
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 8,
          children: ['all', 'successful', 'failed'].map((f) {
            final sel = _txnFilter == f;
            return ChoiceChip(
              label: Text(_txnFilterLabel(f)),
              selected: sel,
              onSelected: (_) => setState(() => _txnFilter = f),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_emptyTxnMsg(), style: const TextStyle(color: Color(0xff718096))),
          )
        else
          ...rows.map((t) => Card(
                child: ListTile(
                  title: Text(t.station, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${t.vrn}\n${t.date}', style: const TextStyle(fontSize: 12)),
                  isThreeLine: true,
                  trailing: Text(
                    '${_txnCredit(t) ? '+' : '-'}₹${t.amount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _txnCredit(t) ? const Color(0xff16a34a) : const Color(0xff111827),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  String _txnFilterLabel(String f) {
    switch (f) {
      case 'successful':
        return 'Successful';
      case 'failed':
        return 'Failed';
      default:
        return 'All';
    }
  }

  String _emptyTxnMsg() {
    switch (_txnFilter) {
      case 'successful':
        return 'No successful transactions';
      case 'failed':
        return 'No failed transactions';
      default:
        return 'No transactions';
    }
  }

  bool _txnStatusOk(String st) => st.toUpperCase() == 'SUCCESS' || st == 'Success';

  Widget _tabProfile(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          children: [
            CircleAvatar(radius: 32, backgroundColor: Colors.green.shade100, child: Text(s.profile.initials, style: TextStyle(color: Colors.green.shade800, fontSize: 22, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Text(s.profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Driver', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xffe5e7eb))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const Divider(height: 1),
              _profileRow('Mobile', s.profile.maskedMobile),
              const Divider(height: 1),
              _profileRow(
                'Registered',
                s.profileRegistered.isNotEmpty ? s.profileRegistered : (s.profile.registered ? 'Yes' : '—'),
              ),
              const Divider(height: 1),
              _profileRow(
                'Fleet Operator',
                s.profileFoName.isNotEmpty ? s.profileFoName : (s.fleetPinFoDisplay.isNotEmpty ? s.fleetPinFoDisplay : '—'),
              ),
              const Divider(height: 1),
              _profileRow('Driver ID', s.profile.id),
              const Divider(height: 1),
              _profileRow('Licence Number', s.profileDlNumber.isNotEmpty ? s.profileDlNumber : '—'),
            ],
          ),
        ),
        if (engine.canChangeProfilePin()) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: engine.openProfileChangePin,
            style: OutlinedButton.styleFrom(
              foregroundColor: FleetReactTheme.green700,
              side: const BorderSide(color: FleetReactTheme.green700),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Change fleet PIN', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xffdc2626),
            side: const BorderSide(color: Color(0xfffecaca)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: engine.logout,
          child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _profileRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(k, style: const TextStyle(color: Color(0xff718096), fontSize: 13))),
          Expanded(
            flex: 2,
            child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
