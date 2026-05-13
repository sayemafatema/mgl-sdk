import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fleet_app_engine.dart';
import 'fleet_demo_data.dart';
import 'fleet_qr_scan_screen.dart';
import 'fleet_react_theme.dart';
import 'fleetpay_qr.dart';
import 'react_parity_strings.dart';

/// Full-screen flow matching Angular `FleetFlowHostComponent` / TS `FleetAppEngine`.
class FleetFlowScreen extends StatefulWidget {
  const FleetFlowScreen({super.key, required this.engine});

  final FleetAppEngine engine;

  @override
  State<FleetFlowScreen> createState() => _FleetFlowScreenState();
}

class _FleetFlowScreenState extends State<FleetFlowScreen> {
  late final TextEditingController _mobileCtrl = TextEditingController();
  late final TextEditingController _inviteCodeCtrl = TextEditingController();

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

  static const _otpSlots = [0, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    final s = widget.engine.getSnapshot();
    return Scaffold(
      backgroundColor: FleetReactTheme.gray100,
      body: SafeArea(
        child: Stack(
        children: [
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
                        otpSlots: _otpSlots,
                      ),
                    )
                  : _MainPane(engine: widget.engine, s: s),
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
          Positioned(
            bottom: 8,
            right: 8,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xffcbd5e1)),
              ),
              onPressed: widget.engine.skipToMainApp,
              child: const Text('Skip to main (dev)', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
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
    required this.otpSlots,
  });

  final FleetAppEngine engine;
  final FleetAppSnapshot s;
  final TextEditingController mobileCtrl;
  final TextEditingController inviteCodeCtrl;
  final List<int> otpSlots;

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
      case 'forgot_pin':
        return _forgotPin(context);
      case 'forgot_otp':
        return _forgotOtp(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _logoBlock(big: true),
        const Text('Mobile number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffd1d5db)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xfff9fafb),
              ),
              child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inpDec('10-digit mobile'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: mobileCtrl,
                onChanged: engine.setMobileNumber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: s.mobileNumber.length == 10
              ? () {
                  engine.loginSendOtp();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: FleetReactTheme.primaryCta,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FleetReactTheme.radiusLg),
            ),
          ),
          child: const Text('Send OTP'),
        ),
        const SizedBox(height: 16),
        const Text('or', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff94a3b8))),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: engine.goInviteSignup,
          child: const Text('New user? I have an invite code'),
        ),
        const SizedBox(height: 16),
        if (!s.useLiveDriverApp)
          Text(
            'Demo OTP after login: 123456 · PIN: 123456',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
      ],
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FleetReactTheme.blue50,
            border: Border.all(color: FleetReactTheme.blue200),
            borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
          ),
          child: Text(
            s.useLiveDriverApp
                ? 'OTP sent to your mobile. Enter the code from SMS.'
                : 'OTP sent (demo — enter 123456)',
            style: const TextStyle(
              fontSize: FleetReactTheme.body,
              color: FleetReactTheme.blue900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _OtpRow(key: ValueKey(s.authStep), onDigit: engine.setLoginOtpDigit),
        if (s.otpErrorLogin.isNotEmpty)
          Text(s.otpErrorLogin, style: const TextStyle(color: Color(0xffb91c1c))),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _logoBlock(big: false),
        Text(s.profile.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Text(
          s.useLiveDriverApp ? 'Fleet PIN' : 'Enter PIN (demo 123456)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _pinDots(s.loginPin.length, bad: s.loginPinError.isNotEmpty),
        if (s.loginPinError.isNotEmpty)
          Text(s.loginPinError, style: const TextStyle(color: Color(0xffb91c1c))),
        _NumPad(
          disabled: s.disableLoginNumpad,
          onDigit: engine.loginPinAppend,
          onBackspace: engine.loginPinBackspace,
        ),
        TextButton(onPressed: engine.goToForgotPin, child: const Text('Forgot PIN?')),
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

  Widget _forgotPin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text('Reset PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Text('We\'ll verify ${s.profile.maskedMobile}', style: const TextStyle(color: Color(0xff64748b))),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: engine.forgotPinSendOtp,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
          child: const Text('Send OTP'),
        ),
      ],
    );
  }

  Widget _forgotOtp(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text('Verify mobile'),
        const SizedBox(height: 12),
        _OtpRow(key: const ValueKey('forgot_otp'), onDigit: engine.setForgotOtpDigit),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: s.inviteOtp.length == 6 ? engine.verifyForgotOtp : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
          child: const Text('Verify'),
        ),
      ],
    );
  }

  Widget _setPin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create PIN'),
        const Text('6 digits', style: TextStyle(color: Color(0xff64748b))),
        _pinDots(s.newPin.length, bad: false),
        _NumPad(
          disabled: false,
          onDigit: engine.newPinAppend,
          onBackspace: engine.newPinBackspace,
        ),
        FilledButton(
          onPressed: s.newPin.length == 6 ? engine.goConfirmNewPin : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
        if (s.pinError.isNotEmpty) Text(s.pinError, style: const TextStyle(color: Color(0xffb91c1c))),
        _pinDots(s.pinConfirm.length, bad: false),
        _NumPad(
          disabled: false,
          onDigit: engine.confirmPinAppend,
          onBackspace: engine.confirmPinBackspace,
        ),
        FilledButton(
          onPressed: s.pinConfirm.length == 6 ? engine.submitConfirmPin : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffd1d5db)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('+91'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inpDec(''),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: mobileCtrl,
                onChanged: engine.setMobileNumber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: s.mobileNumber.length == 10
              ? () => engine.inviteSendOtpFromMobileScreen()
              : null,
          style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
          child: const Text('Send OTP'),
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FleetReactTheme.blue50,
            border: Border.all(color: FleetReactTheme.blue200),
            borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
          ),
          child: Text(
            'OTP sent to +91 …${s.mobileNumber.length >= 4 ? s.mobileNumber.substring(s.mobileNumber.length - 4).padLeft(10, '•') : s.mobileNumber}',
            style: const TextStyle(fontSize: FleetReactTheme.body, color: FleetReactTheme.blue900),
          ),
        ),
        const SizedBox(height: 12),
        _OtpRow(key: ValueKey(s.authStep), onDigit: engine.setInviteOtpDigit),
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
        _pinDots(s.invitePin.length, bad: false),
        _NumPad(
          disabled: false,
          onDigit: engine.invitePinAppend,
          onBackspace: engine.invitePinBackspace,
        ),
        FilledButton(
          onPressed: s.invitePin.length == 6 ? engine.invitePinNext : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
        if (s.pinError.isNotEmpty) Text(s.pinError, style: const TextStyle(color: Color(0xffb91c1c))),
        _pinDots(s.invitePinConfirm.length, bad: false),
        _NumPad(
          disabled: false,
          onDigit: engine.invitePinConfirmAppend,
          onBackspace: engine.invitePinConfirmBackspace,
        ),
        FilledButton(
          onPressed: s.invitePinConfirm.length == 6 ? engine.inviteConfirmSubmit : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
          child: const Text('Finish signup'),
        ),
      ],
    );
  }

  Widget _logoBlock({required bool big}) {
    return Column(
      children: [
        Container(
          width: big ? 72 : 48,
          height: big ? 72 : 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xff059669), Color(0xff2563eb)]),
          ),
          child: Text(
            'MGL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: big ? 18 : 14),
          ),
        ),
        const SizedBox(height: 8),
        if (big) ...[
          const Text('MGL Fleet Connect', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Driver App', style: TextStyle(color: Colors.grey.shade600)),
        ] else
          Text('Welcome back', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  InputDecoration _inpDec(String hint) => InputDecoration(
        hintText: hint,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _pinDots(int filled, {required bool bad}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: otpSlots.map((i) {
        final on = filled > i;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? (bad ? const Color(0xffdc2626) : const Color(0xff047857)) : Colors.transparent,
            border: Border.all(color: bad && on ? const Color(0xffdc2626) : const Color(0xffd1d5db), width: 2),
          ),
        );
      }).toList(),
    );
  }
}

class _NumPad extends StatelessWidget {
  const _NumPad({
    required this.disabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final bool disabled;
  final void Function(String d) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in [1, 2, 3, 4, 5, 6, 7, 8, 9])
            SizedBox(
              width: 72,
              height: 48,
              child: ElevatedButton(
                onPressed: disabled ? null : () => onDigit('$n'),
                child: Text('$n'),
              ),
            ),
          SizedBox(
            width: 148,
            height: 48,
            child: ElevatedButton(onPressed: disabled ? null : onBackspace, child: const Text('⌫')),
          ),
          SizedBox(
            width: 72,
            height: 48,
            child: ElevatedButton(
              onPressed: disabled ? null : () => onDigit('0'),
              child: const Text('0'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpRow extends StatefulWidget {
  const _OtpRow({super.key, required this.onDigit});

  final void Function(int index, String digit) onDigit;

  @override
  State<_OtpRow> createState() => _OtpRowState();
}

class _OtpRowState extends State<_OtpRow> {
  late final List<TextEditingController> _c = List.generate(6, (_) => TextEditingController());
  late final List<FocusNode> _f = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final x in _c) {
      x.dispose();
    }
    for (final x in _f) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            width: 40,
            child: TextField(
              controller: _c[i],
              focusNode: _f[i],
              maxLength: 1,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) {
                widget.onDigit(i, v);
                _c[i].clear();
                if (v.isNotEmpty && i < 5) {
                  _f[i + 1].requestFocus();
                }
              },
            ),
          ),
        );
      }),
    );
  }
}

class _MainPane extends StatefulWidget {
  const _MainPane({required this.engine, required this.s});

  final FleetAppEngine engine;
  final FleetAppSnapshot s;

  @override
  State<_MainPane> createState() => _MainPaneState();
}

class _MainPaneState extends State<_MainPane> {
  String _txnFilter = 'all';

  FleetAppEngine get engine => widget.engine;
  FleetAppSnapshot get s => widget.s;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: s.mainOverlay != 'home' ? _overlay(context) : _home(context),
          ),
        ],
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    switch (s.mainOverlay) {
      case 'assignment_notification':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff0f766e), Colors.white],
              stops: [0, 0.35],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(onPressed: () => engine.setMainOverlay('home'), child: const Text('←', style: TextStyle(color: Colors.white))),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('New assignment'),
                      Text(engine.assignmentDemoBinding().vrn, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(engine.assignmentDemoBinding().fo),
                      FilledButton(
                        onPressed: engine.acceptAssignmentDemo,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
                        child: const Text('Review & accept'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 'pairing_code':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Enter pairing code'),
              const Text('Demo valid codes include 123456, 789012'),
              _OtpRow(key: ValueKey('pair-${s.pairingAttempts}'), onDigit: engine.setPairingDigit),
              if (s.pairingError.isNotEmpty) Text(s.pairingError, style: const TextStyle(color: Color(0xffb91c1c))),
              FilledButton(onPressed: () => engine.submitPairingCode(), child: const Text('Pair')),
              TextButton(onPressed: () => engine.setMainOverlay('home'), child: const Text('Cancel')),
            ],
          ),
        );
      case 'assignment_accepted':
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Assignment activated', style: TextStyle(color: Color(0xff047857), fontSize: 20)),
              Text(engine.assignmentDemoBinding().vrn, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              FilledButton(onPressed: engine.dismissAssignmentFlow, child: const Text('Go to Assignments')),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _home(BuildContext context) {
    const navTabs = ['card', 'scan', 'assignments', 'profile'];
    final onTransactions = s.activeTab == 'transactions';
    final selIdx = onTransactions ? -1 : navTabs.indexOf(s.activeTab);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          color: const Color(0xff1a3020),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_indiaGreeting(),
                      style: const TextStyle(color: Color(0xffc8e6c9), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(s.profile.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xff2d4a36),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text(s.profile.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        if (s.successToast != null)
          Container(
            width: double.infinity,
            color: const Color(0xff059669),
            padding: const EdgeInsets.all(12),
            child: Text(s.successToast!, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: engine.openAssignmentDemo, child: const Text('Demo: assignment push')),
              OutlinedButton(onPressed: engine.openPairingDemo, child: const Text('Demo: pairing')),
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: (s.activeTab == 'card' || s.activeTab == 'assignments') ? const Color(0xffeceff1) : Colors.white,
            child: _tabBody(context),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xffe5e7eb))),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _navItem(0, selIdx, Icons.home_outlined, 'Home', 'card'),
              _navItem(1, selIdx, Icons.qr_code_2, 'Scan & Pay', 'scan'),
              _navItem(2, selIdx, Icons.local_shipping_outlined, 'My Vehicles', 'assignments'),
              _navItem(3, selIdx, Icons.person_outline, 'Profile', 'profile'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navItem(int index, int selIdx, IconData icon, String label, String tab) {
    final on = selIdx == index;
    final c = on ? const Color(0xff047857) : const Color(0xff6b7280);
    return Expanded(
      child: InkWell(
        onTap: () => engine.setTab(tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: on ? FontWeight.w600 : FontWeight.normal, color: c, height: 1.1),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _indiaGreeting() {
    final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final h = ist.hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _tabBody(BuildContext context) {
    switch (s.activeTab) {
      case 'card':
        return _tabCard(context);
      case 'scan':
        return _tabScan(context);
      case 'assignments':
        return _tabAssignments(context);
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
    final scanGreen = const Color(0xff43a047);

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
          Text(
            s.parsedScanQr?.merchantName?.trim().isNotEmpty == true
                ? s.parsedScanQr!.merchantName!
                : 'Fuel station',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: FleetReactTheme.body),
          ),
          const SizedBox(height: 8),
          Text(
            '${sel.vrn} · ₹${s.parsedScanQr != null ? paiseToInrDisplay(s.parsedScanQr!.amountPaise) : '—'}',
            style: const TextStyle(color: FleetReactTheme.textMuted),
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
          TextField(
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: engine.setSessionPin,
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FleetReactTheme.green700,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(FleetReactTheme.radiusLg),
              ),
            ),
            onPressed: s.qrPayBusy
                ? null
                : (s.sessionPin.length == 6 ? engine.scanVerifyPin : null),
            child: Text(s.qrPayBusy ? 'Processing…' : 'Verify PIN'),
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
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Fueling authorized', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Vehicle ${sel.vrn}', style: const TextStyle(color: Color(0xff718096))),
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (s.sessionState == 'complete') {
      final pay = s.lastQrPay;
      final failed = pay?.payFailed == true;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(
            failed ? Icons.error_outline : Icons.check_circle,
            color: failed ? const Color(0xffdc2626) : const Color(0xff16a34a),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            pay != null
                ? (failed ? 'Transaction failed' : 'Fueling complete')
                : 'Payment complete',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (pay?.amountINR != null)
            Text('Amount ₹${pay!.amountINR!.toStringAsFixed(2)}',
                style: TextStyle(color: failed ? const Color(0xffdc2626) : const Color(0xff15803d), fontWeight: FontWeight.w600)),
          Text(sel != null ? 'Vehicle ${sel.vrn}' : '', style: const TextStyle(color: Color(0xff718096))),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: engine.scanDismissSessionComplete,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          height: 220,
          decoration: BoxDecoration(color: const Color(0xff111827), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Icon(Icons.qr_code_2, size: 72, color: Colors.white54)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
          onPressed: () {
            if (s.useLiveDriverApp) {
              engine.scanSimulateDemoQr();
            } else {
              engine.scanBeginConfirmation();
            }
          },
          child: Text(s.useLiveDriverApp ? 'Simulate fleetpay scan' : 'Simulate Scan'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final raw = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const FleetpayQrScanScreen()),
            );
            if (!context.mounted || raw == null) return;
            engine.applyFleetpayQrRaw(raw);
          },
          child: const Text('Scan QR with camera'),
        ),
      ],
    );
  }

  Widget _tabAssignments(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: s.bindings.map((b) {
        return Card(
          child: ListTile(
            title: Text(b.vrn, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.fo),
                Text(b.state),
                if (b.scanPayStatus == 'locked_unpaired') const Text('Pair to unlock'),
              ],
            ),
          ),
        );
      }).toList(),
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
              _profileRow('Registered', '—'),
              const Divider(height: 1),
              _profileRow('Fleet Operator', '—'),
              const Divider(height: 1),
              _profileRow('Driver ID', s.profile.id),
              const Divider(height: 1),
              _profileRow('Licence Number', '—'),
            ],
          ),
        ),
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
