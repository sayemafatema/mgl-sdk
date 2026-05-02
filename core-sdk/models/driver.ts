/** Currency amounts in smallest unit (paise) unless noted */
export type DriverStatus = 'Active' | 'Inactive';

export interface Driver {
  id: string;
  name: string;
  vrn: string;
  status: DriverStatus;
  /** Balance in paise for API parity */
  cardBalancePaise: number;
}

export interface DriverUpdatePayload {
  id: string;
  name?: string;
  status?: DriverStatus;
  /** Balance in paise */
  cardBalancePaise?: number;
}

export interface FleetDriverProfile {
  id: string;
  name: string;
  initials: string;
  mobile: string;
  maskedMobile: string;
  registered: boolean;
}

export type BindingState = 'ACTIVE' | 'PENDING_ACCEPTANCE';

export type AuthMode = 'vehicle_linked' | 'shift_based' | 'trip_linked';

export type ScanPayStatus =
  | 'always_available'
  | 'in_window'
  | 'locked_unpaired'
  | 'locked_repair';

export interface FleetBinding {
  id: string;
  vrn: string;
  fo: string;
  authMode: AuthMode;
  state: BindingState;
  paired: boolean;
  scanPayStatus: ScanPayStatus;
  balance?: number;
  cardBalance?: number;
  incentiveBalance?: number;
  spendLimit?: number;
  shiftDays?: string[];
  shiftStart?: string;
  shiftEnd?: string;
  shiftEndsIn?: string;
  tripDate?: string;
  tripStart?: string;
  tripEnd?: string;
  tripEndsIn?: string;
  origin?: string;
  destination?: string;
  assignedBy?: string;
  validPairingCode?: string;
  repairReason?: string;
}

export interface FleetTransaction {
  id: string;
  station: string;
  vrn: string;
  amount: number;
  date: string;
  type: string;
  quantity?: string;
  status: string;
}

export interface FleetVehicleSummary {
  vrn: string;
  company: string;
  authMode: string;
  balance: number;
  limit: number;
}
