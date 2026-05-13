class FleetDriverProfile {
  const FleetDriverProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.mobile,
    required this.maskedMobile,
    required this.registered,
  });

  final String id;
  final String name;
  final String initials;
  final String mobile;
  final String maskedMobile;
  final bool registered;

  FleetDriverProfile copyWith({bool? registered}) {
    return FleetDriverProfile(
      id: id,
      name: name,
      initials: initials,
      mobile: mobile,
      maskedMobile: maskedMobile,
      registered: registered ?? this.registered,
    );
  }
}

class FleetBinding {
  const FleetBinding({
    required this.id,
    required this.vrn,
    required this.fo,
    required this.authMode,
    required this.state,
    required this.paired,
    required this.scanPayStatus,
    this.balance,
    this.cardBalance,
    this.incentiveBalance,
    this.spendLimit,
    this.shiftDays,
    this.shiftStart,
    this.shiftEnd,
    this.shiftEndsIn,
    this.tripDate,
    this.tripStart,
    this.tripEnd,
    this.tripEndsIn,
    this.origin,
    this.destination,
    this.assignedBy,
    this.validPairingCode,
    this.repairReason,
    this.vehicleId,
  });

  final String id;
  final String vrn;
  final String fo;
  final String authMode;
  final String state;
  final bool paired;
  final String scanPayStatus;
  final num? balance;
  final num? cardBalance;
  final num? incentiveBalance;
  final num? spendLimit;
  final List<String>? shiftDays;
  final String? shiftStart;
  final String? shiftEnd;
  final String? shiftEndsIn;
  final String? tripDate;
  final String? tripStart;
  final String? tripEnd;
  final String? tripEndsIn;
  final String? origin;
  final String? destination;
  final String? assignedBy;
  final String? validPairingCode;
  final String? repairReason;
  final String? vehicleId;

  FleetBinding copy() => FleetBinding(
        id: id,
        vrn: vrn,
        fo: fo,
        authMode: authMode,
        state: state,
        paired: paired,
        scanPayStatus: scanPayStatus,
        balance: balance,
        cardBalance: cardBalance,
        incentiveBalance: incentiveBalance,
        spendLimit: spendLimit,
        shiftDays: shiftDays == null ? null : List<String>.from(shiftDays!),
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        shiftEndsIn: shiftEndsIn,
        tripDate: tripDate,
        tripStart: tripStart,
        tripEnd: tripEnd,
        tripEndsIn: tripEndsIn,
        origin: origin,
        destination: destination,
        assignedBy: assignedBy,
        validPairingCode: validPairingCode,
        repairReason: repairReason,
        vehicleId: vehicleId,
      );
}

class FleetTransaction {
  const FleetTransaction({
    required this.id,
    required this.station,
    required this.vrn,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    this.quantity,
  });

  final String id;
  final String station;
  final String vrn;
  final num amount;
  final String date;
  final String type;
  final String status;
  final String? quantity;

  FleetTransaction copy() => FleetTransaction(
        id: id,
        station: station,
        vrn: vrn,
        amount: amount,
        date: date,
        type: type,
        status: status,
        quantity: quantity,
      );
}

class PairingMeta {
  const PairingMeta({required this.company, required this.authorizer});

  final String company;
  final String authorizer;
}

const FleetDriverProfile mockFleetProfile = FleetDriverProfile(
  id: 'DRV001',
  name: 'Ravi Sharma',
  initials: 'RS',
  mobile: '9876501234',
  maskedMobile: '+91 ••••••1234',
  registered: true,
);

final List<FleetBinding> mockBindings = [
  const FleetBinding(
    id: 'BND001',
    vrn: 'MH 02 AB 1234',
    fo: 'ABC Logistics Pvt. Ltd.',
    authMode: 'vehicle_linked',
    state: 'ACTIVE',
    paired: true,
    scanPayStatus: 'always_available',
    balance: 14600,
    cardBalance: 12500,
    incentiveBalance: 2100,
    spendLimit: 2000,
  ),
  const FleetBinding(
    id: 'BND002',
    vrn: 'MH 02 CD 5678',
    fo: 'ABC Logistics Pvt. Ltd.',
    authMode: 'shift_based',
    state: 'ACTIVE',
    paired: true,
    scanPayStatus: 'in_window',
    shiftDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    shiftStart: '06:00',
    shiftEnd: '14:00',
    shiftEndsIn: '3h 20m',
    balance: 8200,
    cardBalance: 8200,
    incentiveBalance: 0,
    spendLimit: 1500,
  ),
  const FleetBinding(
    id: 'BND003',
    vrn: 'MH 04 GH 9012',
    fo: 'ABC Logistics Pvt. Ltd.',
    authMode: 'trip_linked',
    state: 'ACTIVE',
    paired: true,
    scanPayStatus: 'in_window',
    tripDate: 'Today',
    tripStart: '08:00',
    tripEnd: '18:00',
    tripEndsIn: '7h 20m',
    origin: 'Andheri East',
    destination: 'Pune',
    balance: 5400,
    cardBalance: 5400,
    incentiveBalance: 0,
    spendLimit: 3000,
  ),
  const FleetBinding(
    id: 'BND004',
    vrn: 'MH 06 EF 3456',
    fo: 'ABC Logistics Pvt. Ltd.',
    authMode: 'vehicle_linked',
    state: 'PENDING_ACCEPTANCE',
    paired: false,
    scanPayStatus: 'locked_unpaired',
    balance: 0,
    spendLimit: 2000,
    assignedBy: 'Ramesh Shah',
    validPairingCode: '234567',
  ),
  const FleetBinding(
    id: 'BND005',
    vrn: 'MH 08 KL 7890',
    fo: 'XYZ Transport',
    authMode: 'shift_based',
    state: 'ACTIVE',
    paired: false,
    scanPayStatus: 'locked_repair',
    shiftDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    shiftStart: '22:00',
    shiftEnd: '06:00',
    repairReason: 'Monthly re-verification',
    balance: 3200,
    spendLimit: 1000,
    validPairingCode: '345678',
  ),
];

final List<FleetTransaction> mockTransactions = [
  const FleetTransaction(
    id: 'TXN001',
    station: 'MGL Hind CNG Filling',
    vrn: 'MH 02 AB 1234',
    amount: 672,
    date: 'Mar 23, 10:30 AM',
    type: 'Fueling',
    quantity: '4.2 kg',
    status: 'SUCCESS',
  ),
  const FleetTransaction(
    id: 'TXN002',
    station: 'NEFT Credit',
    vrn: 'MH 02 AB 1234',
    amount: 10000,
    date: 'Mar 22, 02:15 PM',
    type: 'Credit',
    status: 'SUCCESS',
  ),
  const FleetTransaction(
    id: 'TXN003',
    station: 'MGL Kurla Station',
    vrn: 'MH 02 CD 5678',
    amount: 1200,
    date: 'Mar 21, 08:45 AM',
    type: 'Fueling',
    quantity: '7.5 kg',
    status: 'SUCCESS',
  ),
  const FleetTransaction(
    id: 'TXN004',
    station: 'MGL Andheri East',
    vrn: 'MH 02 AB 1234',
    amount: 950,
    date: 'Mar 20, 06:20 PM',
    type: 'Fueling',
    quantity: '6.0 kg',
    status: 'SUCCESS',
  ),
];

const Map<String, String> mockInviteCompanies = {
  'ABC123': 'ABC Logistics Pvt. Ltd.',
  'XYZ789': 'XYZ Transport',
};

const Map<String, PairingMeta> mockPairingCodes = {
  '123456':
      PairingMeta(company: 'ABC Logistics Pvt. Ltd.', authorizer: 'Ramesh Shah'),
  '789012': PairingMeta(company: 'XYZ Transport', authorizer: 'Priya Patel'),
};
