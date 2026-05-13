import 'fleet_demo_data.dart';
import 'fleet_live_models.dart';
import 'fleetpay_qr.dart';

List<String>? _parseShiftDays(String? csv) {
  if (csv == null || csv.trim().isEmpty) return null;
  return csv.split(',').map((d) {
    final t = d.trim();
    if (t.length < 2) return t;
    return t.substring(0, 1) + t.substring(1, t.length < 3 ? t.length : 3).toLowerCase();
  }).toList();
}

String _assignmentTypeToAuthMode(String t) {
  switch (t.toUpperCase()) {
    case 'WHOLE_TIME':
      return 'vehicle_linked';
    case 'SHIFT':
      return 'shift_based';
    default:
      return 'trip_linked';
  }
}

/// Mirrors Android [mapAssignmentsToDemoBindings].
List<FleetBinding> mapAssignmentsToFleetBindings(
  DriverHomeJson? home,
  List<DriverAssignmentJson> rows,
) {
  final homeVrn =
      home?.vehicleRegNo != null ? normVrnPublic(home!.vehicleRegNo!) : '';
  final hasHomeVrn = homeVrn.isNotEmpty;

  return rows.map((a) {
    final authMode = _assignmentTypeToAuthMode(a.assignmentType);
    final vrnKey = normVrnPublic(a.vehicleRegNo);
    final matchesHome =
        home?.hasActiveVehicle == true && hasHomeVrn && vrnKey == homeVrn;
    final activeEligible = a.status == 'ACTIVE' && !a.requiresPairing;
    final homeEligible = home?.isCurrentlyEligible == true ||
        home?.currentlyEligible == true ||
        (home?.isCurrentlyEligible == null &&
            home?.currentlyEligible == null &&
            activeEligible);
    final eligible = matchesHome ? homeEligible : activeEligible;

    String scanPay;
    if (a.status == 'PENDING_ACCEPTANCE' && a.requiresPairing) {
      scanPay = 'locked_unpaired';
    } else if (!eligible) {
      scanPay = 'out_window';
    } else if (a.assignmentType.toUpperCase() == 'WHOLE_TIME') {
      scanPay = 'always_available';
    } else if (a.assignmentType.toUpperCase() == 'SHIFT') {
      scanPay = 'in_window';
    } else {
      scanPay = 'trip_window';
    }

    final balance = (matchesHome && home?.totalBalanceINR != null)
        ? home!.totalBalanceINR!.round()
        : 0;
    final foFromHome = (matchesHome &&
            home?.foName != null &&
            home!.foName!.trim().isNotEmpty)
        ? home.foName!.trim()
        : '';

    final state =
        a.status == 'PENDING_ACCEPTANCE' ? 'PENDING_ACCEPTANCE' : 'ACTIVE';
    final paired = !(a.status == 'PENDING_ACCEPTANCE' && a.requiresPairing);

    return FleetBinding(
      id: a.vehicleDriverId.toString(),
      vrn: a.vehicleRegNo,
      fo: foFromHome,
      authMode: authMode,
      state: state,
      paired: paired,
      scanPayStatus: scanPay,
      vehicleId: a.vehicleId.isNotEmpty ? a.vehicleId : null,
      shiftDays: _parseShiftDays(a.shiftDaysOfWeek) ?? const [],
      shiftStart: a.shiftStartTime ?? '',
      shiftEnd: a.shiftEndTime ?? '',
      tripDate: a.tripDate ?? '',
      tripStart: a.tripStartTime ?? '',
      tripEnd: a.tripEndTime ?? '',
      origin: a.tripStartLocation ?? '',
      destination: '',
      balance: balance,
      cardBalance: balance,
      incentiveBalance: 0,
      assignedAt: a.assignedAt,
    );
  }).toList();
}

FleetDriverProfile mapLiveProfile(
  DriverProfileJson p,
  String mobileDigits,
) {
  final name = p.name.trim().isEmpty ? 'Driver' : p.name.trim();
  final initials = name.isEmpty
      ? 'D'
      : name
          .split(RegExp(r'\s+'))
          .where((x) => x.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();
  final mob = mobileDigits.replaceAll(RegExp(r'\D'), '');
  final last4 = mob.length >= 4 ? mob.substring(mob.length - 4) : mob;
  final mask = p.maskedMobile?.trim().isNotEmpty == true
      ? p.maskedMobile!
      : '+91 ${'•' * 6}$last4';
  return FleetDriverProfile(
    id: p.driverId.isEmpty ? 'DRV' : p.driverId,
    name: name,
    initials: initials.isEmpty ? 'D' : initials,
    mobile: mob,
    maskedMobile: mask,
    registered: true,
  );
}
