import 'package:flutter/material.dart';
import 'fleet_fueling_receipt_share.dart';
import 'fleet_live_models.dart';
import 'fleet_react_theme.dart';

String formatReceiptAmount(double? inr) {
  if (inr == null || !inr.isFinite) return '—';
  final v = inr.abs();
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  return '₹$s';
}

String formatReceiptDate(String? iso) {
  final t = iso?.trim() ?? '';
  if (t.isEmpty) return '—';
  try {
    final d = DateTime.parse(t);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return t;
  }
}

class FleetScanReceiptView extends StatelessWidget {
  const FleetScanReceiptView({
    super.key,
    required this.pay,
    required this.vrn,
    this.driverName,
    this.stationName,
    required this.onDone,
  });

  final QrPayResultLive pay;
  final String vrn;
  final String? driverName;
  final String? stationName;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final failed = pay.payFailed;
    final amount = formatReceiptAmount(pay.amountINR);
    final txnId = pay.serverTxnId?.trim().isNotEmpty == true ? pay.serverTxnId! : '—';
    final station = stationName?.trim().isNotEmpty == true ? stationName! : '—';
    final auth = pay.authCode?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: failed ? FleetReactTheme.red600 : FleetReactTheme.green600,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        failed ? Icons.close : Icons.check,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      failed ? 'Transaction Failed' : 'Fueling Complete',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: failed ? const Color(0xffb91c1c) : FleetReactTheme.green600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: FleetReactTheme.receiptFooterBg,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: FleetReactTheme.logoBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FleetReactTheme.logoBorder.withValues(alpha: 0.8)),
                      ),
                      child: Image.asset('assets/mgl_logo.png', height: 36, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Official Receipt',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _kv('Station', station),
                    _kv('Vehicle', vrn),
                    if (driverName != null && driverName!.trim().isNotEmpty)
                      _kv('Driver', driverName!.trim()),
                    if (failed) _kv('Status', 'FAILED', valueColor: FleetReactTheme.red600),
                    _kv('Amount', amount,
                        valueColor: failed ? FleetReactTheme.red600 : FleetReactTheme.green600),
                    if (!failed && pay.newBalanceINR != null && pay.newBalanceINR!.isFinite)
                      _kv('New balance', formatReceiptAmount(pay.newBalanceINR),
                          valueColor: FleetReactTheme.green600),
                    if (auth.isNotEmpty) _kv('Auth code', auth),
                    const Divider(color: Color(0xffd1d5db), height: 24),
                    Text(
                      'TXN ID: $txnId',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: FleetReactTheme.gray500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatReceiptDate(pay.txnTime),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: FleetReactTheme.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => FleetFuelingReceiptShare.shareReceiptImage(
            pay: pay,
            vrn: vrn,
            driverName: driverName,
            stationName: stationName,
          ),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share receipt'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onDone,
          style: FilledButton.styleFrom(
            backgroundColor: failed ? const Color(0xff374151) : FleetReactTheme.green600,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(failed ? 'Close' : 'Done'),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 13, color: FleetReactTheme.textMuted))),
          Expanded(
            flex: 2,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? FleetReactTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
