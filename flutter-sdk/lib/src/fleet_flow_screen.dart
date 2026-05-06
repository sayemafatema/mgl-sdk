import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fleet_app_engine.dart';
import 'fleet_demo_data.dart';

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
      backgroundColor: const Color(0xfff3f4f6),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xfff3f4f6),
              child: s.authStep != 'complete'
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
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
      child: _authBody(context),
    );
  }

  Widget _authBody(BuildContext context) {
    switch (s.authStep) {
      case 'login':
        return _login(context);
      case 'login_otp':
        return _loginOtp(context);
      case 'pin_login':
        return _pinLogin(context);
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
      case 'invite_mobile':
        return _inviteMobile(context);
      case 'invite_otp':
        return _inviteOtp(context);
      case 'invite_code':
        return _inviteCode(context);
      case 'invite_pin':
        return _invitePin(context);
      case 'invite_confirm_pin':
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
          onPressed: s.mobileNumber.length == 10 ? engine.loginSendOtp : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
        const Text('Verify mobile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xffeff6ff),
            border: Border.all(color: const Color(0xffbfdbfe)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('OTP sent (demo — enter 123456)'),
        ),
        const SizedBox(height: 12),
        _OtpRow(key: ValueKey(s.authStep), onDigit: engine.setLoginOtpDigit),
        if (s.otpErrorLogin.isNotEmpty)
          Text(s.otpErrorLogin, style: const TextStyle(color: Color(0xffb91c1c))),
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
        const Text('Enter PIN (demo 123456)', style: TextStyle(fontWeight: FontWeight.w600)),
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
    final ok = s.inviteCode.length == 6 && mockInviteCompanies[s.inviteCode] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: engine.authBack, child: const Text('← Back')),
        const Text('Invite code'),
        TextField(
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: _inpDec('ABC123'),
          controller: inviteCodeCtrl,
          onChanged: engine.setInviteCode,
        ),
        if (ok)
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
          onPressed: ok ? engine.inviteContinue : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
          onPressed: s.mobileNumber.length == 10 ? engine.inviteSendOtp : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xff047857)),
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
        const Text('Verify OTP'),
        const SizedBox(height: 12),
        _OtpRow(key: ValueKey(s.authStep), onDigit: engine.setInviteOtpDigit),
        const Text('Auto-advances on 123456', style: TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _invitePin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

class _MainPane extends StatelessWidget {
  const _MainPane({required this.engine, required this.s});

  final FleetAppEngine engine;
  final FleetAppSnapshot s;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: s.mainOverlay != 'home' ? _overlay(context) : _home(context),
        ),
      ],
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
              FilledButton(onPressed: engine.submitPairingCode, child: const Text('Pair')),
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
    final tabs = ['card', 'scan', 'assignments', 'transactions', 'profile'];
    final idx = tabs.indexOf(s.activeTab).clamp(0, tabs.length - 1);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xff059669),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                  Text(s.profile.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              CircleAvatar(child: Text(s.profile.initials)),
            ],
          ),
        ),
        if (s.successToast != null)
          Container(
            width: double.infinity,
            color: const Color(0xff059669),
            padding: const EdgeInsets.all(10),
            child: Text(s.successToast!, style: const TextStyle(color: Colors.white)),
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
        Expanded(child: _tabBody(context)),
        NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => engine.setTab(tabs[i]),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.credit_card), label: 'Card'),
            NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
            NavigationDestination(icon: Icon(Icons.assignment), label: 'Assign'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Txns'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
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
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (s.bindings.isNotEmpty && pending > 0)
          Material(
            color: const Color(0xfffffbeb),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              title: Text('$pending assignment(s) need attention'),
              trailing: TextButton(onPressed: () => engine.setTab('assignments'), child: const Text('View')),
            ),
          ),
        if (c != null) ...[
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
                            c.fo,
                            style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey[600]),
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
                          const SizedBox(height: 8),
                          Text(
                            'Spend limit ₹${c.spendLimit} per fueling',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
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
                    icon: const Icon(Icons.chevron_left),
                  ),
                ),
              if (s.activeCardIndex < cards.length - 1)
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () => engine.setActiveCardIndex(s.activeCardIndex + 1),
                    icon: const Icon(Icons.chevron_right),
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
                    color: i == s.activeCardIndex ? const Color(0xff43a047) : const Color(0xffd1d5db),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => engine.setTab('scan'), child: const Text('Scan & Pay')),
          const SizedBox(height: 16),
          const Text('Recent', style: TextStyle(fontWeight: FontWeight.bold)),
          ...s.transactions.take(3).map((t) => ListTile(
                title: Text(t.station),
                subtitle: Text(t.date),
                trailing: Text('-₹${t.amount}', style: const TextStyle(color: Color(0xffdc2626))),
              )),
        ],
      ],
    );
  }

  Widget _tabScan(BuildContext context) {
    final avail = engine.scanAvailableBindings();
    final sel = engine.selectedScanBinding();
    if (avail.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Scan unavailable — check assignments.'),
          OutlinedButton(onPressed: () => engine.setTab('assignments'), child: const Text('Go to Assignments')),
        ],
      );
    }
    if (s.sessionState == 'confirmation' && sel != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confirm fueling', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(onPressed: engine.scanCancelConfirmation, icon: const Icon(Icons.close)),
            ],
          ),
          const Text('Station · MGL Hind CNG'),
          Text('${sel.vrn} · ₹${sel.balance}'),
          TextField(
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'Authorize PIN', counterText: ''),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: engine.setSessionPin,
          ),
          FilledButton(onPressed: engine.scanConfirmAuthorize, child: const Text('Authorize')),
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
        Container(
          margin: const EdgeInsets.all(16),
          height: 220,
          decoration: BoxDecoration(color: const Color(0xff111827), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Icon(Icons.qr_code_2, size: 72, color: Colors.white54)),
        ),
        FilledButton(onPressed: engine.scanBeginConfirmation, child: const Text('Simulate scan')),
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
    return ListView(
      children: s.transactions.map((t) {
        return ListTile(
          title: Text(t.station),
          subtitle: Text('${t.date} · ${t.type}'),
          trailing: Text('₹${t.amount}', style: const TextStyle(color: Color(0xffdc2626))),
        );
      }).toList(),
    );
  }

  Widget _tabProfile(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(s.profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(s.profile.maskedMobile),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: engine.logout, child: const Text('Log out')),
      ],
    );
  }
}
