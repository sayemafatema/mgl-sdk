import 'package:flutter/material.dart';

import 'fleet_app_engine.dart';
import 'fleet_demo_data.dart';
import 'fleet_react_theme.dart';

/// Assignments tab — parity with Android `AssignmentsTab`.
class FleetAssignmentsTab extends StatefulWidget {
  const FleetAssignmentsTab({super.key, required this.engine, required this.snapshot});

  final FleetAppEngine engine;
  final FleetAppSnapshot snapshot;

  @override
  State<FleetAssignmentsTab> createState() => _FleetAssignmentsTabState();
}

class _FleetAssignmentsTabState extends State<FleetAssignmentsTab> {
  FleetBinding? _detailBinding;

  FleetAppEngine get engine => widget.engine;
  FleetAppSnapshot get s => widget.snapshot;

  List<FleetBinding> get _active =>
      s.bindings.where((b) => b.paired && b.state == 'ACTIVE').toList();

  List<FleetBinding> get _pending =>
      s.bindings.where((b) => b.state == 'PENDING_ACCEPTANCE').toList();

  List<FleetBinding> get _repair =>
      s.bindings.where((b) => b.scanPayStatus == 'locked_repair').toList();

  bool _scanDisabled(FleetBinding b) =>
      b.scanPayStatus == 'out_window' ||
      b.scanPayStatus == 'locked_unpaired' ||
      b.scanPayStatus == 'locked_repair';

  void _openDetails(FleetBinding b) => setState(() => _detailBinding = b);

  @override
  Widget build(BuildContext context) {
    final needs = _pending.length + _repair.length;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('My Vehicles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              '${_active.length} active · $needs need attention',
              style: const TextStyle(fontSize: 12, color: FleetReactTheme.gray500),
            ),
            const SizedBox(height: 16),
            ..._active.map((b) => _activeCard(context, b)),
            if (_pending.isNotEmpty || _repair.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'NEEDS ATTENTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FleetReactTheme.warning,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ..._pending.map((b) => _pendingCard(b)),
              ..._repair.map((b) => _repairCard(b)),
            ],
            if (_active.isEmpty && _pending.isEmpty && _repair.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No vehicles yet',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        'Your Fleet Operator will assign vehicles here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_detailBinding != null) _detailSheet(context, _detailBinding!),
      ],
    );
  }

  Widget _activeCard(BuildContext context, FleetBinding b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 8, color: FleetReactTheme.primaryCta),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(b.vrn,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: FleetReactTheme.blue50,
                        border: Border.all(color: FleetReactTheme.primaryCta),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Active',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FleetReactTheme.green700))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(b.fo.trim().isEmpty ? '—' : b.fo,
                    style: const TextStyle(color: FleetReactTheme.gray500))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance', style: TextStyle(color: FleetReactTheme.gray500)),
                    Text('₹${b.balance ?? 0}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _actionTile(
                    icon: Icons.qr_code_2,
                    label: 'Scan & Pay',
                    color: FleetReactTheme.green600,
                    enabled: !_scanDisabled(b),
                    onTap: () => engine.openScanForBinding(b.id),
                  ),
                ),
                Expanded(
                  child: _actionTile(
                    icon: Icons.list_alt,
                    label: 'Transactions',
                    onTap: () => engine.openTransactionsForBinding(b.id),
                  ),
                ),
                Expanded(
                  child: _actionTile(
                    icon: Icons.info_outline,
                    label: 'Details',
                    onTap: () => _openDetails(b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: enabled ? (color ?? const Color(0xff6b7280)) : Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: enabled ? (color ?? const Color(0xff4b5563)) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard(FleetBinding b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xfffcd34d), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.vrn,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xfffef3c7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Action needed',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffb45309))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Assigned by ${b.assignedBy?.trim().isNotEmpty == true ? b.assignedBy : 'your Fleet Operator'}',
                style: const TextStyle(fontSize: 12, color: Color(0xff6b7280))),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.lock, size: 16, color: Color(0xffb45309)),
                SizedBox(width: 8),
                Text('Pair to unlock Scan & Pay',
                    style: TextStyle(color: Color(0xffb45309))),
              ],
            ),
            const Divider(height: 24),
            FilledButton(
              onPressed: () => engine.openAssignmentForBinding(b.id),
              style: FilledButton.styleFrom(backgroundColor: FleetReactTheme.green700),
              child: const Text('Accept & Pair'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => engine.requestDeclineConfirm(b.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xffdc2626),
                side: const BorderSide(color: Color(0xfffecaca)),
              ),
              child: const Text('Decline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _repairCard(FleetBinding b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xfffca5a5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.vrn,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xfffee2e2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Re-pair required',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffb91c1c))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${b.repairReason?.trim().isNotEmpty == true ? b.repairReason : 'Re-pair required'}',
              style: const TextStyle(fontSize: 12, color: FleetReactTheme.gray500),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.lock, size: 16, color: Color(0xffdc2626)),
                SizedBox(width: 8),
                Text('Scan & Pay locked until re-paired',
                    style: TextStyle(color: Color(0xffdc2626))),
              ],
            ),
            const Divider(height: 24),
            OutlinedButton(
              onPressed: () => engine.openPairingForBinding(b.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xffb45309),
                side: const BorderSide(color: Color(0xfffde68a)),
              ),
              child: const Text('Enter new pairing code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSheet(BuildContext context, FleetBinding b) {
    final isTrip = b.authMode == 'trip_linked';
    final isShift = b.authMode == 'shift_based';
    return GestureDetector(
      onTap: () => setState(() => _detailBinding = null),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (_, scroll) {
              return Material(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isTrip
                                ? 'Trip details'
                                : isShift
                                    ? 'Shift schedule'
                                    : b.vrn,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _detailBinding = null),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (isTrip) ...[
                      _detailRow('Vehicle', b.vrn),
                      _detailRow('Date', b.tripDate ?? '—'),
                      _detailRow('Window', '${b.tripStart ?? ''} – ${b.tripEnd ?? ''}'.trim()),
                      _detailRow('From', b.origin?.trim().isNotEmpty == true ? b.origin! : '—'),
                      _detailRow('To', b.destination?.trim().isNotEmpty == true ? b.destination! : '—'),
                      _detailRow('Notes', 'Client delivery'),
                    ] else if (isShift) ...[
                      if (b.shiftDays != null && b.shiftDays!.isNotEmpty)
                        ...b.shiftDays!.map(
                          (day) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(day),
                                Text('${b.shiftStart ?? ''} – ${b.shiftEnd ?? ''}',
                                    style: const TextStyle(fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                        )
                      else
                        Text('${b.shiftStart ?? ''} – ${b.shiftEnd ?? ''}',
                            style: const TextStyle(fontFamily: 'monospace')),
                    ] else ...[
                      _detailRow('Balance', '₹${b.balance ?? 0}'),
                      _detailRow('Fleet Operator', b.fo.trim().isEmpty ? '—' : b.fo),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(k, style: const TextStyle(color: Color(0xff6b7280), fontSize: 13))),
          Expanded(
            flex: 2,
            child: Text(v,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
