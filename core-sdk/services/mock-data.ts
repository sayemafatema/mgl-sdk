import type {
  Driver,
  FleetBinding,
  FleetDriverProfile,
  FleetTransaction,
  FleetVehicleSummary,
} from '../models/driver';

/** Mirrors React app demo data */
export const MOCK_FLEET_PROFILE: FleetDriverProfile = {
  id: 'DRV001',
  name: 'Ravi Sharma',
  initials: 'RS',
  mobile: '9876501234',
  maskedMobile: '+91 ••••••1234',
  registered: true,
};

export const MOCK_DRIVERS: Driver[] = [
  {
    id: 'fo-drv-1',
    name: 'Ramesh Kumar',
    vrn: 'MH 02 AB 1234',
    status: 'Active',
    cardBalancePaise: 1250000,
  },
  {
    id: 'fo-drv-2',
    name: 'Priya Patel',
    vrn: 'MH 02 CD 5678',
    status: 'Active',
    cardBalancePaise: 820000,
  },
  {
    id: 'fo-drv-3',
    name: 'Suresh Singh',
    vrn: 'MH 02 EF 9012',
    status: 'Inactive',
    cardBalancePaise: 510000,
  },
];

export const MOCK_BINDINGS: FleetBinding[] = [
  {
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
  },
  {
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
  },
  {
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
  },
  {
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
  },
  {
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
  },
];

export const MOCK_VEHICLES: FleetVehicleSummary[] = [
  {
    vrn: 'MH 02 AB 1234',
    company: 'ABC Logistics Pvt. Ltd.',
    authMode: 'Vehicle-linked',
    balance: 14600,
    limit: 2000,
  },
  {
    vrn: 'MH 02 CD 5678',
    company: 'XYZ Transport',
    authMode: 'Day shift 06:00-14:00',
    balance: 8500,
    limit: 1500,
  },
];

export const MOCK_TRANSACTIONS: FleetTransaction[] = [
  {
    id: 'TXN001',
    station: 'MGL Hind CNG Filling',
    vrn: 'MH 02 AB 1234',
    amount: 672,
    date: 'Mar 23, 10:30 AM',
    type: 'Fueling',
    quantity: '4.2 kg',
    status: 'Success',
  },
  {
    id: 'TXN002',
    station: 'NEFT Credit',
    vrn: 'MH 02 AB 1234',
    amount: 10000,
    date: 'Mar 22, 02:15 PM',
    type: 'Credit',
    status: 'Success',
  },
  {
    id: 'TXN003',
    station: 'MGL Kurla Station',
    vrn: 'MH 02 CD 5678',
    amount: 1200,
    date: 'Mar 21, 08:45 AM',
    type: 'Fueling',
    quantity: '7.5 kg',
    status: 'Success',
  },
  {
    id: 'TXN004',
    station: 'MGL Andheri East',
    vrn: 'MH 02 AB 1234',
    amount: 950,
    date: 'Mar 20, 06:20 PM',
    type: 'Fueling',
    quantity: '6.0 kg',
    status: 'Success',
  },
];

export const MOCK_INVITE_CODES: Record<string, string> = {
  ABC123: 'ABC Logistics Pvt. Ltd.',
  XYZ789: 'XYZ Transport',
};

export const MOCK_PAIRING_CODES: Record<
  string,
  { company: string; authorizer: string }
> = {
  '123456': { company: 'ABC Logistics Pvt. Ltd.', authorizer: 'Ramesh Shah' },
  '789012': { company: 'XYZ Transport', authorizer: 'Priya Patel' },
};
