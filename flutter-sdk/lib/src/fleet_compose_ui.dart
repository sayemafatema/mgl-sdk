import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fleet_react_theme.dart';

/// MGL logo + "Driver App" — Android `LoginScreen` header.
class FleetBrandHeader extends StatelessWidget {
  const FleetBrandHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: FleetReactTheme.logoBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FleetReactTheme.logoBorder.withValues(alpha: 0.8)),
          ),
          child: Image.asset(
            'assets/mgl_logo.png',
            height: compact ? 28 : 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              'MGL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 14 : 16,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        if (!compact)
          const Text(
            'Driver App',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: FleetReactTheme.gray500),
          )
        else
          const Text(
            'Welcome back',
            style: TextStyle(fontSize: 14, color: FleetReactTheme.textMuted),
          ),
      ],
    );
  }
}

/// White bordered card for auth steps.
class FleetAuthCard extends StatelessWidget {
  const FleetAuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FleetReactTheme.radiusLg),
        side: const BorderSide(color: FleetReactTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

/// +91 mobile row — Compose login field.
class FleetMobileInputRow extends StatelessWidget {
  const FleetMobileInputRow({
    super.key,
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FleetReactTheme.redBg,
              border: Border.all(color: FleetReactTheme.redBorder),
              borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
            ),
            child: Text(errorText!, style: const TextStyle(fontSize: 14, color: FleetReactTheme.redText)),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: FleetReactTheme.cardBorder),
            borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('+91', style: TextStyle(fontSize: 14, color: FleetReactTheme.textMuted)),
              ),
              Container(width: 1, height: 48, color: FleetReactTheme.cardBorder),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '98765 01234',
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14, color: FleetReactTheme.textPrimary),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Six OTP boxes — Android `SixDigitOtpFields`.
class FleetOtpFields extends StatefulWidget {
  const FleetOtpFields({
    super.key,
    required this.onDigit,
    this.refocusKey = 0,
  });

  final void Function(int index, String digit) onDigit;
  final int refocusKey;

  @override
  State<FleetOtpFields> createState() => _FleetOtpFieldsState();
}

class _FleetOtpFieldsState extends State<FleetOtpFields> {
  final List<TextEditingController> _c = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _f = List.generate(6, (_) => FocusNode());

  @override
  void didUpdateWidget(FleetOtpFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refocusKey != widget.refocusKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _f[0].requestFocus();
      });
    }
  }

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
      children: List.generate(6, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: _c[i],
                focusNode: _f[i],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FleetReactTheme.radiusSm),
                  ),
                ),
                onChanged: (v) {
                  widget.onDigit(i, v);
                  _c[i].clear();
                  if (v.isNotEmpty && i < 5) _f[i + 1].requestFocus();
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// PIN dots — hollow rings, Android `PinDots`.
class FleetPinDots extends StatelessWidget {
  const FleetPinDots({super.key, required this.filled, this.bad = false});

  final int filled;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final color = bad ? FleetReactTheme.red600 : FleetReactTheme.green700;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          final on = i < filled;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? color : Colors.transparent,
              border: Border.all(color: on ? color : Colors.grey.shade400, width: 2),
            ),
          );
        }),
      ),
    );
  }
}

/// Numpad — Android `Numpad` (outlined digits + red backspace row).
class FleetNumpad extends StatelessWidget {
  const FleetNumpad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.disabled = false,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool disabled;

  Widget _digit(String d) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: disabled ? null : () => onDigit(d),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: FleetReactTheme.cardBorder),
          ),
          child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(children: [_digit('1'), _digit('2'), _digit('3')]),
          const SizedBox(height: 8),
          Row(children: [_digit('4'), _digit('5'), _digit('6')]),
          const SizedBox(height: 8),
          Row(children: [_digit('7'), _digit('8'), _digit('9')]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: disabled ? null : onBackspace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FleetReactTheme.numpadBackspaceBg,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('← Backspace', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              _digit('0'),
            ],
          ),
        ],
      ),
    );
  }
}

class FleetOtpInfoBanner extends StatelessWidget {
  const FleetOtpInfoBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FleetReactTheme.blue50,
        border: Border.all(color: FleetReactTheme.blue200),
        borderRadius: BorderRadius.circular(FleetReactTheme.radiusMd),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: FleetReactTheme.body, color: FleetReactTheme.blue900, height: 1.4),
      ),
    );
  }
}

/// Shell header — Android `MainHeader`.
class FleetMainHeader extends StatelessWidget {
  const FleetMainHeader({
    super.key,
    required this.greeting,
    required this.driverName,
    required this.initials,
  });

  final String greeting;
  final String driverName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      color: FleetReactTheme.headerBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(color: FleetReactTheme.headerMuted, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                driverName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FleetReactTheme.headerAvatarBg,
              shape: BoxShape.circle,
              border: Border.all(color: Color(0x1affffff)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation — Android `BottomNav`.
class FleetBottomNav extends StatelessWidget {
  const FleetBottomNav({
    super.key,
    required this.currentTab,
    required this.onTab,
  });

  final String currentTab;
  final ValueChanged<String> onTab;

  static const _items = [
    ('card', Icons.home_outlined, Icons.home, 'Home'),
    ('scan', Icons.qr_code_2, Icons.qr_code_2, 'Scan & Pay'),
    ('assignments', Icons.local_shipping_outlined, Icons.local_shipping, 'My Vehicles'),
    ('profile', Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: FleetReactTheme.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: _items.map((e) {
            final selected = currentTab == e.$1;
            return Expanded(
              child: InkWell(
                onTap: () => onTab(e.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? e.$3 : e.$2,
                        size: 24,
                        color: selected ? FleetReactTheme.green700 : FleetReactTheme.gray500,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.$4,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                          color: selected ? FleetReactTheme.green700 : FleetReactTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

String fleetIndiaGreeting() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Good Morning';
  if (h >= 12 && h < 17) return 'Good Afternoon';
  return 'Good Evening';
}
