'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { ChevronLeft, X, Lock, MapPin, AlertCircle, User, Clock, Check, CreditCard, Zap, QrCode, History, Phone, Shield, LogOut, Eye, EyeOff, Home, Route, CheckCircle, ArrowDown, ArrowUp } from 'lucide-react';
import {
  driverAcceptPairing,
  driverExchangeOtpToken,
  driverFoList,
  driverFoSelect,
  driverInviteMobileSendOtp,
  driverInviteMobileVerifyOtp,
  driverSendLoginOtp,
  driverQrPay,
  driverCheckMobile,
  driverInviteSetPin,
  driverInviteValidate,
  driverGetAssignments,
  driverGetHome,
  driverGetProfile,
  driverGetTransactions,
  getDriverApiBase,
  mapAssignmentsToUiBindings,
  oauthAccessToken,
  type DriverAssignment,
  type DriverHome,
  type DriverProfile,
  type DriverTxnRow,
  type DriverUiBinding,
  type FoListEntry,
} from '../components/mgl/driver-api';
import { QrCameraScanner } from '../components/mgl/qr-camera-scanner';
import {
  parseFleetpayPayUri,
  paiseToInrDisplay,
  type FleetpayQrPayload,
} from '../components/mgl/fleetpay-qr';

const DRIVER_API_BASE = getDriverApiBase();
const USE_DRIVER_API = DRIVER_API_BASE.length > 0;
const DRIVER_APP_FO_TOKEN_KEY = 'mgl_driver_app_fo_token';

// ============ MOCK DATA - BEFORE COMPONENT ============
const INVITE_CODES_DB: { [key: string]: string } = {
  'ABC123': 'ABC Logistics Pvt. Ltd.',
  'XYZ789': 'XYZ Transport',
};

const PAIRING_CODES_DB: { [key: string]: { company: string; authorizer: string } } = {
  '123456': { company: 'ABC Logistics Pvt. Ltd.', authorizer: 'Ramesh Shah' },
  '789012': { company: 'XYZ Transport', authorizer: 'Priya Patel' },
};

const pairedVehicles = [
  { vrn: 'MH 02 AB 1234', company: 'ABC Logistics Pvt. Ltd.', authMode: 'Vehicle-linked', balance: 14600, limit: 2000 },
  { vrn: 'MH 02 CD 5678', company: 'XYZ Transport', authMode: 'Day shift 06:00-14:00', balance: 8500, limit: 1500 },
];

const mockTransactions = [
  { id: 'TXN001', station: 'MGL Hind CNG Filling', vrn: 'MH 02 AB 1234', amount: 850, date: 'Mar 23, 10:30 AM', dayLabel: '13 Apr', timeLabel: '10:30 AM', type: 'Fueling' as const, quantity: '4.2 kg', status: 'Success' },
  { id: 'TXN002', station: 'Wallet Top-up', vrn: 'MH 02 AB 1234', amount: 10000, date: 'Mar 22, 02:15 PM', dayLabel: '12 Apr', timeLabel: '02:15 PM', type: 'Credit' as const, status: 'Success' },
  { id: 'TXN003', station: 'MGL Kurla Station', vrn: 'MH 02 CD 5678', amount: 1200, date: 'Mar 21, 08:45 AM', dayLabel: '11 Apr', timeLabel: '08:45 AM', type: 'Fueling' as const, quantity: '7.5 kg', status: 'Success' },
  { id: 'TXN004', station: 'MGL Andheri East', vrn: 'MH 02 AB 1234', amount: 950, date: 'Mar 20, 06:20 PM', dayLabel: '10 Apr', timeLabel: '06:20 PM', type: 'Fueling' as const, quantity: '6.0 kg', status: 'Success' },
];

const MOCK_PENDING_BINDING = {
  id: 'BND004',
  vehicleVrn: 'MH 04 GH 9012',
  foName: 'ABC Logistics Pvt. Ltd.',
  authMode: 'trip_linked' as const,
  state: 'PENDING_ACCEPTANCE' as const,
  paired: false,
  tripDate: '14 Apr 2026',
  tripStart: '08:00',
  tripEnd: '18:00',
  origin: 'Andheri East',
  destination: 'Pune',
  tripNotes: 'Client delivery',
  assignedBy: 'Ramesh Shah',
  validPairingCode: '123456',
};

// Global mock data
const PAIRING_CODES_DB_GLOBAL: { [key: string]: { company: string; authorizer: string } } = {
  '123456': { company: 'ABC Logistics Pvt. Ltd.', authorizer: 'Ramesh Shah' },
  '789012': { company: 'XYZ Transport', authorizer: 'Priya Patel' },
};

const DRIVER = {
  id: "DRV001",
  name: "Ravi Sharma",
  initials: "RS",
  mobile: "9876501234",
  maskedMobile: "+91 ••••••1234",
  pin: "123456",
  registered: true,
};

function driverInitialsFromName(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  const one = parts[0] ?? '';
  if (one.length >= 2) return one.slice(0, 2).toUpperCase();
  return one.toUpperCase() || '?';
}

const MOCK_BINDINGS: DriverUiBinding[] = [
  {
    id: "BND001",
    vrn: "MH 02 AB 1234",
    fo: "ABC Logistics Pvt. Ltd.",
    authMode: "vehicle_linked" as const,
    state: "ACTIVE" as const,
    paired: true,
    scanPayStatus: "always_available",
    balance: 14600,
    cardBalance: 12500,
    incentiveBalance: 2100,
    spendLimit: 2000,
  },
  {
    id: "BND002",
    vrn: "MH 02 CD 5678",
    fo: "ABC Logistics Pvt. Ltd.",
    authMode: "shift_based" as const,
    state: "ACTIVE" as const,
    paired: true,
    scanPayStatus: "in_window",
    shiftDays: ["Mon","Tue","Wed","Thu","Fri"],
    shiftStart: "06:00",
    shiftEnd: "14:00",
    shiftEndsIn: "3h 20m",
    balance: 8200,
    cardBalance: 8200,
    incentiveBalance: 0,
    spendLimit: 1500,
  },
  {
    id: "BND003",
    vrn: "MH 04 GH 9012",
    fo: "ABC Logistics Pvt. Ltd.",
    authMode: "trip_linked" as const,
    state: "ACTIVE" as const,
    paired: true,
    scanPayStatus: "in_window",
    tripDate: "Today",
    tripStart: "08:00",
    tripEnd: "18:00",
    tripEndsIn: "7h 20m",
    origin: "Andheri East",
    destination: "Pune",
    balance: 5400,
    cardBalance: 5400,
    incentiveBalance: 0,
    spendLimit: 3000,
  },
  {
    id: "BND004",
    vrn: "MH 06 EF 3456",
    fo: "ABC Logistics Pvt. Ltd.",
    authMode: "vehicle_linked" as const,
    state: "PENDING_ACCEPTANCE" as const,
    paired: false,
    scanPayStatus: "locked_unpaired",
    balance: 0,
    spendLimit: 2000,
    assignedBy: "Ramesh Shah",
    validPairingCode: "234567",
  },
  {
    id: "BND005",
    vrn: "MH 08 KL 7890",
    fo: "XYZ Transport",
    authMode: "shift_based" as const,
    state: "ACTIVE" as const,
    paired: false,
    scanPayStatus: "locked_repair",
    shiftDays: ["Mon","Tue","Wed","Thu","Fri","Sat"],
    shiftStart: "22:00",
    shiftEnd: "06:00",
    repairReason: "Monthly re-verification",
    balance: 3200,
    spendLimit: 1000,
    validPairingCode: "345678",
  },
];

const pairedVehiclesGlobal = [
  { vrn: 'MH 02 AB 1234', company: 'ABC Logistics Pvt. Ltd.', authMode: 'Vehicle-linked', balance: 14600, limit: 2000 },
  { vrn: 'MH 02 CD 5678', company: 'XYZ Transport', authMode: 'Day shift 06:00-14:00', balance: 8500, limit: 1500 },
];

const mockTransactionsGlobal = [
    { id: 'TXN001', station: 'MGL Hind CNG Filling', vrn: 'MH 02 AB 1234', amount: 850, date: 'Mar 23, 10:30 AM', dayLabel: '13 Apr', timeLabel: '10:30 AM', type: 'Fueling' as const, quantity: '4.2 kg', status: 'Success' },
    { id: 'TXN002', station: 'Wallet Top-up', vrn: 'MH 02 AB 1234', amount: 10000, date: 'Mar 22, 02:15 PM', dayLabel: '12 Apr', timeLabel: '02:15 PM', type: 'Credit' as const, status: 'Success' },
    { id: 'TXN003', station: 'MGL Kurla Station', vrn: 'MH 02 CD 5678', amount: 1200, date: 'Mar 21, 08:45 AM', dayLabel: '11 Apr', timeLabel: '08:45 AM', type: 'Fueling' as const, quantity: '7.5 kg', status: 'Success' },
    { id: 'TXN004', station: 'MGL Andheri East', vrn: 'MH 02 AB 1234', amount: 950, date: 'Mar 20, 06:20 PM', dayLabel: '10 Apr', timeLabel: '06:20 PM', type: 'Fueling' as const, quantity: '6.0 kg', status: 'Success' },
];

const mockBindingsGlobal = MOCK_BINDINGS;

export default function Page() {
  // ============ STATE ============
  const [isReturningUser, setIsReturningUser] = useState(true);
  const [onboardingStep, setOnboardingStep] = useState<
    | 'login'
    | 'login_otp'
    | 'pin_login'
    | 'set_pin'
    | 'confirm_pin'
    | 'complete'
    | 'forgot_pin'
    | 'forgot_otp'
    | 'verify_otp_reset'
    | 'set_pin_reset'
    | 'confirm_pin_reset'
    | 'registered'
    | '1b'
    | '1c'
    | '1d'
    | '1e'
    | '1f'
    | 'select_fo'
    | 'fo_pin_login'
  >('login');
  const [inviteCode, setInviteCode] = useState('');
  const [mobileNumber, setMobileNumber] = useState('');
  const [otp, setOtp] = useState('');
  const [otpCountdown, setOtpCountdown] = useState(0);
  const [pin, setPin] = useState('');
  const [pinConfirm, setPinConfirm] = useState('');
  const [pinError, setPinError] = useState('');
  const [loginPin, setLoginPin] = useState('');
  const [loginPinError, setLoginPinError] = useState('');
  const [wrongAttempts, setWrongAttempts] = useState(0);
  const [disableNumpad, setDisableNumpad] = useState(false);
  const [showShake, setShowShake] = useState(false);
  const [sessionState, setSessionState] = useState<
    'idle' | 'scanning' | 'confirmation' | 'pin_confirm' | 'otp_entry' | 'authorized' | 'complete'
  >('idle');
  const [sessionPin, setSessionPin] = useState('');
  const [sessionOtp, setSessionOtp] = useState('');
  const [dispensingAmount, setDispensingAmount] = useState(0);
  const [pairingCode, setPairingCode] = useState('');
  const [pairingError, setPairingError] = useState('');
  const [activeTab, setActiveTab] = useState<'card' | 'scan' | 'assignments' | 'transactions' | 'profile'>('card');
  const [txnFilter, setTxnFilter] = useState<'all' | 'successful' | 'failed'>('all');
  const [currentMainScreen, setCurrentMainScreen] = useState<'home_empty' | 'home_active' | 'assignment_notification' | 'pairing_code'>('home_empty');
  const [selectedVehicle, setSelectedVehicle] = useState(0);
  const [activeCard, setActiveCard] = useState(0);
  const [selectedAssignment, setSelectedAssignment] = useState<string | null>(null);
  const [selectedPendingBinding, setSelectedPendingBinding] = useState(MOCK_PENDING_BINDING);
  const [showShiftSchedule, setShowShiftSchedule] = useState(false);
  const [selectedShiftBinding, setSelectedShiftBinding] = useState<DriverUiBinding | null>(null);
  const [showTripDetails, setShowTripDetails] = useState(false);
  const [selectedTripBinding, setSelectedTripBinding] = useState<DriverUiBinding | null>(null);
  const [assignmentDetailBinding, setAssignmentDetailBinding] = useState<DriverUiBinding | null>(null);
  const [declineBndId, setDeclineBndId] = useState<string | null>(null);
  const [activeAssignment, setActiveAssignment] = useState<DriverUiBinding | null>(null);
  const [pairingDigits, setPairingDigits] = useState(Array(6).fill(""));
  const [pairingAttempts, setPairingAttempts] = useState(0);
  const [pairingSuccess, setPairingSuccess] = useState(false);
  const [showDeclineConfirm, setShowDeclineConfirm] = useState(false);
  const [showPairingHelp, setShowPairingHelp] = useState(false);
  const [devMenuTaps, setDevMenuTaps] = useState(0);
  const [showDevMenu, setShowDevMenu] = useState(false);
  const [newPin, setNewPin] = useState("");
  const [isNewUser, setIsNewUser] = useState(false);
  const [successToast, setSuccessToast] = useState<string | null>(null);
  const [isRegistered, setIsRegistered] = useState(true);
  const [otpDigits, setOtpDigits] = useState(Array(6).fill(''));
  const [otpError, setOtpError] = useState('');
  const [inviteFlowOtpError, setInviteFlowOtpError] = useState('');
  const [activeScanBinding, setActiveScanBinding] = useState<DriverUiBinding | null>(null);
  const [selectedScanBinding, setSelectedScanBinding] = useState<DriverUiBinding | null>(null);
  const [foScopedToken, setFoScopedToken] = useState<string | null>(null);
  const [otpPhaseToken, setOtpPhaseToken] = useState<string | null>(null);
  const [inviteSessionToken, setInviteSessionToken] = useState<string | null>(null);
  const [inviteOtpRefNumber, setInviteOtpRefNumber] = useState<string | null>(null);
  const [inviteMobileVerificationToken, setInviteMobileVerificationToken] = useState<string | null>(null);
  const [validatedInvitePreview, setValidatedInvitePreview] = useState<{ driverName: string; foName: string } | null>(null);
  const [foOrganizationList, setFoOrganizationList] = useState<FoListEntry[]>([]);
  const [selectedFoCompanyId, setSelectedFoCompanyId] = useState<number | null>(null);
  const [apiHome, setApiHome] = useState<DriverHome | null>(null);
  const [apiProfileState, setApiProfileState] = useState<DriverProfile | null>(null);
  const [apiAssignments, setApiAssignments] = useState<DriverAssignment[]>([]);
  const [apiTxns, setApiTxns] = useState<DriverTxnRow[]>([]);
  const [apiBanner, setApiBanner] = useState<string | null>(null);
  const [foPinEntry, setFoPinEntry] = useState('');
  const [qrTxnId, setQrTxnId] = useState('QR-DEMO-LOCAL');
  const [qrPayFields, setQrPayFields] = useState<FleetpayQrPayload | null>(null);

  const pairingRefs = [
    useRef(null), useRef(null), useRef(null),
    useRef(null), useRef(null), useRef(null)
  ];

  // ============ DERIVED STATE ============
  const PAIRING_CODES_DB = PAIRING_CODES_DB_GLOBAL;
  const pairedVehicles = pairedVehiclesGlobal;
  const mockTransactions = mockTransactionsGlobal;
  const mockBindings = mockBindingsGlobal;
  const screenBindings: DriverUiBinding[] =
    USE_DRIVER_API && onboardingStep === 'complete' && foScopedToken
      ? mapAssignmentsToUiBindings(apiHome, apiAssignments)
      : MOCK_BINDINGS;
  const currentVehicle = pairedVehicles[selectedVehicle];
  const activeCards = screenBindings.filter((b) => b.paired && b.state === 'ACTIVE');
  const currentCard = activeCards[activeCard];
  const pendingAssignmentCount = screenBindings.filter((b) => b.state === 'PENDING_ACCEPTANCE' || (!b.paired && b.state === 'ACTIVE')).length;
  const activeBindings = screenBindings.filter((b) => b.paired && b.state === 'ACTIVE');
  const pendingBindings = screenBindings.filter((b) => b.state === 'PENDING_ACCEPTANCE');
  const repairBindings = screenBindings.filter((b) => !b.paired && b.state === 'ACTIVE');
  const assignmentFallback = screenBindings[3] ?? screenBindings[0] ?? MOCK_BINDINGS[0];
  const driverDisplayName = apiProfileState?.name ?? DRIVER.name;
  const driverDisplayInitials = apiProfileState?.name
    ? driverInitialsFromName(apiProfileState.name)
    : DRIVER.initials;

  // ============ HANDLERS ============
  const handleInviteCodeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const max = USE_DRIVER_API ? 24 : 6;
    const val = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, max);
    setInviteCode(val);
  };

  const handleMobileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value.replace(/\D/g, '').slice(0, 10);
    if (USE_DRIVER_API && val !== mobileNumber) {
      setInviteOtpRefNumber(null);
      setInviteMobileVerificationToken(null);
    }
    setMobileNumber(val);
  };

  const handleOtpChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value.replace(/\D/g, '').slice(0, 6);
    setOtp(val);
  };

  const handlePinInput = (digit: string, isConfirm: boolean = false) => {
    if (isConfirm) {
      if (pinConfirm.length < 6) setPinConfirm(pinConfirm + digit);
    } else {
      if (pin.length < 6) setPin(pin + digit);
    }
  };

  const handlePinBackspace = (isConfirm: boolean = false) => {
    if (isConfirm) {
      setPinConfirm(pinConfirm.slice(0, -1));
    } else {
      setPin(pin.slice(0, -1));
    }
  };

  const handleSessionPinInput = (digit: string) => {
    if (sessionPin.length < 6) setSessionPin(sessionPin + digit);
  };

  const handleSessionPinBackspace = () => {
    setSessionPin(sessionPin.slice(0, -1));
  };

  const handleFleetpayScan = useCallback(
    (text: string) => {
      setApiBanner(null);
      const parsed = parseFleetpayPayUri(text);
      if (!parsed) {
        setApiBanner('Invalid Fleetpay QR. Point at the station QR (must include tid).');
        return;
      }
      if (!selectedScanBinding) {
        setApiBanner('Select a vehicle first.');
        return;
      }
      setQrTxnId(parsed.txnId);
      setQrPayFields(parsed);
      setActiveScanBinding(selectedScanBinding);
      setSessionState('confirmation');
    },
    [selectedScanBinding]
  );

  const handleSessionOtpChange = (idx: number, val: string) => {
    const digit = val.replace(/\D/g, '').slice(-1);
    let newOtp = sessionOtp.split('');
    newOtp[idx] = digit;
    const fullOtp = newOtp.join('');
    setSessionOtp(fullOtp);
    if (digit && idx < 5) {
      const nextInput = document.querySelectorAll('.session-otp-digit')[idx + 1] as HTMLInputElement;
      nextInput?.focus();
    }
  };

  const handleLoginOtpVerify = async () => {
    const enteredOtp = otpDigits.join('');
    if (!USE_DRIVER_API) {
      if (enteredOtp === '123456') {
        if (isRegistered) setOnboardingStep('complete');
        else {
          setIsNewUser(true);
          setNewPin('');
          setPinConfirm('');
          setPinError('');
          setOnboardingStep('set_pin');
        }
      } else {
        setOtpError('Incorrect OTP. Try again.');
        setTimeout(() => {
          setOtpDigits(Array(6).fill(''));
          setOtpError('');
        }, 1500);
      }
      return;
    }
    try {
      setApiBanner(null);
      setOtpError('');
      const tr = await driverExchangeOtpToken(mobileNumber, enteredOtp, DRIVER_API_BASE);
      const partial = oauthAccessToken(tr);
      if (!partial) {
        setOtpError('Login failed: no token.');
        return;
      }
      setOtpPhaseToken(partial);
      const fos = await driverFoList(DRIVER_API_BASE, partial);
      const active = fos.filter((f) => f.foStatus === 'ACTIVE');
      setFoOrganizationList(active);
      if (!active.length) {
        setOtpError('No active fleet — use your invite code.');
        setOtpPhaseToken(null);
        setOtpDigits(Array(6).fill(''));
        return;
      }
      if (active.length === 1) {
        setSelectedFoCompanyId(active[0].foCompanyId);
        setFoPinEntry('');
        setOnboardingStep('fo_pin_login');
      } else {
        setSelectedFoCompanyId(null);
        setOnboardingStep('select_fo');
      }
      setOtpDigits(Array(6).fill(''));
    } catch (e) {
      setOtpError(e instanceof Error ? e.message : String(e));
      setTimeout(() => {
        setOtpDigits(Array(6).fill(''));
        setOtpError('');
      }, 1700);
    }
  };

  const completeOnboarding = () => {
    setOnboardingStep('complete');
  };

  const handleLogout = () => {
    if (typeof window !== 'undefined') {
      try {
        localStorage.removeItem(DRIVER_APP_FO_TOKEN_KEY);
      } catch {
        /* ignore */
      }
    }
    setOnboardingStep('login');
    setInviteCode('');
    setMobileNumber('');
    setOtp('');
    setPin('');
    setPinConfirm('');
    setFoScopedToken(null);
    setOtpPhaseToken(null);
    setInviteSessionToken(null);
    setValidatedInvitePreview(null);
    setFoOrganizationList([]);
    setSelectedFoCompanyId(null);
    setApiHome(null);
    setApiProfileState(null);
    setApiAssignments([]);
    setApiTxns([]);
    setApiBanner(null);
    setFoPinEntry('');
    setOtpDigits(Array(6).fill(''));
  };

  // Numpad component
  const Numpad = ({ onPress, onBackspace, isConfirm = false }: { onPress: (digit: string) => void; onBackspace: () => void; isConfirm?: boolean }) => {
    return (
      <div className="grid grid-cols-3 gap-2 mt-4">
        {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => (
          <button key={num} onClick={() => onPress(num.toString())} className="bg-gray-100 hover:bg-gray-200 rounded-lg py-3 font-semibold text-gray-900 transition">
            {num}
          </button>
        ))}
        <button onClick={onBackspace} className="bg-red-100 hover:bg-red-200 rounded-lg py-3 text-red-700 transition col-span-2">
          ← Backspace
        </button>
        <button onClick={() => onPress('0')} className="bg-gray-100 hover:bg-gray-200 rounded-lg py-3 font-semibold text-gray-900 transition">
          0
        </button>
      </div>
    );
  };

  // PIN display dots
  const PinDisplay = ({ value }: { value: string }) => (
    <div className="flex justify-center gap-3 my-6">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className={`w-4 h-4 rounded-full border-2 ${i < value.length ? 'bg-green-700 border-green-700' : 'border-gray-300'}`} />
      ))}
    </div>
  );

  // ============ EFFECTS ============
  useEffect(() => {
    if (!USE_DRIVER_API || typeof window === 'undefined') return;
    try {
      const t = localStorage.getItem(DRIVER_APP_FO_TOKEN_KEY)?.trim();
      if (t) {
        setFoScopedToken(t);
        setOnboardingStep('complete');
      }
    } catch {
      /* ignore */
    }
  }, []);

  useEffect(() => {
    if (!USE_DRIVER_API || typeof window === 'undefined' || !foScopedToken) return;
    try {
      localStorage.setItem(DRIVER_APP_FO_TOKEN_KEY, foScopedToken);
    } catch {
      /* ignore */
    }
  }, [USE_DRIVER_API, foScopedToken]);

  useEffect(() => {
    if (otpDigits.join('').length === 6 && onboardingStep === 'login_otp') void handleLoginOtpVerify();
  }, [otpDigits, onboardingStep]);

  useEffect(() => {
    if (!USE_DRIVER_API || !foScopedToken || onboardingStep !== 'complete') return;
    let cancelled = false;
    (async () => {
      try {
        setApiBanner(null);
        const [home, profile, assignments, tx] = await Promise.all([
          driverGetHome(DRIVER_API_BASE, foScopedToken),
          driverGetProfile(DRIVER_API_BASE, foScopedToken),
          driverGetAssignments(DRIVER_API_BASE, foScopedToken),
          driverGetTransactions(DRIVER_API_BASE, foScopedToken, 0),
        ]);
        if (!cancelled) {
          setApiHome(home);
          setApiProfileState(profile);
          setApiAssignments(assignments);
          setApiTxns(tx);
        }
      } catch (e) {
        if (cancelled) return;
        const msg = e instanceof Error ? e.message : String(e);
        setApiBanner(msg);
        if (/\b401\b|Unauthorized|invalid_token|expired/i.test(msg)) {
          try {
            localStorage.removeItem(DRIVER_APP_FO_TOKEN_KEY);
          } catch {
            /* ignore */
          }
          setFoScopedToken(null);
          setApiHome(null);
          setApiProfileState(null);
          setApiAssignments([]);
          setApiTxns([]);
          setOnboardingStep('login');
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [USE_DRIVER_API, foScopedToken, onboardingStep]);

  useEffect(() => {
    if (USE_DRIVER_API || onboardingStep !== '1d' || otp.length !== 6) return;
    if (otp === '123456') {
      setInviteFlowOtpError('');
      setOnboardingStep('1b');
    } else {
      setInviteFlowOtpError('Incorrect OTP. Try again.');
      setTimeout(() => {
        setOtp('');
        setInviteFlowOtpError('');
      }, 1500);
    }
  }, [otp, onboardingStep]);

  useEffect(() => {
    if (currentMainScreen === "pairing_code") {
      setPairingDigits(["","","","","",""])
      setTimeout(() => {
        pairingRefs[0].current?.focus()
      }, 100)
    }
  }, [currentMainScreen]);

  // ============ RENDER SCREENS ============

  // Onboarding and PIN Login
  if (onboardingStep !== 'complete') {
    return (
      <div className="relative w-full min-h-screen bg-gray-100 flex flex-col">
          <div className="flex-1 w-full min-h-0 overflow-y-auto flex flex-col justify-center p-6">
            {/* Screen: Login */}
            {onboardingStep === 'login' && (
              <>
                <div className="flex flex-col h-full">
                  {/* Top Section */}
                  <div className="text-center space-y-3 mb-8 flex flex-col items-center">
                    <img src="/mgl-logo.png" alt="MGL Fleet" className="w-18 h-18 object-contain" />
                    <p className="text-bold text-xl text-gray-900 font-poppins">MGL Fleet Connect</p>
                    <p className="text-xs text-gray-500 font-poppins">Driver App</p>
                  </div>

                  {/* Spacer */}
                  <div className="flex-1" />

                  {/* Bottom Section */}
                  <div className="space-y-4">
                    <div>
                      <label className="text-xs text-gray-600 font-medium">Mobile number</label>
                      <div className="flex gap-2 mt-2">
                        <span className="flex items-center px-3 py-3 border border-gray-300 rounded-xl text-gray-600 bg-gray-50 font-medium text-sm">+91</span>
                        <input
                          type="tel"
                          value={mobileNumber}
                          onChange={(e) => setMobileNumber(e.target.value.replace(/\D/g, '').slice(0, 10))}
                          placeholder="Enter your mobile number"
                          inputMode="numeric"
                          maxLength={10}
                          className="flex-1 px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-700 focus:border-green-700"
                        />
                      </div>
                    </div>

                    <button
                      onClick={() => {
                        void (async () => {
                          setApiBanner(null);
                          setOtpDigits(Array(6).fill(''));
                          setOtpError('');
                          try {
                            if (USE_DRIVER_API) {
                              const cm = await driverCheckMobile(DRIVER_API_BASE, mobileNumber);
                              if (cm === 'NEW_USER') {
                                setApiBanner('New user — continue with invite code.');
                                setInviteOtpRefNumber(null);
                                setInviteMobileVerificationToken(null);
                                setOnboardingStep('1c');
                                return;
                              }
                              await driverSendLoginOtp(DRIVER_API_BASE, mobileNumber);
                            }
                            setOtpCountdown(30);
                            setOnboardingStep('login_otp');
                          } catch (e) {
                            setOtpError(e instanceof Error ? e.message : String(e));
                          }
                        })();
                      }}
                      disabled={mobileNumber.length !== 10}
                      className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-xl transition"
                    >
                      Send OTP
                    </button>

                    <div className="flex items-center gap-3 my-5">
                      <div className="flex-1 h-px bg-gray-300" />
                      <span className="text-xs text-gray-500">or</span>
                      <div className="flex-1 h-px bg-gray-300" />
                    </div>

                    <button
                      onClick={() => {
                        setInviteCode('');
                        setOtp('');
                        setInviteFlowOtpError('');
                        setInviteOtpRefNumber(null);
                        setInviteMobileVerificationToken(null);
                        setMobileNumber('');
                        setOnboardingStep('1c');
                      }}
                      className="w-full border border-gray-300 text-gray-700 hover:bg-gray-50 font-medium py-3 rounded-xl transition"
                    >
                      New user? I have an invite code
                    </button>

                    <p className="text-xs text-gray-400 text-center mt-6">
                      By continuing you agree to MGL Fleet Terms of Service
                    </p>
                  </div>
                </div>
              </>
            )}

            {/* Screen: Login OTP */}
            {onboardingStep === 'login_otp' && (
              <>
                <button onClick={() => setOnboardingStep('login')} className="flex items-center gap-2 text-gray-600 mb-6">
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Verify mobile</h2>

                <div className="bg-blue-50 border border-blue-200 rounded-xl p-3 mb-6">
                  <p className="text-sm text-blue-900">OTP sent to +91 {mobileNumber.slice(-4).padStart(10, '•')}</p>
                </div>

                <div className="flex justify-center gap-1 mb-6">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <input
                      key={i}
                      type="text"
                      inputMode="numeric"
                      maxLength={1}
                      value={otpDigits[i] || ''}
                      onChange={(e) => {
                        const newOtpDigits = [...otpDigits];
                        newOtpDigits[i] = e.target.value.replace(/\D/g, '').slice(-1);
                        setOtpDigits(newOtpDigits);
                        if (newOtpDigits[i] && i < 5) {
                          (document.querySelectorAll('.otp-digit-login')[i + 1] as HTMLInputElement)?.focus();
                        }
                      }}
                      className="otp-digit-login w-10 h-10 text-center text-lg font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-700 focus:ring-2 focus:ring-green-100"
                    />
                  ))}
                </div>

                {otpError && (
                  <p className="text-red-500 text-sm text-center mt-2">{otpError}</p>
                )}

                <button
                  onClick={handleLoginOtpVerify}
                  disabled={otpDigits.join("").length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-xl transition mb-3"
                >
                  Verify
                </button>

                {otpCountdown > 0 ? (
                  <p className="text-center text-xs text-gray-500">Resend OTP in {otpCountdown}s</p>
                ) : (
                  <button
                    onClick={() => {
                      void (async () => {
                        try {
                          if (USE_DRIVER_API) await driverSendLoginOtp(DRIVER_API_BASE, mobileNumber);
                          setOtpCountdown(30);
                        } catch (e) {
                          setOtpError(e instanceof Error ? e.message : String(e));
                        }
                      })();
                    }}
                    className="w-full text-green-700 hover:text-green-800 font-medium py-2 text-sm"
                  >
                    Resend OTP
                  </button>
                )}
                {USE_DRIVER_API && apiBanner && !otpError && (
                  <p className="text-xs text-center text-amber-700 mt-3">{apiBanner}</p>
                )}
              </>
            )}

            {onboardingStep === 'select_fo' && (
              <>
                <button
                  onClick={() => {
                    setOnboardingStep('login_otp');
                    setOtpPhaseToken(null);
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-6"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-4">Choose fleet operator</h2>
                <div className="space-y-3">
                  {foOrganizationList
                    .filter((f) => f.foStatus === 'ACTIVE')
                    .map((f) => (
                      <button
                        key={f.foCompanyId}
                        type="button"
                        onClick={() => {
                          setSelectedFoCompanyId(f.foCompanyId);
                          setFoPinEntry('');
                          setOnboardingStep('fo_pin_login');
                        }}
                        className="w-full text-left border rounded-2xl p-4 hover:border-green-700 border-gray-200"
                      >
                        <p className="font-semibold text-gray-900">{f.foName}</p>
                        <p className="text-xs text-gray-500">Fleet ID #{f.foCompanyId}</p>
                      </button>
                    ))}
                </div>
              </>
            )}

            {onboardingStep === 'fo_pin_login' && otpPhaseToken && (
              <>
                <button
                  onClick={() =>
                    setOnboardingStep(
                      foOrganizationList.filter((x) => x.foStatus === 'ACTIVE').length > 1 ? 'select_fo' : 'login_otp'
                    )
                  }
                  className="flex items-center gap-2 text-gray-600 mb-6"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Fleet PIN</h2>
                <p className="text-sm text-gray-600 mb-6">Enter your PIN for this fleet (4–6 digits)</p>
                <PinDisplay value={foPinEntry} />
                <Numpad
                  onPress={(digit) => foPinEntry.length < 6 && setFoPinEntry(foPinEntry + digit)}
                  onBackspace={() => setFoPinEntry(foPinEntry.slice(0, -1))}
                />
                <button
                  disabled={foPinEntry.length < 4 || foPinEntry.length > 6 || selectedFoCompanyId === null}
                  onClick={() => {
                    void (async () => {
                      if (selectedFoCompanyId === null || !otpPhaseToken) return;
                      try {
                        const tr = await driverFoSelect(
                          DRIVER_API_BASE,
                          otpPhaseToken,
                          selectedFoCompanyId,
                          foPinEntry
                        );
                        const scoped = oauthAccessToken(tr);
                        if (!scoped) throw new Error('Missing fleet token');
                        setFoScopedToken(scoped);
                        setOtpPhaseToken(null);
                        setFoPinEntry('');
                        setApiBanner(null);
                        setOnboardingStep('complete');
                      } catch (e) {
                        setApiBanner(e instanceof Error ? e.message : String(e));
                      }
                    })();
                  }}
                  className="w-full mt-8 bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition"
                >
                  Unlock app
                </button>
                {apiBanner && <p className="text-red-600 text-xs text-center mt-3">{apiBanner}</p>}
              </>
            )}

            {/* Screen: PIN Login */}
            {onboardingStep === 'pin_login' && (
              <>
                <div className="text-center space-y-2 mb-8 flex flex-col items-center">
                  <img src="/mgl-logo.png" alt="MGL Fleet" className="w-12 h-12 object-contain" />
                  <p className="text-xs text-gray-500">Welcome back</p>
                  <p className="text-lg font-bold text-gray-900">{driverDisplayName}</p>
                </div>

                <div className="mb-6">
                  <label className="text-xs text-gray-600 font-medium">Enter your PIN</label>
                  <div className={`flex justify-center gap-3 my-4 transition-all ${showShake ? 'animate-shake' : ''}`}>
                    {Array.from({ length: 6 }).map((_, i) => (
                      <div
                        key={i}
                        className={`w-4 h-4 rounded-full border-2 transition-all ${
                          i < loginPin.length
                            ? loginPinError
                              ? 'bg-red-500 border-red-500'
                              : 'bg-green-700 border-green-700'
                            : 'border-gray-300'
                        }`}
                      />
                    ))}
                  </div>
                  {loginPinError && <p className="text-xs text-red-600 text-center">{loginPinError}</p>}
                </div>

                <Numpad
                  onPress={(digit) => {
                    if (!disableNumpad && loginPin.length < 6) {
                      const newPin = loginPin + digit;
                      setLoginPin(newPin);
                      setLoginPinError('');

                      if (newPin.length === 6) {
                        if (newPin === '123456') {
                          setShowShake(false);
                          setTimeout(() => setOnboardingStep('complete'), 300);
                        } else {
                          setShowShake(true);
                          const newAttempts = wrongAttempts + 1;
                          setWrongAttempts(newAttempts);
                          setLoginPinError('Incorrect PIN');
                          setTimeout(() => {
                            setShowShake(false);
                            setLoginPin('');
                            setLoginPinError('');
                          }, 500);

                          if (newAttempts >= 3) {
                            setDisableNumpad(true);
                          }
                        }
                      }
                    }
                  }}
                  onBackspace={() => setLoginPin(loginPin.slice(0, -1))}
                />

                {disableNumpad && (
                  <div className="mt-6 space-y-2">
                    <p className="text-xs text-gray-500 text-center">Too many attempts. Try again later or reset your PIN.</p>
                    <button
                      onClick={() => {
                        setOnboardingStep('forgot_pin');
                        setLoginPin('');
                        setLoginPinError('');
                      }}
                      className="w-full text-green-700 hover:text-green-800 font-medium py-2 text-sm"
                    >
                      Forgot PIN?
                    </button>
                  </div>
                )}

                {!disableNumpad && (
                  <button
                    onClick={() => {
                      setOnboardingStep('forgot_pin');
                      setLoginPin('');
                      setLoginPinError('');
                    }}
                    className="w-full text-green-700 hover:text-green-800 font-medium py-2 text-sm mt-6"
                  >
                    Forgot PIN?
                  </button>
                )}
              </>
            )}

            {/* Screen: Set PIN (New User) */}
            {onboardingStep === 'set_pin' && (
              <>
                <h2 className="text-xl font-bold mb-2">{isNewUser ? 'Create your PIN' : 'Set new PIN'}</h2>
                <p className="text-sm text-gray-600 mb-6">{isNewUser ? "You'll use this every time you sign in" : 'Choose a new 6-digit PIN'}</p>
                <PinDisplay value={newPin} />
                <Numpad onPress={(digit) => { setNewPin(newPin + digit); }} onBackspace={() => setNewPin(newPin.slice(0, -1))} />
                <button onClick={() => { setPinConfirm(''); setPinError(''); setOnboardingStep('confirm_pin'); }} disabled={newPin.length !== 6} className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6">
                  Next
                </button>
              </>
            )}

            {/* Screen: Confirm PIN */}
            {onboardingStep === 'confirm_pin' && (
              <>
                <h2 className="text-xl font-bold mb-2">Confirm your PIN</h2>
                <p className="text-sm text-gray-600 mb-6">Enter the same PIN again</p>
                {pinError && <div className="bg-red-50 border border-red-300 rounded-2xl p-3 mb-4 text-red-900 text-sm">{pinError}</div>}
                <PinDisplay value={pinConfirm} />
                <Numpad onPress={(digit) => { setPinConfirm(pinConfirm + digit); }} onBackspace={() => setPinConfirm(pinConfirm.slice(0, -1))} isConfirm />
                <button
                  onClick={() => {
                    if (newPin === pinConfirm) {
                      setPinError('');
                      if (isNewUser) {
                        setOnboardingStep('registered');
                      } else {
                        setSuccessToast('PIN updated successfully');
                        setTimeout(() => setSuccessToast(null), 2000);
                        setNewPin('');
                        setPinConfirm('');
                        setIsNewUser(false);
                        setOnboardingStep('pin_login');
                      }
                    } else {
                      setPinError("PINs didn't match. Try again.");
                      setPinConfirm('');
                      setOnboardingStep('set_pin');
                    }
                  }}
                  disabled={pinConfirm.length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6"
                >
                  Confirm PIN
                </button>
              </>
            )}

            {/* Screen: Registered (New User Success) */}
            {onboardingStep === 'registered' && (
              <div className="flex-1 overflow-y-auto flex flex-col items-center justify-center p-6 bg-gradient-to-b from-green-50 to-white space-y-6">
                <CheckCircle className="w-20 h-20 text-green-600 animate-bounce" />
                <h1 className="text-3xl font-bold text-green-700 text-center">PIN created successfully</h1>
                <p className="text-center text-gray-600">You can now use Scan & Pay at any MGL CNG station</p>
                <button
                  onClick={() => {
                    setNewPin('');
                    setPinConfirm('');
                    setIsNewUser(false);
                    setOnboardingStep('complete');
                  }}
                  className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition mt-8"
                >
                  Continue to Home
                </button>
              </div>
            )}

            {/* Screen 1b: Invite Code */}
            {onboardingStep === '1b' && (
              <>
                <button
                  onClick={() => {
                    setValidatedInvitePreview(null);
                    setInviteSessionToken(null);
                    if (USE_DRIVER_API) {
                      setInviteMobileVerificationToken(null);
                      setInviteOtpRefNumber(null);
                      setOtp('');
                      setOnboardingStep('1c');
                    } else {
                      setOnboardingStep('1d');
                    }
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-4"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Invite Code</h2>
                <p className="text-sm text-gray-600 mb-6">
                  {USE_DRIVER_API ? 'Enter the code your Fleet Operator shared' : 'Enter the 6-character code your Fleet Operator shared'}
                </p>
                <input
                  type="text"
                  value={inviteCode}
                  onChange={(e) => {
                    handleInviteCodeChange(e);
                    setValidatedInvitePreview(null);
                    setInviteSessionToken(null);
                  }}
                  maxLength={USE_DRIVER_API ? 24 : 6}
                  placeholder={USE_DRIVER_API ? 'A3K9M2…' : 'ABC123'}
                  className="w-full px-4 py-3 border border-gray-300 rounded-2xl text-center text-lg tracking-widest font-bold focus:outline-none focus:ring-2 focus:ring-green-700 mb-4"
                />
                {!USE_DRIVER_API && inviteCode.length === 6 && INVITE_CODES_DB[inviteCode] && (
                  <div className="bg-green-50 border border-green-300 rounded-2xl p-3 mb-4 flex items-start gap-3">
                    <Check className="w-5 h-5 text-green-700 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="font-semibold text-green-900 text-sm">{INVITE_CODES_DB[inviteCode]}</p>
                    </div>
                  </div>
                )}
                {USE_DRIVER_API && validatedInvitePreview && (
                  <div className="bg-green-50 border border-green-300 rounded-2xl p-3 mb-4 flex items-start gap-3">
                    <Check className="w-5 h-5 text-green-700 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="font-semibold text-green-900 text-sm">{validatedInvitePreview.driverName}</p>
                      <p className="text-xs text-green-800">{validatedInvitePreview.foName}</p>
                    </div>
                  </div>
                )}
                <button
                  onClick={() => {
                    void (async () => {
                      try {
                        if (!USE_DRIVER_API) {
                          if (inviteCode.length !== 6 || !INVITE_CODES_DB[inviteCode]) return;
                          setOnboardingStep('1e');
                          return;
                        }
                        if (!inviteMobileVerificationToken) {
                          setInviteFlowOtpError('Complete mobile OTP verification first.');
                          return;
                        }
                        const r = await driverInviteValidate(
                          DRIVER_API_BASE,
                          mobileNumber,
                          inviteCode,
                          inviteMobileVerificationToken
                        );
                        setInviteSessionToken(r.sessionToken);
                        setValidatedInvitePreview({ driverName: r.driverName, foName: r.foName });
                        setInviteFlowOtpError('');
                        setOnboardingStep('1e');
                      } catch (e) {
                        setInviteFlowOtpError(e instanceof Error ? e.message : String(e));
                      }
                    })();
                  }}
                  disabled={
                    !USE_DRIVER_API ? inviteCode.length !== 6 || !INVITE_CODES_DB[inviteCode] : inviteCode.length < 6
                  }
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition"
                >
                  Continue
                </button>
                {inviteFlowOtpError && onboardingStep === '1b' && (
                  <p className="text-red-600 text-xs text-center mt-3">{inviteFlowOtpError}</p>
                )}
              </>
            )}

            {/* Screen 1c: Mobile Verify */}
            {onboardingStep === '1c' && (
              <>
                <button
                  onClick={() => {
                    setInviteOtpRefNumber(null);
                    setInviteMobileVerificationToken(null);
                    setOtp('');
                    setOnboardingStep('login');
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-4"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Mobile Verification</h2>
                <p className="text-sm text-gray-600 mb-6">Must match number your Fleet Operator provided</p>
                <div className="flex gap-2 mb-4">
                  <span className="text-lg font-bold text-gray-600 pt-3">+91</span>
                  <input type="tel" value={mobileNumber} onChange={handleMobileChange} placeholder="98765 43210" className="flex-1 px-4 py-3 border border-gray-300 rounded-2xl focus:outline-none focus:ring-2 focus:ring-green-700" />
                </div>
                <button
                  onClick={() => {
                    void (async () => {
                      setApiBanner(null);
                      setInviteFlowOtpError('');
                      if (!USE_DRIVER_API) {
                        setOtp('');
                        setOtpCountdown(30);
                        setOnboardingStep('1d');
                        return;
                      }
                      try {
                        const cm = await driverCheckMobile(DRIVER_API_BASE, mobileNumber);
                        if (cm !== 'NEW_USER') {
                          setInviteFlowOtpError('Use “Send OTP” on the login screen.');
                          return;
                        }
                        const ref = await driverInviteMobileSendOtp(DRIVER_API_BASE, mobileNumber);
                        setInviteOtpRefNumber(ref);
                        setOtp('');
                        setInviteFlowOtpError('');
                        setOtpCountdown(30);
                        setOnboardingStep('1d');
                      } catch (e) {
                        setInviteFlowOtpError(e instanceof Error ? e.message : String(e));
                      }
                    })();
                  }}
                  disabled={mobileNumber.length !== 10}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition"
                >
                  Send OTP
                </button>
                {inviteFlowOtpError && onboardingStep === '1c' && (
                  <p className="text-red-600 text-xs text-center mt-3">{inviteFlowOtpError}</p>
                )}
              </>
            )}

            {/* Screen 1d: OTP Entry */}
            {!USE_DRIVER_API && onboardingStep === '1d' && (
              <>
                <button onClick={() => setOnboardingStep('1c')} className="flex items-center gap-2 text-gray-600 mb-4">
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Verify OTP</h2>
                <div className="bg-blue-50 border border-blue-200 rounded-2xl p-3 mb-4">
                  <p className="text-sm text-blue-900">OTP sent to +91 {mobileNumber.slice(-4).padStart(10, '•')}</p>
                </div>
                <p className="text-xs text-gray-500 mb-2">Demo: enter <strong>123456</strong></p>
                <div className="flex justify-center gap-1 mb-4">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <input key={i} type="text" inputMode="numeric" maxLength={1} value={otp[i] || ''} onChange={(e) => { const newOtp = otp.split(''); newOtp[i] = e.target.value.replace(/\D/g, '').slice(-1); setOtp(newOtp.join('')); if (newOtp[i] && i < 5) (document.querySelectorAll('.otp-digit-invite')[i + 1] as HTMLInputElement)?.focus(); }} className="otp-digit-invite w-10 h-10 text-center text-lg font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-700 focus:ring-2 focus:ring-green-100" />
                  ))}
                </div>
                {inviteFlowOtpError && (
                  <p className="text-red-500 text-sm text-center mb-3">{inviteFlowOtpError}</p>
                )}
                <button
                  onClick={() => {
                    if (otp === '123456') {
                      setInviteFlowOtpError('');
                      setOnboardingStep('1b');
                    } else {
                      setInviteFlowOtpError('Incorrect OTP. Try again.');
                      setTimeout(() => {
                        setOtp('');
                        setInviteFlowOtpError('');
                      }, 1500);
                    }
                  }}
                  disabled={otp.length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mb-2"
                >
                  Verify OTP
                </button>
                <button className="w-full text-green-700 font-medium py-2 text-sm">Resend OTP</button>
              </>
            )}

            {USE_DRIVER_API && onboardingStep === '1d' && (
              <>
                <button
                  onClick={() => {
                    setInviteOtpRefNumber(null);
                    setOtp('');
                    setOnboardingStep('1c');
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-4"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Verify OTP</h2>
                <div className="bg-blue-50 border border-blue-200 rounded-2xl p-3 mb-4">
                  <p className="text-sm text-blue-900">OTP sent to +91 {mobileNumber.slice(-4).padStart(10, '•')}</p>
                </div>
                <div className="flex justify-center gap-1 mb-4">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <input
                      key={i}
                      type="text"
                      inputMode="numeric"
                      maxLength={1}
                      value={otp[i] || ''}
                      onChange={(e) => {
                        const newOtp = otp.split('');
                        newOtp[i] = e.target.value.replace(/\D/g, '').slice(-1);
                        setOtp(newOtp.join(''));
                        if (newOtp[i] && i < 5) {
                          (
                            document.querySelectorAll('.otp-digit-invite-api')[i + 1] as HTMLInputElement
                          )?.focus();
                        }
                      }}
                      className="otp-digit-invite-api w-10 h-10 text-center text-lg font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-700 focus:ring-2 focus:ring-green-100"
                    />
                  ))}
                </div>
                {inviteFlowOtpError && (
                  <p className="text-red-500 text-sm text-center mb-3">{inviteFlowOtpError}</p>
                )}
                <button
                  onClick={() => {
                    void (async () => {
                      if (!inviteOtpRefNumber || otp.length !== 6) return;
                      try {
                        const tok = await driverInviteMobileVerifyOtp(
                          DRIVER_API_BASE,
                          mobileNumber,
                          inviteOtpRefNumber,
                          otp
                        );
                        setInviteMobileVerificationToken(tok);
                        setInviteFlowOtpError('');
                        setOtp('');
                        setOnboardingStep('1b');
                      } catch (e) {
                        setInviteFlowOtpError(e instanceof Error ? e.message : String(e));
                      }
                    })();
                  }}
                  disabled={otp.length !== 6 || !inviteOtpRefNumber}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mb-2"
                >
                  Verify OTP
                </button>
                {otpCountdown > 0 ? (
                  <p className="text-center text-xs text-gray-500">Resend OTP in {otpCountdown}s</p>
                ) : (
                  <button
                    onClick={() => {
                      void (async () => {
                        try {
                          const ref = await driverInviteMobileSendOtp(DRIVER_API_BASE, mobileNumber);
                          setInviteOtpRefNumber(ref);
                          setInviteFlowOtpError('');
                          setOtpCountdown(30);
                        } catch (e) {
                          setInviteFlowOtpError(e instanceof Error ? e.message : String(e));
                        }
                      })();
                    }}
                    className="w-full text-green-700 hover:text-green-800 font-medium py-2 text-sm"
                  >
                    Resend OTP
                  </button>
                )}
              </>
            )}

            {/* Screen 1e: PIN Setup */}
            {onboardingStep === '1e' && (
              <>
                <h2 className="text-xl font-bold mb-2">Create your app PIN</h2>
                <p className="text-sm text-gray-600 mb-6">{USE_DRIVER_API ? '4–6 digits for fleet login and fuel authorization' : '6 digits for fueling authorization'}</p>
                <PinDisplay value={pin} />
                <Numpad onPress={(digit) => { if (pin.length < 6) handlePinInput(digit, false); }} onBackspace={() => handlePinBackspace(false)} />
                <button
                  onClick={() => setOnboardingStep('1f')}
                  disabled={
                    USE_DRIVER_API ? pin.length < 4 || pin.length > 6 : pin.length !== 6
                  }
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6"
                >
                  Next
                </button>
              </>
            )}

            {/* Screen 1f: PIN Confirm */}
            {onboardingStep === '1f' && (
              <>
                <h2 className="text-xl font-bold mb-2">Confirm your PIN</h2>
                <p className="text-sm text-gray-600 mb-6">Enter the same PIN again</p>
                {pinError && <div className="bg-red-50 border border-red-300 rounded-2xl p-3 mb-4 text-red-900 text-sm">{pinError}</div>}
                <PinDisplay value={pinConfirm} />
                <Numpad onPress={(digit) => { if (pinConfirm.length < 6) handlePinInput(digit, true); }} onBackspace={() => handlePinBackspace(true)} isConfirm />
                <button
                  onClick={() => {
                    void (async () => {
                      if (pin !== pinConfirm) {
                        setPinError("PINs don't match, try again");
                        setPinConfirm('');
                        return;
                      }
                      setPinError('');
                      if (!USE_DRIVER_API) {
                        setOnboardingStep('complete');
                        return;
                      }
                      if (!inviteSessionToken) {
                        setPinError('Session missing — go back to invite step.');
                        return;
                      }
                      try {
                        const tr = await driverInviteSetPin(DRIVER_API_BASE, inviteSessionToken, pin);
                        const scoped = oauthAccessToken(tr);
                        if (!scoped) throw new Error('Missing access token');
                        setFoScopedToken(scoped);
                        setInviteSessionToken(null);
                        setPin('');
                        setPinConfirm('');
                        setApiBanner(null);
                        setOnboardingStep('complete');
                      } catch (e) {
                        setPinError(e instanceof Error ? e.message : String(e));
                      }
                    })();
                  }}
                  disabled={USE_DRIVER_API ? pinConfirm.length < 4 || pinConfirm.length > 6 : pinConfirm.length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6"
                >
                  Confirm PIN
                </button>
              </>
            )}

            {/* Screen: Forgot PIN */}
            {onboardingStep === 'forgot_pin' && (
              <>
                <button onClick={() => setOnboardingStep('pin_login')} className="flex items-center gap-2 text-gray-600 mb-4">
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Reset your PIN</h2>
                <p className="text-sm text-gray-600 mb-6">Verify your mobile to reset</p>

                <div className="bg-gray-50 border border-gray-200 rounded-2xl p-4 mb-6 flex items-center gap-3">
                  <Phone className="w-5 h-5 text-gray-600 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-semibold text-gray-900">+91 ••••••1234</p>
                    <p className="text-xs text-gray-600 mt-1">Your registered mobile number</p>
                  </div>
                </div>

                <button
                  onClick={() => {
                    setOtpCountdown(30);
                    setOnboardingStep('forgot_otp');
                  }}
                  className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition"
                >
                  Send OTP
                </button>
              </>
            )}

            {/* Screen: Forgot OTP (OTP entry for PIN reset) */}
            {onboardingStep === 'forgot_otp' && (
              <>
                <button onClick={() => setOnboardingStep('forgot_pin')} className="flex items-center gap-2 text-gray-600 mb-4">
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Verify mobile</h2>
                <div className="bg-blue-50 border border-blue-200 rounded-2xl p-3 mb-4">
                  <p className="text-sm text-blue-900">OTP sent to +91 ••••••1234</p>
                </div>
                <div className="flex justify-center gap-1 mb-4">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <input
                      key={i}
                      type="text"
                      inputMode="numeric"
                      maxLength={1}
                      value={otp[i] || ''}
                      onChange={(e) => {
                        const newOtp = otp.split('');
                        newOtp[i] = e.target.value.replace(/\D/g, '').slice(-1);
                        setOtp(newOtp.join(''));
                        if (newOtp[i] && i < 5) (document.querySelectorAll('.otp-digit-reset')[i + 1] as HTMLInputElement)?.focus();
                      }}
                      className="otp-digit-reset w-10 h-10 text-center text-lg font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-700 focus:ring-2 focus:ring-green-100"
                    />
                  ))}
                </div>
                <button
                  onClick={() => {
                    if (otp === '123456') {
                      setOtp('');
                      setNewPin('');
                      setPinConfirm('');
                      setPinError('');
                      setIsNewUser(false);
                      setOnboardingStep('set_pin');
                    }
                  }}
                  disabled={otp.length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mb-3"
                >
                  Verify
                </button>

                {otpCountdown > 0 ? (
                  <p className="text-center text-xs text-gray-500">Resend OTP in {otpCountdown}s</p>
                ) : (
                  <button onClick={() => setOtpCountdown(30)} className="w-full text-green-700 hover:text-green-800 font-medium py-2 text-sm">
                    Resend OTP
                  </button>
                )}
              </>
            )}

            {/* Screen: Set New PIN */}
            {onboardingStep === 'set_pin_reset' && (
              <>
                <h2 className="text-xl font-bold mb-2">Create new PIN</h2>
                <p className="text-sm text-gray-600 mb-6">6 digits for fueling authorization</p>
                <PinDisplay value={pin} />
                <Numpad onPress={(digit) => handlePinInput(digit, false)} onBackspace={() => handlePinBackspace(false)} />
                <button
                  onClick={() => setOnboardingStep('confirm_pin_reset')}
                  disabled={pin.length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6"
                >
                  Next
                </button>
              </>
            )}

            {/* Screen: Confirm New PIN */}
            {onboardingStep === 'confirm_pin_reset' && (
              <>
                <h2 className="text-xl font-bold mb-2">Confirm new PIN</h2>
                <p className="text-sm text-gray-600 mb-6">Enter the same PIN again</p>
                {pinError && <div className="bg-red-50 border border-red-300 rounded-2xl p-3 mb-4 text-red-900 text-sm">{pinError}</div>}
                <PinDisplay value={pinConfirm} />
                <Numpad onPress={(digit) => handlePinInput(digit, true)} onBackspace={() => handlePinBackspace(true)} isConfirm />
                <button
                  onClick={() => {
                    if (pin === pinConfirm) {
                      setPinError('');
                      setPin('');
                      setPinConfirm('');
                      setOtp('');
                      setLoginPin('');
                      setLoginPinError('');
                      setWrongAttempts(0);
                      setDisableNumpad(false);
                      setOnboardingStep('pin_login');
                    } else {
                      setPinError("PINs don't match, try again");
                      setPinConfirm('');
                    }
                  }}
                  disabled={pinConfirm.length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6"
                >
                  Confirm PIN
                </button>
              </>
            )}
          </div>

        {/* Dev Menu Trigger */}
        <button 
          onClick={() => setShowDevMenu(!showDevMenu)}
          className="fixed bottom-20 right-2 w-8 h-8 
            bg-gray-200 rounded-full text-xs text-gray-500
            flex items-center justify-center z-50"
        >
          ⋮
        </button>
        {showDevMenu && (
          <div className="absolute top-4 right-4 bg-gray-800 text-white p-3 rounded text-xs space-y-1">
            <button onClick={() => { setOnboardingStep('complete'); setShowDevMenu(false); }} className="block w-full text-left hover:bg-gray-700 p-1">Skip to Main App</button>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="relative flex min-h-screen w-full flex-col bg-gray-100">
        {USE_DRIVER_API && apiBanner && (
          <div className="bg-amber-50 border-b border-amber-200 px-4 py-2 text-xs text-amber-900 flex justify-between gap-2 items-center">
            <span>{apiBanner}</span>
            <button type="button" onClick={() => setApiBanner(null)} className="text-amber-800 font-semibold shrink-0">
              Dismiss
            </button>
          </div>
        )}

        {/* Session In Progress Banner */}
        {/* {sessionState !== 'idle' && (
          <div className="bg-blue-100 border-b border-blue-300 px-4 py-2 flex items-center gap-2 text-xs">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"/>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"/>
            </span>
            <span className="text-blue-900 font-medium">Fueling in progress · MH 02 AB 1234</span>
          </div>
        )} */}

        {/* Content Area */}
        <div className="flex-1 min-h-0 overflow-hidden flex flex-col bg-white">
          {/* Assignment Notification Screen */}
          {currentMainScreen === 'assignment_notification' && (
            <div className="flex-1 overflow-y-auto flex flex-col">
              {/* Header */}
              <div className="p-4 flex items-center justify-between border-b border-gray-100">
                <button onClick={() => setCurrentMainScreen('home_empty')} className="text-gray-600 hover:text-gray-900">
                  <ChevronLeft className="w-6 h-6" />
                </button>
              </div>

              <div className="flex-1 flex flex-col overflow-y-auto">
                <div className="p-6 space-y-4">
                  {/* Get assignment data */}
                  {(() => {
                    const assignment = activeAssignment || assignmentFallback;

                    return (
                      <>
                        {/* Top Banner */}
                        {assignment.authMode === 'vehicle_linked' && (
                          <div className="bg-green-50 border border-green-200 rounded-xl p-4 space-y-2">
                            <p className="text-base font-bold text-green-900">New vehicle assigned</p>
                            <p className="text-sm text-green-800">Vehicle-linked · Permanent assignment</p>
                          </div>
                        )}
                        {assignment.authMode === 'shift_based' && (
                          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 space-y-2">
                            <p className="text-base font-bold text-amber-900">New shift assigned</p>
                            <p className="text-sm text-amber-800">Shift-based · Time-restricted fueling</p>
                          </div>
                        )}
                        {assignment.authMode === 'trip_linked' && (
                          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 space-y-2">
                            <p className="text-base font-bold text-blue-900">New trip assigned</p>
                            <p className="text-sm text-blue-800">Trip-linked · Single trip fueling</p>
                          </div>
                        )}

                        {/* Vehicle Details Card */}
                        <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-3">
                          <p className="text-3xl font-mono font-bold text-gray-900">{assignment.vrn}</p>
                          <p className="text-sm text-gray-600">{assignment.fo}</p>
                          {assignment.assignedBy && <p className="text-xs text-gray-600">Assigned by {assignment.assignedBy}</p>}
                        </div>

                        {/* Mode-Specific Details */}
                        {assignment.authMode === 'vehicle_linked' && (
                          <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-3">
                            <div className="flex items-center gap-2">
                              <CheckCircle className="w-5 h-5 text-green-600" />
                              <p className="font-medium text-gray-900">Permanent assignment</p>
                            </div>
                            <p className="text-sm text-gray-600">Scan & Pay will be available at all times once paired</p>
                          </div>
                        )}

                        {assignment.authMode === 'shift_based' && (
                          <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-3">
                            <p className="font-medium text-gray-900">Shift schedule</p>
                            <div className="grid grid-cols-3 gap-2 text-xs font-medium text-gray-600 mb-3">
                              <div>Day</div>
                              <div>Start</div>
                              <div>End</div>
                            </div>
                            {assignment.shiftDays?.map((day) => (
                              <div key={day} className="grid grid-cols-3 gap-2 text-sm text-gray-900 py-2 border-b border-gray-100 last:border-0">
                                <div>{day}</div>
                                <div className="font-mono">{assignment.shiftStart}</div>
                                <div className="font-mono">{assignment.shiftEnd}</div>
                              </div>
                            ))}
                            <p className="text-xs text-amber-700 pt-2">Scan & Pay available within shift windows only</p>
                          </div>
                        )}

                        {assignment.authMode === 'trip_linked' && (
                          <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-3">
                            <div className="space-y-2 text-sm">
                              <div className="flex justify-between py-2 border-b border-gray-100">
                                <span className="text-gray-600">Date</span>
                                <span className="font-medium text-gray-900">{assignment.tripDate}</span>
                              </div>
                              <div className="flex justify-between py-2 border-b border-gray-100">
                                <span className="text-gray-600">Window</span>
                                <span className="font-medium text-gray-900">{assignment.tripStart} – {assignment.tripEnd}</span>
                              </div>
                              <div className="flex justify-between py-2 border-b border-gray-100">
                                <span className="text-gray-600">From</span>
                                <span className="font-medium text-gray-900">{assignment.origin}</span>
                              </div>
                              <div className="flex justify-between py-2">
                                <span className="text-gray-600">To</span>
                                <span className="font-medium text-gray-900">{assignment.destination}</span>
                              </div>
                            </div>
                            <p className="text-xs text-blue-700 pt-2">Scan & Pay available within trip window only</p>
                          </div>
                        )}

                        {/* Pairing Info Box */}
                        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 space-y-2">
                          <div className="flex items-center gap-2">
                            <Lock className="w-5 h-5 text-amber-700" />
                            <p className="font-bold text-amber-900">Pairing required</p>
                          </div>
                          <p className="text-sm text-amber-800">Enter the 6-digit code from your Fleet Operator to activate fueling</p>
                        </div>
                      </>
                    );
                  })()}
                </div>
              </div>

              {/* Fixed Bottom Buttons */}
              <div className="border-t border-gray-100 bg-white p-6 space-y-3">
                <button
                  onClick={() => {
                    setPairingDigits(Array(6).fill(""));
                    setPairingError("");
                    setPairingAttempts(0);
                    setPairingSuccess(false);
                    setCurrentMainScreen('pairing_code');
                  }}
                  className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition"
                >
                  Accept & Pair
                </button>
                <button
                  onClick={() => setShowDeclineConfirm(true)}
                  className="w-full border border-red-300 hover:bg-red-50 text-red-600 font-medium py-3 rounded-2xl transition"
                >
                  Decline
                </button>
              </div>

              {/* Decline Confirmation Dialog */}
              {showDeclineConfirm && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                  <div className="bg-white rounded-2xl p-6 max-w-sm space-y-4">
                    <h3 className="text-lg font-bold text-gray-900">Decline this assignment?</h3>
                    <p className="text-sm text-gray-600">Your Fleet Operator will be notified.</p>
                    <div className="flex gap-3 pt-2">
                      <button onClick={() => setShowDeclineConfirm(false)} className="flex-1 border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2 rounded-lg transition">
                        Cancel
                      </button>
                      <button
                        onClick={() => {
                          setShowDeclineConfirm(false);
                          setCurrentMainScreen('home_empty');
                        }}
                        className="flex-1 bg-red-600 hover:bg-red-700 text-white font-medium py-2 rounded-lg transition"
                      >
                        Yes, decline
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Pairing Code Screen */}
          {currentMainScreen === 'pairing_code' && (
            <div className="flex-1 overflow-y-auto flex flex-col">
              {/* Header */}
              <div className="p-4 flex items-center justify-between border-b border-gray-100">
                <button onClick={() => setCurrentMainScreen('assignment_notification')} className="text-gray-600 hover:text-gray-900">
                  <ChevronLeft className="w-6 h-6" />
                </button>
                <h2 className="text-lg font-bold text-gray-900">Enter pairing code</h2>
                <div className="w-6" />
              </div>

              <div className="flex-1 flex flex-col overflow-y-auto">
                <div className="p-6 space-y-6">
                  {(() => {
                    const assignment = activeAssignment || assignmentFallback;

                    return (
                      <>
                        {/* Context Card */}
                        <div className="bg-gray-50 border border-gray-200 rounded-xl p-4 space-y-3">
                          <p className="text-2xl font-mono font-bold text-gray-900">{assignment.vrn}</p>
                          <div>
                            {assignment.authMode === 'vehicle_linked' && <span className="inline-block px-3 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">Vehicle-linked</span>}
                            {assignment.authMode === 'shift_based' && <span className="inline-block px-3 py-1 bg-amber-100 text-amber-700 text-xs font-semibold rounded-full">Shift-based</span>}
                            {assignment.authMode === 'trip_linked' && <span className="inline-block px-3 py-1 bg-blue-100 text-blue-700 text-xs font-semibold rounded-full">Trip-linked</span>}
                          </div>
                          <p className="text-sm text-gray-600">
                            {assignment.authMode === 'vehicle_linked' && 'Permanent assignment'}
                            {assignment.authMode === 'shift_based' && `Mon–Fri · ${assignment.shiftStart}–${assignment.shiftEnd}`}
                            {assignment.authMode === 'trip_linked' && `Today · ${assignment.tripStart}–${assignment.tripEnd} · ${assignment.origin} → ${assignment.destination}`}
                          </p>
                          <p className="text-xs text-gray-600">{assignment.fo}</p>
                        </div>

                        {/* Instruction Text */}
                        <p className="text-sm text-gray-600 text-center">Enter the 6-digit code your Fleet Operator shared with you</p>

                        {/* 6 Digit Input Boxes */}
                        <div className="flex gap-3 justify-center my-6">
                          {pairingDigits.map((digit, i) => (
                            <input
                              key={i}
                              ref={pairingRefs[i]}
                              type="text"
                              inputMode="numeric"
                              maxLength={1}
                              value={digit}
                              onChange={(e) => {
                                const val = e.target.value.replace(
                                  /[^0-9]/g, "")
                                if (!val) return
                                const next = [...pairingDigits]
                                next[i] = val
                                setPairingDigits(next)
                                if (i < 5) {
                                  pairingRefs[i+1].current?.focus()
                                }
                              }}
                              onKeyDown={(e) => {
                                if (e.key === "Backspace") {
                                  const next = [...pairingDigits]
                                  if (next[i]) {
                                    next[i] = ""
                                    setPairingDigits(next)
                                  } else if (i > 0) {
                                    pairingRefs[i-1].current?.focus()
                                  }
                                }
                              }}
                              onPaste={(e) => {
                                e.preventDefault()
                                const paste = e.clipboardData
                                  .getData("text")
                                  .replace(/[^0-9]/g, "")
                                  .slice(0, 6)
                                const next = ["","","","","",""]
                                paste.split("").forEach((c, idx) => {
                                  next[idx] = c
                                })
                                setPairingDigits(next)
                                const focusIdx = Math.min(
                                  paste.length, 5)
                                pairingRefs[focusIdx].current?.focus()
                              }}
                              className={`w-11 h-14 text-center 
                                text-xl font-mono font-bold 
                                border-2 rounded-xl outline-none
                                transition-colors
                                ${digit ? 
                                  "border-green-500 bg-green-50" : 
                                  "border-gray-300 bg-white"}
                                focus:border-green-600`}
                            />
                          ))}
                        </div>

                        {/* Success State */}
                        {pairingSuccess && (
                          <div className="text-center space-y-2">
                            <CheckCircle className="w-8 h-8 text-green-600 mx-auto animate-bounce" />
                            <p className="text-lg font-bold text-green-700">Pairing successful!</p>
                            <p className="text-sm text-gray-600">Activating your assignment...</p>
                          </div>
                        )}

                        {/* Error State */}
                        {pairingError && !pairingSuccess && (
                          <p className="text-center text-sm text-red-600">{pairingError}</p>
                        )}

                        {/* Max Attempts State */}
                        {pairingAttempts >= 3 && (
                          <div className="bg-red-50 border border-red-200 rounded-xl p-4 space-y-3">
                            <p className="text-sm font-bold text-red-900">Too many attempts</p>
                            <p className="text-sm text-red-800">Contact your Fleet Operator for a new code.</p>
                          </div>
                        )}

                        {/* Verify Button */}
                        {pairingAttempts < 3 && !pairingSuccess && (
                          <button
                            onClick={() => {
                              void (async () => {
                                const code = pairingDigits.join('');
                                if (USE_DRIVER_API && foScopedToken) {
                                  try {
                                    await driverAcceptPairing(DRIVER_API_BASE, foScopedToken, code);
                                    const next = await driverGetAssignments(DRIVER_API_BASE, foScopedToken);
                                    setApiAssignments(next);
                                    setPairingSuccess(true);
                                    setTimeout(() => setCurrentMainScreen('assignment_accepted'), 1500);
                                  } catch (e) {
                                    const newAttempts = pairingAttempts + 1;
                                    setPairingAttempts(newAttempts);
                                    setPairingError(e instanceof Error ? e.message : String(e));
                                    setTimeout(() => {
                                      setPairingDigits(Array(6).fill(''));
                                      setPairingError('');
                                    }, 1500);
                                  }
                                  return;
                                }
                                const validCode =
                                  activeAssignment?.validPairingCode || assignmentFallback?.validPairingCode;

                                if (code === validCode) {
                                  setPairingSuccess(true);
                                  setTimeout(() => {
                                    setCurrentMainScreen('assignment_accepted');
                                  }, 1500);
                                } else {
                                  const newAttempts = pairingAttempts + 1;
                                  setPairingAttempts(newAttempts);
                                  setPairingError('Incorrect code');
                                  setTimeout(() => {
                                    setPairingDigits(Array(6).fill(''));
                                    setPairingError('');
                                    const inputs = document.querySelectorAll('.pairing-digit-ref') as NodeListOf<HTMLInputElement>;
                                    inputs[0]?.focus();
                                  }, 1500);
                                }
                              })();
                            }}
                            disabled={pairingDigits.some(d => d === "")}
                            className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition"
                          >
                            Verify & Activate
                          </button>
                        )}

                        {/* Max Attempts Button */}
                        {pairingAttempts >= 3 && (
                          <button
                            onClick={() => setCurrentMainScreen('home_empty')}
                            className="w-full bg-gray-300 hover:bg-gray-400 text-gray-700 font-medium py-3 rounded-2xl transition"
                          >
                            Close
                          </button>
                        )}

                        {/* Help Link */}
                        <button
                          onClick={() => setShowPairingHelp(true)}
                          className="text-center text-sm text-green-700 hover:text-green-800 font-medium"
                        >
                          Haven&apos;t received your code?
                        </button>
                      </>
                    );
                  })()}
                </div>
              </div>

              {/* Help Sheet */}
              {showPairingHelp && (
                <div className="fixed inset-0 bg-black/50 flex items-end z-50">
                  <div className="bg-white w-full rounded-t-2xl p-6 space-y-4 max-h-96 overflow-y-auto">
                    <div className="flex justify-between items-center">
                      <h3 className="text-lg font-bold text-gray-900">Pairing code help</h3>
                      <button onClick={() => setShowPairingHelp(false)} className="text-gray-500 hover:text-gray-700">
                        <X className="w-5 h-5" />
                      </button>
                    </div>
                    <div className="space-y-3 text-sm text-gray-700">
                      <p>Ask your Fleet Operator to share the 6-digit pairing code for this assignment.</p>
                      <p>They can find it in the MGL Fleet portal under Driver Management.</p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Assignment Accepted Screen */}
          {currentMainScreen === 'assignment_accepted' && (
            <div className="flex-1 overflow-y-auto flex flex-col items-center justify-center p-6 bg-gradient-to-b from-green-50 to-white space-y-6">
              {(() => {
                const assignment = activeAssignment || assignmentFallback;

                return (
                  <>
                    {/* Checkmark Animation */}
                    <CheckCircle className="w-20 h-20 text-green-600 animate-bounce" />

                    {/* Success Message */}
                    <h1 className="text-3xl font-bold text-green-700 text-center">Assignment activated!</h1>

                    {/* VRN Pill */}
                    <span className="inline-block px-4 py-2 bg-green-100 text-green-700 font-mono font-bold rounded-full">
                      {assignment.vrn}
                    </span>

                    {/* What's Now Unlocked Card */}
                    <div className="w-full bg-white border border-gray-200 rounded-xl p-4 space-y-3 mt-4">
                      <h2 className="text-sm font-bold text-gray-900 mb-3">What&apos;s now unlocked</h2>

                      {assignment.authMode === 'vehicle_linked' && (
                        <>
                          <div className="flex items-start gap-3">
                            <CheckCircle className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
                            <div>
                              <p className="font-medium text-gray-900">Scan & Pay always available</p>
                              <p className="text-sm text-gray-600 mt-1">You can fuel {assignment.vrn} at any MGL CNG station at any time</p>
                            </div>
                          </div>
                        </>
                      )}

                      {assignment.authMode === 'shift_based' && (
                        <>
                          <div className="flex items-start gap-3">
                            <Clock className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
                            <div>
                              <p className="font-medium text-gray-900">Scan & Pay within shift hours</p>
                              <p className="text-sm text-gray-600 mt-1">Mon–Fri · {assignment.shiftStart}–{assignment.shiftEnd}</p>
                              <p className="text-xs text-gray-500 mt-2">Outside these hours Scan & Pay will be unavailable</p>
                            </div>
                          </div>
                        </>
                      )}

                      {assignment.authMode === 'trip_linked' && (
                        <>
                          <div className="flex items-start gap-3">
                            <MapPin className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
                            <div>
                              <p className="font-medium text-gray-900">Scan & Pay until {assignment.tripEnd} today</p>
                              <p className="text-sm text-gray-600 mt-1">Valid for this trip only</p>
                              <p className="text-sm text-gray-600 mt-1">{assignment.origin} → {assignment.destination}</p>
                            </div>
                          </div>
                        </>
                      )}
                    </div>

                    {/* Go to Assignments Button */}
                    <button
                      onClick={() => {
                        setActiveAssignment(null);
                        setCurrentMainScreen('home_empty');
                        setActiveTab('assignments');
                      }}
                      className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition mt-4"
                    >
                      Go to My Assignments
                    </button>
                  </>
                );
              })()}
            </div>
          )}

          {/* Main Screens */}
          {currentMainScreen !== 'pairing_code' && currentMainScreen !== 'assignment_accepted' && currentMainScreen !== 'assignment_notification' && (
            <>
              {/* Header */}
              <div className="bg-[#1a3020] px-5 pt-4 pb-5">
                <div className="flex justify-between items-center">
                  <div>
                    <p className="text-[#c8e6c9] text-sm font-normal">Good morning</p>
                    <p className="text-white font-bold text-xl mt-0.5">{driverDisplayName}</p>
                  </div>
                  <div className="w-10 h-10 rounded-full bg-[#2d4a36] ring-2 ring-white/10 flex items-center justify-center">
                    <span className="text-white font-bold text-sm">{driverDisplayInitials}</span>
                  </div>
                </div>
              </div>

              {/* Success Toast */}
              {successToast && (
                <div className="bg-green-600 text-white px-6 py-3 text-sm font-medium">
                  {successToast}
                </div>
              )}

              {/* Tab Content */}
          <div
            className={`flex-1 overflow-y-auto pb-24 ${
              activeTab === 'card' && currentCard ? 'bg-[#eceff1]' : 'bg-white'
            }`}
          >
            {/* Card Tab */}
            {activeTab === 'card' && currentCard && (
              <div className="p-4 space-y-4">
                {/* Pending Assignment Banner */}
                {pendingAssignmentCount > 0 && (
                  <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <AlertCircle className="w-5 h-5 text-amber-600 flex-shrink-0" />
                      <div>
                        <p className="text-sm font-medium text-amber-900">{pendingAssignmentCount} assignment{pendingAssignmentCount > 1 ? 's' : ''} need your attention</p>
                      </div>
                    </div>
                    <button onClick={() => setActiveTab('assignments')} className="text-sm font-medium text-green-700 hover:text-green-800">View</button>
                  </div>
                )}

                {/* Vehicle Card Carousel */}
                <div>
                  <div className="relative mb-1">
                    <div className="rounded-[14px] border border-gray-200 bg-white p-5 shadow-[0_2px_12px_rgba(0,0,0,0.04)]">
                      <div className="flex justify-between items-start gap-3">
                        <p className="text-xs text-gray-600 leading-snug pr-2 min-w-0 flex-1">
                          {currentCard.fo}
                        </p>
                        <span
                          className={`shrink-0 rounded-md px-2.5 py-1 text-[11px] font-bold
                            ${currentCard.authMode === 'vehicle_linked'
                              ? 'bg-[#e8f5e9] text-[#1b5e20]'
                              : currentCard.authMode === 'shift_based'
                                ? 'bg-amber-100 text-amber-900'
                                : 'bg-blue-100 text-blue-900'}`}
                        >
                          {currentCard.authMode === 'vehicle_linked' && 'Vehicle-linked'}
                          {currentCard.authMode === 'shift_based' &&
                            `Shift · ends ${currentCard.shiftEnd}`}
                          {currentCard.authMode === 'trip_linked' &&
                            `Trip · ends ${currentCard.tripEnd}`}
                        </span>
                      </div>
                      <p className="text-gray-900 font-bold text-2xl leading-tight tracking-wide mt-4 font-mono">
                        {activeCards[activeCard]?.vrn}
                      </p>
                      <div className="mt-4 border-t border-gray-100 pt-4">
                        <p className="text-[10px] text-gray-400 font-medium tracking-[0.22em] uppercase">
                          Vehicle balance
                        </p>
                        <p className="text-[1.75rem] leading-none font-bold text-gray-900 mt-2">
                          ₹{activeCards[activeCard]?.balance?.toLocaleString('en-IN')}
                        </p>
                        {(activeCards[activeCard]?.incentiveBalance ?? 0) > 0 && (
                          <p className="text-xs text-gray-500 mt-2">
                            Card ₹{activeCards[activeCard]?.cardBalance?.toLocaleString('en-IN')} · Incentive ₹
                            {activeCards[activeCard]?.incentiveBalance?.toLocaleString('en-IN')}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex justify-center gap-2 mt-2.5">
                    {activeCards.map((_: unknown, i: number) => (
                      <button
                        key={i}
                        type="button"
                        onClick={() => setActiveCard(i)}
                        className={`rounded-full transition-all duration-300 ${
                          activeCard === i ? 'w-7 h-2 bg-[#43a047]' : 'w-2 h-2 bg-gray-300'
                        }`}
                      />
                    ))}
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="mt-4">
                  <button
                    onClick={() => setActiveTab('scan')}
                    disabled={activeCards[activeCard]?.scanPayStatus === 'out_window'}
                    className="w-full bg-[#43a047] hover:bg-[#388e3c] disabled:bg-gray-200 disabled:text-gray-400 text-white font-semibold py-3.5 rounded-2xl text-[15px] flex items-center justify-center gap-2.5 transition-colors shadow-sm"
                  >
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                      <rect x="3" y="3" width="7" height="7"/>
                      <rect x="14" y="3" width="7" height="7"/>
                      <rect x="3" y="14" width="7" height="7"/>
                      <path d="M14 14h3v3M17 20v1M20 14v3M20 20h1"/>
                    </svg>
                    Scan & Pay
                  </button>
                </div>

                {/* Recent Transactions */}
                <div className="flex justify-between items-center pt-4 pb-2">
                  <p className="font-semibold text-base text-gray-900">Recent</p>
                  <button type="button" onClick={() => setActiveTab('transactions')} className="text-sm text-[#2e7d32] font-semibold">
                    View all
                  </button>
                </div>
                <div className="pb-2 space-y-3">
                    {(USE_DRIVER_API ? apiTxns.length === 0 : mockTransactions.length === 0) ? (
                      <div className="rounded-xl border border-gray-100 bg-white px-3.5 py-8 text-center shadow-[0_2px_12px_rgba(0,0,0,0.05)]">
                        <p className="text-sm text-gray-500">No transaction found</p>
                      </div>
                    ) : USE_DRIVER_API
                      ? apiTxns.slice(0, 3).map((txn) => {
                          const isCredit = /credit|top-up|top up|wallet|neft/i.test(txn.status);
                          let dayLine = txn.createdOn;
                          let timeFromCreated = '';
                          if (txn.createdOn.includes('T')) {
                            const [d, t] = txn.createdOn.split('T');
                            dayLine = d ?? txn.createdOn;
                            timeFromCreated = t?.slice(0, 5) ?? '';
                          } else {
                            const m = /\d{1,2}:\d{2}/.exec(txn.createdOn);
                            timeFromCreated = m?.[0] ?? '';
                            dayLine =
                              txn.createdOn.split(/\d{1,2}:\d{2}/)[0]?.replace(/[,\s]+$/u, '').trim() ??
                              txn.createdOn;
                          }
                          return (
                            <div
                              key={txn.serverTxnId}
                              className="flex items-center gap-3 rounded-xl border border-gray-100 bg-white px-3.5 py-3 shadow-[0_2px_12px_rgba(0,0,0,0.05)]"
                            >
                              <div
                                className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                                  isCredit ? 'bg-green-50' : 'bg-red-50'
                                }`}
                              >
                                {isCredit ? (
                                  <ArrowUp className="w-5 h-5 text-green-700" strokeWidth={2.5} />
                                ) : (
                                  <ArrowDown className="w-5 h-5 text-red-600" strokeWidth={2.5} />
                                )}
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-sm font-semibold text-gray-900 truncate">{txn.status}</p>
                                <p className="text-xs text-gray-500 truncate">
                                  {txn.vehicleRegNo} · {dayLine || txn.createdOn}
                                </p>
                              </div>
                              <div className="text-right shrink-0">
                                <p
                                  className={`text-sm font-bold tabular-nums ${isCredit ? 'text-green-600' : 'text-gray-900'}`}
                                >
                                  {isCredit ? '+' : '-'}₹{txn.amountINR.toLocaleString('en-IN')}
                                </p>
                                {timeFromCreated ? (
                                  <p className="text-xs text-gray-400 mt-0.5">{timeFromCreated}</p>
                                ) : null}
                              </div>
                            </div>
                          );
                        })
                      : mockTransactions.slice(0, 3).map((txn) => {
                          const isCredit = txn.type === 'Credit';
                          return (
                            <div
                              key={txn.id}
                              className="flex items-center gap-3 rounded-xl border border-gray-100 bg-white px-3.5 py-3 shadow-[0_2px_12px_rgba(0,0,0,0.05)]"
                            >
                              <div
                                className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                                  isCredit ? 'bg-green-50' : 'bg-red-50'
                                }`}
                              >
                                {isCredit ? (
                                  <ArrowUp className="w-5 h-5 text-green-700" strokeWidth={2.5} />
                                ) : (
                                  <ArrowDown className="w-5 h-5 text-red-600" strokeWidth={2.5} />
                                )}
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-sm font-semibold text-gray-900 truncate">{txn.station}</p>
                                <p className="text-xs text-gray-500 truncate">
                                  {txn.vrn} · {txn.dayLabel}
                                </p>
                              </div>
                              <div className="text-right shrink-0">
                                <p
                                  className={`text-sm font-bold tabular-nums ${isCredit ? 'text-green-600' : 'text-gray-900'}`}
                                >
                                  {isCredit ? '+' : '-'}₹{txn.amount.toLocaleString('en-IN')}
                                </p>
                                <p className="text-xs text-gray-400 mt-0.5">{txn.timeLabel}</p>
                              </div>
                            </div>
                          );
                        })}
                </div>
              </div>
            )}

            {/* Scan & Pay Tab */}
            {activeTab === 'scan' && (
              <div className="p-4 space-y-4 pb-24">
                {(sessionState === 'idle' || sessionState === 'scanning') && (() => {
                  const availableForScan = screenBindings.filter((b) => 
                    b.paired === true && 
                    b.state === "ACTIVE" &&
                    (b.scanPayStatus === "always_available" || 
                     b.scanPayStatus === "in_window" ||
                     b.scanPayStatus === "trip_window")
                  );

                  const lockedBindings = screenBindings.filter((b) =>
                    b.scanPayStatus === "locked_unpaired" ||
                    b.scanPayStatus === "locked_repair" ||
                    b.scanPayStatus === "out_window"
                  );

                  if (!selectedScanBinding && availableForScan.length > 0) {
                    setSelectedScanBinding(availableForScan[0]);
                  }

                  if (availableForScan.length === 0) {
                    return (
                      <div className="flex flex-col items-center justify-center py-12 space-y-6">
                        <QrCode className="w-12 h-12 text-gray-300" />
                        <div className="text-center">
                          <h2 className="text-lg font-bold text-gray-900 mb-1">Scan & Pay unavailable</h2>
                          <p className="text-sm text-gray-600">No vehicles available for scanning right now</p>
                        </div>
                        
                        {lockedBindings.length > 0 && (
                          <div className="w-full bg-gray-50 rounded-2xl p-4 space-y-3">
                            {lockedBindings.map(b => (
                              <div key={b.id} className="text-sm">
                                <p className="font-medium text-gray-900">{b.vrn}</p>
                                <p className="text-gray-600">
                                  {b.scanPayStatus === "locked_unpaired" && "Pair to unlock"}
                                  {b.scanPayStatus === "locked_repair" && "Re-pair required"}
                                  {b.scanPayStatus === "out_window" && "Outside shift/trip window"}
                                </p>
                              </div>
                            ))}
                          </div>
                        )}

                        <button 
                          onClick={() => setActiveTab('assignments')}
                          className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition"
                        >
                          Go to My Assignments
                        </button>
                      </div>
                    );
                  }

                  return (
                    <div className="space-y-4">
                      {availableForScan.length > 1 && (
                        <div className="flex gap-2 overflow-x-auto pb-2">
                          {availableForScan.map(b => (
                            <button
                              key={b.id}
                              onClick={() => setSelectedScanBinding(b)}
                              className={`px-3 py-1.5 rounded-full text-sm font-medium whitespace-nowrap transition ${
                                selectedScanBinding?.id === b.id
                                  ? "bg-green-600 text-white"
                                  : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                              }`}
                            >
                              {b.vrn}
                            </button>
                          ))}
                        </div>
                      )}

                      {selectedScanBinding && (
                        <div className="bg-gray-50 rounded-2xl p-3 space-y-2">
                          <p className="text-sm font-medium text-gray-900">Fueling: {selectedScanBinding.vrn}</p>
                          <div className="flex items-center gap-2">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                              selectedScanBinding.scanPayStatus === "always_available"
                                ? "bg-green-100 text-green-700"
                                : "bg-green-100 text-green-700"
                            }`}>
                              {selectedScanBinding.scanPayStatus === "always_available" && "Always available"}
                              {selectedScanBinding.scanPayStatus === "in_window" && `Active · ends ${selectedScanBinding.shiftEnd || "today"}`}
                              {selectedScanBinding.scanPayStatus === "trip_window" && `Active · ends ${selectedScanBinding.tripEnd || "today"}`}
                            </span>
                          </div>
                        </div>
                      )}

                      <div className="relative aspect-square w-full overflow-hidden rounded-2xl border-4 border-white bg-black">
                        <QrCameraScanner
                          active={
                            (sessionState === 'idle' || sessionState === 'scanning') &&
                            !!selectedScanBinding
                          }
                          onScan={handleFleetpayScan}
                          onCameraError={(msg) => setApiBanner(msg)}
                          className="h-full min-h-[220px]"
                        />
                      </div>

                      <button 
                        type="button"
                        onClick={() => {
                          if (!selectedScanBinding) return;
                          setApiBanner(null);
                          const exp = Math.floor(Date.now() / 1000) + 3600;
                          const demo = `fleetpay://pay?txn=QR-DEMO-${Date.now()}&mid=ADX7353085&mn=MGL+Hind+CNG+Filling&am=120000&cu=INR&exp=${exp}&tid=TID-DEMO1&sign=demo`;
                          const parsed = parseFleetpayPayUri(demo);
                          if (!parsed) return;
                          setQrTxnId(parsed.txnId);
                          setQrPayFields(parsed);
                          setActiveScanBinding(selectedScanBinding);
                          setSessionState('confirmation');
                        }} 
                        className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition"
                      >
                        Simulate Scan
                      </button>
                    </div>
                  );
                })()}

                {sessionState === 'confirmation' && activeScanBinding && (
                  <>
                    <div className="flex items-center justify-between mb-4">
                      <h2 className="text-lg font-bold text-gray-900">Confirm fueling</h2>
                      <button
                        type="button"
                        onClick={() => {
                          setSessionState('idle');
                          setActiveScanBinding(null);
                          setSessionPin('');
                          setQrPayFields(null);
                        }}
                        className="text-gray-600 hover:text-gray-900"
                      >
                        <X className="w-5 h-5" />
                      </button>
                    </div>

                    {/* Station Card */}
                    <div className="bg-white border border-gray-200 rounded-2xl p-4 mb-4">
                      <div className="flex items-start gap-3">
                        <MapPin className="w-5 h-5 text-green-700 flex-shrink-0 mt-0.5" />
                        <div>
                          <p className="font-semibold text-gray-900">
                            {qrPayFields?.merchantName ?? 'MGL Hind CNG Filling Station'}
                          </p>
                          <p className="text-sm text-gray-600">
                            {qrPayFields?.mid ? `MID ${qrPayFields.mid}` : 'Andheri, Mumbai'}
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Fueling Details */}
                    <div className="bg-gray-50 rounded-2xl p-4 space-y-2 mb-4">
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Amount</span>
                        <span className="font-medium text-gray-900">
                          ₹{qrPayFields ? paiseToInrDisplay(qrPayFields.amountPaise) : '—'}
                        </span>
                      </div>
                      <div className="flex justify-between text-sm border-t border-gray-200 pt-2">
                        <span className="text-gray-600">Vehicle</span>
                        <span className="font-medium text-gray-900">{activeScanBinding.vrn}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Fleet Operator</span>
                        <span className="font-medium text-gray-900">{activeScanBinding.fo}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Available balance</span>
                        <span className="font-medium text-green-700">₹{activeScanBinding.balance?.toLocaleString('en-IN') || '0'}</span>
                      </div>
                      <div className="flex justify-between text-sm border-t border-gray-200 pt-2">
                        <span className="text-gray-600">Spend limit</span>
                        <span className="font-medium text-gray-900">₹{activeScanBinding.spendLimit?.toLocaleString('en-IN') || '5,000'}</span>
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        setSessionPin('');
                        setSessionState('pin_confirm');
                      }}
                      className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition"
                    >
                      Continue
                    </button>
                  </>
                )}

                {sessionState === 'pin_confirm' && activeScanBinding && (
                  <>
                    <div className="flex items-center gap-3 mb-4">
                      <button
                        type="button"
                        onClick={() => {
                          setSessionPin('');
                          setSessionState('confirmation');
                        }}
                        className="text-gray-600 hover:text-gray-900"
                        aria-label="Back"
                      >
                        <ChevronLeft className="w-5 h-5" />
                      </button>
                      <h2 className="text-lg font-bold text-gray-900">Enter PIN</h2>
                    </div>

                    <div className="mb-4">
                      <p className="text-sm font-medium text-gray-900 mb-2">Enter your PIN to confirm</p>
                      <PinDisplay value={sessionPin} />
                      <Numpad onPress={handleSessionPinInput} onBackspace={handleSessionPinBackspace} />
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        void (async () => {
                          if (USE_DRIVER_API && foScopedToken && activeScanBinding && qrPayFields) {
                            if (sessionPin.length < 4 || sessionPin.length > 6) return;
                            try {
                              setApiBanner(null);
                              await driverQrPay(DRIVER_API_BASE, foScopedToken, {
                                txnId: qrPayFields.txnId,
                                vehicleRegNo: activeScanBinding.vrn.replace(/\s+/g, ''),
                                pin: sessionPin,
                                mid: qrPayFields.mid,
                                terminalId: qrPayFields.terminalId,
                                amountPaise: qrPayFields.amountPaise,
                                expiryEpoch: qrPayFields.expiryEpoch,
                                sign: qrPayFields.sign,
                              });
                              setSessionPin('');
                              setSessionState('complete');
                              const [home, tx] = await Promise.all([
                                driverGetHome(DRIVER_API_BASE, foScopedToken),
                                driverGetTransactions(DRIVER_API_BASE, foScopedToken, 0),
                              ]);
                              setApiHome(home);
                              setApiTxns(tx);
                            } catch (e) {
                              setApiBanner(e instanceof Error ? e.message : String(e));
                            }
                            return;
                          }
                          if (sessionPin.length !== 6) return;
                          if (sessionPin === pin) setSessionState('otp_entry');
                          else setSessionPin('');
                        })();
                      }}
                      disabled={
                        USE_DRIVER_API
                          ? sessionPin.length < 4 || sessionPin.length > 6 || !qrPayFields
                          : sessionPin.length !== 6
                      }
                      className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition"
                    >
                      Verify PIN
                    </button>
                  </>
                )}

                {sessionState === 'otp_entry' && activeScanBinding && (
                  <>
                    <div className="flex items-center gap-3 mb-4">
                      <button type="button" onClick={() => setSessionState('pin_confirm')} className="text-gray-600">
                        <ChevronLeft className="w-5 h-5" />
                      </button>
                      <h2 className="text-lg font-bold text-gray-900">One-time password</h2>
                    </div>

                    <div className="bg-blue-50 border border-blue-200 rounded-2xl p-3 mb-4">
                      <p className="text-sm text-blue-900">OTP sent to +91 {mobileNumber.slice(-4).padStart(10, '•')}</p>
                    </div>

                    <div className="bg-gray-100 rounded-2xl p-3 mb-4">
                      <p className="text-xs text-gray-600">
                        {activeScanBinding.vrn} · {qrPayFields?.merchantName ?? 'Station'} · ₹
                        {qrPayFields ? paiseToInrDisplay(qrPayFields.amountPaise) : '1,200.00'}
                      </p>
                    </div>

                    <div className="flex justify-center gap-1 mb-4">
                      {Array.from({ length: 6 }).map((_, i) => (
                        <input key={i} type="text" inputMode="numeric" maxLength={1} value={sessionOtp[i] || ''} onChange={(e) => handleSessionOtpChange(i, e.target.value)} className="session-otp-digit w-10 h-10 text-center text-lg font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-700 focus:ring-2 focus:ring-green-100" />
                      ))}
                    </div>

                    <p className="text-center text-xs text-red-600 mb-4">Session expires in 1:24</p>

                    <button onClick={() => { if (sessionOtp.length === 6) setSessionState('authorized'); }} disabled={sessionOtp.length !== 6} className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mb-2">
                      Verify & Authorize
                    </button>

                    <button className="w-full text-green-700 font-medium py-2 text-sm">Resend OTP</button>
                  </>
                )}

                {sessionState === 'authorized' && (
                  <>
                    <div className="flex flex-col items-center justify-center py-8">
                      <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4">
                        <Check className="w-8 h-8 text-green-700" />
                      </div>
                      <h2 className="text-2xl font-bold text-gray-900 mb-1">Fueling authorized</h2>
                      <p className="text-sm text-gray-600 text-center mb-6">Dispenser is now unlocked</p>
                    </div>

                    <div className="bg-white border border-gray-200 rounded-2xl p-4 mb-4">
                      <p className="text-xs text-gray-600 mb-2">{qrPayFields?.merchantName ?? 'Station'}</p>
                      <p className="font-semibold text-gray-900">
                        Pre-authorized: ₹
                        {qrPayFields ? paiseToInrDisplay(qrPayFields.amountPaise) : '1,200.00'}
                      </p>
                    </div>

                    <div className="bg-amber-50 border border-amber-300 rounded-2xl p-3 mb-4">
                      <p className="text-xs text-amber-900">⚠ Do not leave the pump until fueling is complete</p>
                    </div>

                    <div className="bg-gray-50 rounded-2xl p-4 text-center mb-4">
                      <p className="text-xs text-gray-600 mb-1">Dispensing</p>
                      <p className="text-2xl font-bold text-gray-900">2.4 kg</p>
                      <p className="text-sm text-gray-600 mt-1">₹384</p>
                    </div>

                    <button onClick={() => { setSessionState('complete'); setDispensingAmount(4.2); }} className="w-full bg-green-700 text-white font-medium py-3 rounded-2xl">
                      Fueling Complete
                    </button>
                  </>
                )}

                {sessionState === 'complete' && activeScanBinding && (
                  <>
                    <div className="bg-white rounded-2xl p-6 text-center mb-4">
                      <div className="flex justify-center mb-4">
                        <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                          <Check className="w-6 h-6 text-green-700" />
                        </div>
                      </div>
                      <h2 className="text-xl font-bold text-gray-900 mb-1">Fueling Complete</h2>
                      <div className="border-t border-gray-200 my-4 pt-4 text-left space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600">Station</span>
                          <span className="font-medium">MGL Hind Station</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Vehicle</span>
                          <span className="font-medium">{activeScanBinding.vrn}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Quantity</span>
                          <span className="font-bold">4.2 kg</span>
                        </div>
                        <div className="flex justify-between border-t border-gray-200 pt-2">
                          <span className="text-gray-900 font-semibold">Amount</span>
                          <span className="font-bold text-green-700">₹672</span>
                        </div>
                      </div>
                    </div>

                    <button onClick={() => { setSessionState('idle'); setActiveTab('card'); setActiveScanBinding(null); }} className="w-full bg-green-700 text-white font-medium py-3 rounded-2xl">
                      Done
                    </button>
                  </>
                )}
              </div>
            )}

            {/* Assignments Tab */}
            {/* Assignments Tab */}
            {activeTab === 'assignments' && (
              <div className="p-4 pb-8 space-y-4">
                {/* Header */}
                <div>
                  <h2 className="text-2xl font-bold text-gray-900">My Assignments</h2>
                  <p className="text-xs text-gray-600 mt-1">{activeBindings.length} active · {pendingBindings.length + repairBindings.length} need attention</p>
                </div>

                {/* SECTION 1: Active Assignments */}
                {activeBindings.length > 0 && (
                  <div className="space-y-3">
                    <h3 className="text-xs uppercase font-semibold text-gray-500 tracking-wide">Active</h3>
                    {activeBindings.map((binding) => (
                      <div key={binding.id}>
                        {/* Vehicle-Linked */}
                        {binding.authMode === 'vehicle_linked' && (
                          <div className="border-l-4 border-green-700 bg-white rounded-xl overflow-hidden">
                            <div className="p-5 h-full flex flex-col justify-between min-h-[160px]">

                              {/* Top row: FO name left, MGL badge right */}
                              <div className="flex justify-between items-start">
                                <p className="text-gray-700 text-xs font-medium tracking-wide uppercase">
                                  {binding.fo}
                                </p>
                                <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0 ml-2">
                                  <span className="text-green-700 text-xs font-bold">MGL</span>
                                </div>
                              </div>

                              {/* VRN middle */}
                              <p className="text-gray-900 font-mono font-bold text-xl tracking-widest my-3">
                                {binding.vrn}
                              </p>

                              {/* Bottom row: auth pill left, context right — single line */}
                              <div className="flex items-center justify-between gap-2">
                                
                                {/* Auth mode pill — fixed width, no wrap */}
                                <span className="px-2.5 py-1 rounded-full text-xs font-semibold whitespace-nowrap flex-shrink-0 bg-green-100 text-green-700">
                                  Vehicle-linked
                                </span>

                                {/* Context text right — truncate if too long */}
                                <p className="text-gray-600 text-xs text-right truncate">
                                  Active
                                </p>

                              </div>
                            </div>
                            <div className="border-t border-gray-100 pt-3 flex gap-3 px-5 pb-3">
                              {/* Scan & Pay icon button */}
                              <button
                                onClick={() => { setSessionState('scanning'); setActiveTab('scan'); }}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-green-50 hover:bg-green-100 transition-colors">
                                <QrCode className="w-5 h-5 text-green-700" />
                                <span className="text-xs font-medium text-green-700">Scan & Pay</span>
                              </button>

                              {/* Transactions icon button */}
                              <button
                                onClick={() => setActiveTab('transactions')}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-gray-50 hover:bg-gray-100 transition-colors">
                                <History className="w-5 h-5 text-gray-500" />
                                <span className="text-xs font-medium text-gray-500">Transactions</span>
                              </button>

                              {/* Details button */}
                              <button
                                type="button"
                                onClick={() => setAssignmentDetailBinding(binding)}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-gray-50 hover:bg-gray-100 transition-colors">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#6b7280" strokeWidth="2" strokeLinecap="round">
                                  <circle cx="12" cy="12" r="10"/>
                                  <line x1="12" y1="8" x2="12" y2="12"/>
                                  <line x1="12" y1="16" x2="12.01" y2="16"/>
                                </svg>
                                <span className="text-xs font-medium text-gray-500">Details</span>
                              </button>
                            </div>
                          </div>
                        )}

                        {/* Shift-Based */}
                        {binding.authMode === 'shift_based' && binding.scanPayStatus === 'in_window' && (
                          <div className="border-l-4 border-green-700 bg-white rounded-xl overflow-hidden">
                            <div className="p-5 h-full flex flex-col justify-between min-h-[160px]">

                              {/* Top row: FO name left, MGL badge right */}
                              <div className="flex justify-between items-start">
                                <p className="text-gray-700 text-xs font-medium tracking-wide uppercase">
                                  {binding.fo}
                                </p>
                                <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0 ml-2">
                                  <span className="text-green-700 text-xs font-bold">MGL</span>
                                </div>
                              </div>

                              {/* VRN middle */}
                              <p className="text-gray-900 font-mono font-bold text-xl tracking-widest my-3">
                                {binding.vrn}
                              </p>

                              {/* Bottom row: auth pill left, context right — single line */}
                              <div className="flex items-center justify-between gap-2">
                                
                                {/* Auth mode pill — fixed width, no wrap */}
                                <span className="px-2.5 py-1 rounded-full text-xs font-semibold whitespace-nowrap flex-shrink-0 bg-green-100 text-green-700">
                                  {`Shift · ends ${binding.shiftEnd}`}
                                </span>

                                {/* Context text right — truncate if too long */}
                                <p className="text-gray-600 text-xs text-right truncate">
                                  {binding.shiftEndsIn}
                                </p>

                              </div>
                            </div>
                            <div className="border-t border-gray-100 pt-3 flex gap-3 px-5 pb-3">
                              {/* Scan & Pay icon button */}
                              <button
                                onClick={() => { setSessionState('scanning'); setActiveTab('scan'); }}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-green-50 hover:bg-green-100 transition-colors">
                                <QrCode className="w-5 h-5 text-green-700" />
                                <span className="text-xs font-medium text-green-700">Scan & Pay</span>
                              </button>

                              {/* Transactions icon button */}
                              <button
                                onClick={() => setActiveTab('transactions')}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-gray-50 hover:bg-gray-100 transition-colors">
                                <History className="w-5 h-5 text-gray-500" />
                                <span className="text-xs font-medium text-gray-500">Transactions</span>
                              </button>

                              {/* Schedule button */}
                              <button
                                onClick={() => { setShowShiftSchedule(true); setSelectedShiftBinding(binding); }}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-gray-50 hover:bg-gray-100 transition-colors">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#6b7280" strokeWidth="2" strokeLinecap="round">
                                  <rect x="3" y="4" width="18" height="18" rx="2"/>
                                  <line x1="16" y1="2" x2="16" y2="6"/>
                                  <line x1="8" y1="2" x2="8" y2="6"/>
                                  <line x1="3" y1="10" x2="21" y2="10"/>
                                  <path d="M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01"/>
                                </svg>
                                <span className="text-xs font-medium text-gray-500">Schedule</span>
                              </button>
                            </div>
                          </div>
                        )}

                        {/* Trip-Linked */}
                        {binding.authMode === 'trip_linked' && binding.scanPayStatus === 'in_window' && (
                          <div className="border-l-4 border-blue-600 bg-white rounded-xl overflow-hidden">
                            <div className="p-5 h-full flex flex-col justify-between min-h-[160px]">

                              {/* Top row: FO name left, MGL badge right */}
                              <div className="flex justify-between items-start">
                                <p className="text-gray-700 text-xs font-medium tracking-wide uppercase">
                                  {binding.fo}
                                </p>
                                <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0 ml-2">
                                  <span className="text-blue-700 text-xs font-bold">MGL</span>
                                </div>
                              </div>

                              {/* VRN middle */}
                              <p className="text-gray-900 font-mono font-bold text-xl tracking-widest my-3">
                                {binding.vrn}
                              </p>

                              {/* Bottom row: auth pill left, context right — single line */}
                              <div className="flex items-center justify-between gap-2">
                                
                                {/* Auth mode pill — fixed width, no wrap */}
                                <span className="px-2.5 py-1 rounded-full text-xs font-semibold whitespace-nowrap flex-shrink-0 bg-blue-100 text-blue-700">
                                  {`Trip · ends ${binding.tripEnd}`}
                                </span>

                                {/* Context text right — truncate if too long */}
                                <p className="text-gray-600 text-xs text-right truncate">
                                  {`${binding.origin} → ${binding.destination}`}
                                </p>

                              </div>
                            </div>
                            <div className="border-t border-gray-100 pt-3 flex gap-3 px-5 pb-3">
                              {/* Scan & Pay icon button */}
                              <button
                                onClick={() => { setSessionState('scanning'); setActiveTab('scan'); }}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-green-50 hover:bg-green-100 transition-colors">
                                <QrCode className="w-5 h-5 text-green-700" />
                                <span className="text-xs font-medium text-green-700">Scan & Pay</span>
                              </button>

                              {/* Transactions icon button */}
                              <button
                                onClick={() => setActiveTab('transactions')}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-gray-50 hover:bg-gray-100 transition-colors">
                                <History className="w-5 h-5 text-gray-500" />
                                <span className="text-xs font-medium text-gray-500">Transactions</span>
                              </button>

                              {/* Trip info button */}
                              <button
                                onClick={() => { setShowTripDetails(true); setSelectedTripBinding(binding); }}
                                className="flex-1 flex flex-col items-center gap-1 py-2 rounded-xl bg-gray-50 hover:bg-gray-100 transition-colors">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#6b7280" strokeWidth="2" strokeLinecap="round">
                                  <circle cx="12" cy="10" r="3"/>
                                  <path d="M12 2a8 8 0 0 0-8 8c0 5.4 7 12 8 12s8-6.6 8-12a8 8 0 0 0-8-8z"/>
                                </svg>
                                <span className="text-xs font-medium text-gray-500">Trip info</span>
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}

                {/* SECTION 2: Needs Attention */}
                {(pendingBindings.length > 0 || repairBindings.length > 0) && (
                  <div className="space-y-3">
                    <h3 className="text-xs uppercase font-semibold text-amber-600 tracking-wide">Needs attention</h3>
                    
                    {/* Pending Acceptance */}
                    {pendingBindings.map((binding) => (
                      <div key={binding.id} className="border-2 border-dashed border-amber-300 bg-white rounded-xl p-4 space-y-3">
                        <div className="flex justify-between items-start">
                          <p className="font-mono font-bold text-lg text-gray-900">{binding.vrn}</p>
                          <span className="px-3 py-1 bg-amber-100 text-amber-700 text-xs font-semibold rounded-full">Action needed</span>
                        </div>
                        <div className="flex justify-between items-start text-sm">
                          <span className="text-gray-600">Vehicle-linked</span>
                          <span className="text-gray-900 font-medium">{binding.fo}</span>
                        </div>
                        <p className="text-xs text-gray-600">Assigned by {binding.assignedBy} · 2h ago</p>
                        <div className="flex items-center gap-2 text-sm text-amber-700">
                          <Lock className="w-4 h-4" />
                          <span>Pair to unlock Scan & Pay</span>
                        </div>
                        <div className="border-t border-gray-100 pt-3 space-y-2">
                          <button onClick={() => { setActiveAssignment(binding); setCurrentMainScreen('assignment_notification'); }} className="w-full bg-green-700 hover:bg-green-800 text-white text-xs font-medium py-2 rounded-lg transition">
                            Accept & Pair
                          </button>
                          <button onClick={() => setDeclineBndId(binding.id)} className="w-full border border-red-300 hover:bg-red-50 text-red-600 text-xs font-medium py-2 rounded-lg transition">
                            Decline
                          </button>
                        </div>
                      </div>
                    ))}

                    {/* Re-pair Required */}
                    {repairBindings.map((binding) => (
                      <div key={binding.id} className="border-2 border-dashed border-red-300 bg-white rounded-xl p-4 space-y-3">
                        <div className="flex justify-between items-start">
                          <p className="font-mono font-bold text-lg text-gray-900">{binding.vrn}</p>
                          <span className="px-3 py-1 bg-red-100 text-red-700 text-xs font-semibold rounded-full">Re-pair required</span>
                        </div>
                        <div className="text-sm text-gray-600">{binding.authMode === 'shift_based' ? 'Shift-based' : 'Vehicle-linked'} · {binding.fo}</div>
                        <p className="text-xs text-gray-600">Reason: {binding.repairReason}</p>
                        <div className="flex items-center gap-2 text-sm text-red-700">
                          <Lock className="w-4 h-4" />
                          <span>Scan & Pay locked until re-paired</span>
                        </div>
                        <div className="border-t border-gray-100 pt-3">
                          <button onClick={() => { setActiveAssignment(binding); setCurrentMainScreen('pairing_code'); }} className="w-full border border-amber-300 hover:bg-amber-50 text-amber-700 text-xs font-medium py-2 rounded-lg transition">
                            Enter new pairing code
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {/* Empty State */}
                {activeBindings.length === 0 && pendingBindings.length === 0 && repairBindings.length === 0 && (
                  <div className="text-center py-12">
                    <Route className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                    <p className="text-gray-600 font-medium mb-1">No assignments yet</p>
                    <p className="text-sm text-gray-500">Your Fleet Operator will assign vehicles and trips here</p>
                  </div>
                )}
              </div>
            )}

            {/* Shift Schedule Modal */}
            {showShiftSchedule && selectedShiftBinding && (
              <div className="fixed inset-0 bg-black/50 flex items-end z-50">
                <div className="bg-white w-full rounded-t-2xl p-6 space-y-4">
                  <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-bold text-gray-900">Shift schedule</h3>
                    <button onClick={() => { setShowShiftSchedule(false); setSelectedShiftBinding(null); }} className="text-gray-500 hover:text-gray-700">
                      <X className="w-5 h-5" />
                    </button>
                  </div>
                  <div className="space-y-2 max-h-96 overflow-y-auto">
                    <div className="grid grid-cols-3 gap-2 text-xs font-medium text-gray-600 mb-3">
                      <div>Day</div>
                      <div>Start</div>
                      <div>End</div>
                    </div>
                    {selectedShiftBinding.shiftDays?.map((day) => (
                      <div key={day} className="grid grid-cols-3 gap-2 text-sm text-gray-900 py-2 border-b border-gray-100">
                        <div>{day}</div>
                        <div className="font-mono">{selectedShiftBinding.shiftStart}</div>
                        <div className="font-mono">{selectedShiftBinding.shiftEnd}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Trip Details Modal */}
            {showTripDetails && selectedTripBinding && (
              <div className="fixed inset-0 bg-black/50 flex items-end z-50">
                <div className="bg-white w-full rounded-t-2xl p-6 space-y-4">
                  <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-bold text-gray-900">Trip details</h3>
                    <button onClick={() => { setShowTripDetails(false); setSelectedTripBinding(null); }} className="text-gray-500 hover:text-gray-700">
                      <X className="w-5 h-5" />
                    </button>
                  </div>
                  <div className="space-y-3 text-sm">
                    <div className="flex justify-between py-2 border-b border-gray-100">
                      <span className="text-gray-600">Vehicle</span>
                      <span className="font-mono font-medium text-gray-900">{selectedTripBinding.vrn}</span>
                    </div>
                    <div className="flex justify-between py-2 border-b border-gray-100">
                      <span className="text-gray-600">Date</span>
                      <span className="font-medium text-gray-900">{selectedTripBinding.tripDate}</span>
                    </div>
                    <div className="flex justify-between py-2 border-b border-gray-100">
                      <span className="text-gray-600">Window</span>
                      <span className="font-medium text-gray-900">{selectedTripBinding.tripStart} – {selectedTripBinding.tripEnd}</span>
                    </div>
                    <div className="flex justify-between py-2 border-b border-gray-100">
                      <span className="text-gray-600">From</span>
                      <span className="font-medium text-gray-900">{selectedTripBinding.origin}</span>
                    </div>
                    <div className="flex justify-between py-2 border-b border-gray-100">
                      <span className="text-gray-600">To</span>
                      <span className="font-medium text-gray-900">{selectedTripBinding.destination}</span>
                    </div>
                    <div className="flex justify-between py-2">
                      <span className="text-gray-600">Notes</span>
                      <span className="font-medium text-gray-900">Client delivery</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Decline Confirmation Dialog */}
            {declineBndId && (
              <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                <div className="bg-white rounded-2xl p-6 max-w-sm space-y-4">
                  <h3 className="text-lg font-bold text-gray-900">Decline this assignment?</h3>
                  <p className="text-sm text-gray-600">This will notify your Fleet Operator.</p>
                  <div className="flex gap-3 pt-2">
                    <button onClick={() => setDeclineBndId(null)} className="flex-1 border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2 rounded-lg transition">
                      Cancel
                    </button>
                    <button onClick={() => { setDeclineBndId(null); }} className="flex-1 bg-red-600 hover:bg-red-700 text-white font-medium py-2 rounded-lg transition">
                      Yes, decline
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Transactions Tab */}
            {activeTab === 'transactions' && (
              <div>
                <div className="flex gap-2 px-4 py-3 border-b border-gray-100 overflow-x-auto">
                  {[
                    { key: 'all', label: 'All' },
                    { key: 'successful', label: 'Successful' },
                    { key: 'failed', label: 'Failed' },
                  ].map(f => (
                    <button
                      key={f.key}
                      onClick={() => setTxnFilter(f.key as typeof txnFilter)}
                      className={`px-4 py-1.5 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
                        txnFilter === f.key ?
                          "bg-green-600 text-white" :
                          "bg-gray-100 text-gray-600"
                      }`}>
                      {f.label}
                    </button>
                  ))}
                </div>
                <div className="p-4 space-y-2">
                  {(USE_DRIVER_API
                    ? apiTxns.filter((t) => {
                        if (txnFilter === 'all') return true;
                        if (txnFilter === 'successful') return t.status === 'SUCCESS';
                        if (txnFilter === 'failed') return t.status !== 'SUCCESS';
                        return true;
                      })
                    : mockTransactions.filter((t) => {
                        if (txnFilter === 'all') return true;
                        if (txnFilter === 'successful') return t.status === 'Success';
                        if (txnFilter === 'failed') return t.status === 'Failed';
                        return true;
                      })
                  ).map((txn) =>
                    USE_DRIVER_API ? (
                      <div key={(txn as DriverTxnRow).serverTxnId} className="bg-white border border-gray-200 rounded-xl p-3">
                        <div className="flex justify-between items-start mb-1">
                          <div>
                            <p className="text-sm font-medium text-gray-900">{(txn as DriverTxnRow).serverTxnId}</p>
                            <p className="text-xs text-gray-600">{(txn as DriverTxnRow).vehicleRegNo}</p>
                          </div>
                          <p className="text-sm font-bold text-red-600">₹{(txn as DriverTxnRow).amountINR}</p>
                        </div>
                        <p className="text-xs text-gray-600">{(txn as DriverTxnRow).createdOn}</p>
                      </div>
                    ) : (
                      <div key={(txn as (typeof mockTransactions)[0]).id} className="bg-white border border-gray-200 rounded-xl p-3">
                        <div className="flex justify-between items-start mb-1">
                          <div>
                            <p className="text-sm font-medium text-gray-900">{(txn as (typeof mockTransactions)[0]).station}</p>
                            <p className="text-xs text-gray-600">{(txn as (typeof mockTransactions)[0]).vrn}</p>
                          </div>
                          <p className={`text-sm font-bold ${(txn as (typeof mockTransactions)[0]).type === 'Fueling' ? 'text-red-600' : 'text-green-600'}`}>{(txn as (typeof mockTransactions)[0]).type === 'Fueling' ? '-' : '+'}₹{(txn as (typeof mockTransactions)[0]).amount}</p>
                        </div>
                        <p className="text-xs text-gray-600">{(txn as (typeof mockTransactions)[0]).date}</p>
                      </div>
                    )
                  )}
                </div>
              </div>
            )}

            {/* Profile Tab */}
            {activeTab === 'profile' && (
              <div className="p-4 pb-8">
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-green-200 rounded-full flex items-center justify-center mx-auto mb-2">
                    <span className="text-2xl font-bold text-green-700">
                      {driverDisplayName.trim().charAt(0).toUpperCase() || '?'}
                    </span>
                  </div>
                  <h2 className="font-bold text-gray-900">{driverDisplayName}</h2>
                  <p className="text-xs text-gray-600">
                    {USE_DRIVER_API && apiProfileState
                      ? `Driver · FO ${apiProfileState.foStatus ?? ''}`
                      : 'Driver · ABC Logistics'}
                  </p>
                </div>

                <div className="space-y-4">
                  <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
                    <h3 className="px-4 py-3 font-semibold text-gray-900 border-b border-gray-200">Account Details</h3>
                    <div className="divide-y divide-gray-200">
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">Mobile</span>
                        <span className="font-medium">
                          {USE_DRIVER_API && apiProfileState ? apiProfileState.maskedMobile : `+91 ${mobileNumber}`}
                        </span>
                      </div>
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">Driver ID</span>
                        <span className="font-medium">
                          {USE_DRIVER_API && apiProfileState ? apiProfileState.driverId : 'DRV-00123'}
                        </span>
                      </div>
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">DL</span>
                        <span className="font-medium">
                          {USE_DRIVER_API && apiProfileState?.dlNumber ? apiProfileState.dlNumber : '—'}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
                    <h3 className="px-4 py-3 font-semibold text-gray-900 border-b border-gray-200">My Vehicles</h3>
                    {USE_DRIVER_API
                      ? apiAssignments.map((a) => (
                          <div key={a.vehicleDriverId} className="px-4 py-3 border-b border-gray-200 last:border-0">
                            <p className="font-medium text-gray-900 text-sm">{a.vehicleRegNo}</p>
                            <p className="text-xs text-gray-600 mt-1">{a.assignmentType}</p>
                            <div className="flex gap-2 items-center mt-2">
                              <span className="px-2 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium">{a.status}</span>
                              <span className="w-2 h-2 bg-green-600 rounded-full" />
                            </div>
                          </div>
                        ))
                      : pairedVehicles.map((vehicle, idx) => (
                          <div key={idx} className="px-4 py-3 border-b border-gray-200 last:border-0">
                            <p className="font-medium text-gray-900 text-sm">{vehicle.vrn}</p>
                            <p className="text-xs text-gray-600 mt-1">{vehicle.company}</p>
                            <div className="flex gap-2 items-center mt-2">
                              <span className="px-2 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium">{vehicle.authMode}</span>
                              <span className="w-2 h-2 bg-green-600 rounded-full" />
                            </div>
                          </div>
                        ))}
                  </div>

                  <button onClick={handleLogout} className="w-full border-2 border-red-300 text-red-600 font-medium py-3 rounded-2xl hover:bg-red-50 transition">
                    Logout
                  </button>
                </div>
              </div>
            )}
          </div>

          </>
          )}

          {/* Bottom Navigation */}
          <div className="border-t border-gray-200 bg-white flex justify-around items-center h-20 px-2">
            {[{ id: 'card', icon: Home, label: 'Home' }, { id: 'scan', icon: QrCode, label: 'Scan & Pay' }, { id: 'assignments', icon: Route, label: 'My Assignments' }, { id: 'profile', icon: User, label: 'Profile' }].map((tab) => (
              <button key={tab.id} onClick={() => setActiveTab(tab.id as typeof activeTab)} className={`flex flex-col items-center gap-1 py-2 transition ${activeTab === tab.id ? 'text-green-700' : 'text-gray-500'}`}>
                <tab.icon className="w-6 h-6" />
                <span className="text-xs font-medium">{tab.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Assignment sheet: sibling of main scroll area */}
        {assignmentDetailBinding && (
          <div
            className="pointer-events-auto absolute inset-x-0 top-0 bottom-20 z-[80] flex min-h-0 w-full flex-col justify-end bg-black/50 overflow-hidden"
            role="presentation"
            onClick={() => setAssignmentDetailBinding(null)}
          >
            <div
              role="dialog"
              aria-labelledby="assignment-detail-vrn"
              className="w-full min-h-0 min-w-0 max-h-[82%] overflow-x-hidden overflow-y-auto rounded-t-2xl bg-white shadow-[0_-8px_32px_rgba(0,0,0,0.14)] box-border animate-in slide-in-from-bottom duration-200"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex min-w-0 justify-between items-center gap-3 border-b border-gray-100 px-4 pt-4 pb-3 sm:px-5 sm:pt-5 sm:pb-4">
                <p
                  id="assignment-detail-vrn"
                  className="min-w-0 flex-1 break-all font-mono text-base font-bold tracking-wide text-gray-900"
                >
                  {assignmentDetailBinding.vrn}
                </p>
                <button
                  type="button"
                  onClick={() => setAssignmentDetailBinding(null)}
                  className="shrink-0 rounded-lg p-1 text-gray-500 hover:text-gray-700"
                  aria-label="Close"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
              <div className="min-w-0 divide-y divide-gray-100 px-4 pb-6 pt-1 sm:px-5 sm:pb-8">
                <div className="flex min-w-0 items-center justify-between gap-3 py-3.5 text-sm">
                  <span className="shrink-0 text-gray-600">Balance</span>
                  <span className="shrink-0 text-right font-bold tabular-nums text-gray-900">
                    ₹
                    {(assignmentDetailBinding.balance ??
                      assignmentDetailBinding.cardBalance ??
                      0
                    ).toLocaleString('en-IN')}
                  </span>
                </div>
                <div className="flex min-w-0 items-center justify-between gap-3 py-3.5 text-sm">
                  <span className="shrink-0 text-gray-600">Assigned At</span>
                  <span className="min-w-0 break-words text-right font-bold text-gray-900">
                    {assignmentDetailBinding.assignedAt
                      ? new Date(assignmentDetailBinding.assignedAt).toLocaleString('en-IN', {
                          dateStyle: 'medium',
                          timeStyle: 'short',
                        })
                      : '—'}
                  </span>
                </div>
                <div className="flex min-w-0 items-start justify-between gap-3 py-3.5 text-sm">
                  <span className="shrink-0 pt-0.5 text-gray-600">Fleet Operator</span>
                  <span className="min-w-0 flex-1 break-words text-right font-bold text-gray-900">
                    {assignmentDetailBinding.fo?.trim() ? assignmentDetailBinding.fo : '—'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

      {/* Dev Menu Trigger */}
      <button 
        onClick={() => setShowDevMenu(!showDevMenu)}
        className="fixed bottom-20 right-2 w-8 h-8 
          bg-gray-200 rounded-full text-xs text-gray-500
          flex items-center justify-center z-50"
      >
        ⋮
      </button>
      {showDevMenu && (
        <div className="absolute top-4 right-4 bg-gray-800 text-white p-3 rounded text-xs space-y-1">
          <button onClick={() => { setSessionState(sessionState === 'authorized' ? 'idle' : 'authorized'); setShowDevMenu(false); }} className="block w-full text-left hover:bg-gray-700 p-1">Toggle Auth State</button>
        </div>
      )}
    </div>
  );
}
