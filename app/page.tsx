'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { ChevronLeft, X, Lock, MapPin, AlertCircle, User, Clock, Check, CreditCard, Zap, QrCode, History, Shield, LogOut, Eye, EyeOff, Home, CheckCircle, ArrowDown, ArrowUp, Share, Loader2, Truck, FileText, Info, XCircle } from 'lucide-react';
import {
  driverAcceptPairing,
  driverFoList,
  driverFoSelect,
  driverInviteMobileSendOtp,
  driverInviteMobileVerifyOtp,
  driverOauthOtpGrant,
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
  type QrPayResult,
} from '../components/mgl/driver-api';
import { QrCameraScanner } from '../components/mgl/qr-camera-scanner';
import {
  parseFleetpayPayUri,
  paiseToInrDisplay,
  type FleetpayQrPayload,
} from '../components/mgl/fleetpay-qr';

const DRIVER_API_BASE = getDriverApiBase();
const DRIVER_APP_FO_TOKEN_KEY = 'mgl_driver_app_fo_token';
const DRIVER_APP_FO_NAME_KEY = 'mgl_driver_app_fo_name';
const DRIVER_APP_FO_COMPANY_ID_KEY = 'mgl_driver_app_fo_company_id';

function persistFleetOperatorLocalStorage(name: string, foCompanyId: number | null) {
  if (typeof window === 'undefined') return;
  try {
    const n = name.trim();
    if (n) localStorage.setItem(DRIVER_APP_FO_NAME_KEY, n);
    else localStorage.removeItem(DRIVER_APP_FO_NAME_KEY);
    if (foCompanyId != null && Number.isFinite(foCompanyId)) {
      localStorage.setItem(DRIVER_APP_FO_COMPANY_ID_KEY, String(foCompanyId));
    } else {
      localStorage.removeItem(DRIVER_APP_FO_COMPANY_ID_KEY);
    }
  } catch {
    /* ignore */
  }
}

function clearFleetOperatorLocalStorage() {
  if (typeof window === 'undefined') return;
  try {
    localStorage.removeItem(DRIVER_APP_FO_NAME_KEY);
    localStorage.removeItem(DRIVER_APP_FO_COMPANY_ID_KEY);
  } catch {
    /* ignore */
  }
}

function driverInitialsFromName(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  const one = parts[0] ?? '';
  if (one.length >= 2) return one.slice(0, 2).toUpperCase();
  return one.toUpperCase() || '?';
}

const MOBILE_INDIA_PATTERN = /^[6789]\d{9}$/;
function isValidIndianMobile(m: string): boolean {
  return MOBILE_INDIA_PATTERN.test(m);
}

const VALID_MOBILE_ERROR = 'Please enter a valid mobile number';

function errTxt(e: unknown): string {
  return e instanceof Error ? e.message : String(e);
}

function isLikelyNetworkFailure(msg: string): boolean {
  return /network|fetch|failed to fetch|timeout|502|503|504|econn|aborted/i.test(msg.toLowerCase());
}

const BANNER_MSG_MAX = 280;

/** Prefer server/client error text; only substitute for likely transport failures. */
function bannerFromThrownError(e: unknown, transportFallback: string): string {
  const m = errTxt(e);
  if (isLikelyNetworkFailure(m)) return transportFallback;
  const t = m.trim();
  if (!t) return 'Request failed.';
  return t.length <= BANNER_MSG_MAX ? t : `${t.slice(0, BANNER_MSG_MAX - 1)}…`;
}

function bannerForOtpFailure(e: unknown): string {
  return bannerFromThrownError(e, 'Could not verify OTP. Check your connection and try again.');
}

function bannerForPinFailure(e: unknown): string {
  return bannerFromThrownError(e, 'Could not verify PIN. Check your connection and try again.');
}

function bannerForGenericFailure(e: unknown): string {
  return bannerFromThrownError(e, 'Something went wrong. Check your connection and try again.');
}

function formatPayApiTxnDate(iso: string | undefined | null): string {
  if (!iso?.trim()) return '—';
  const d = Date.parse(iso);
  if (Number.isNaN(d)) return iso.trim();
  return new Date(d).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
}

/** Common Indian VRN grouping for receipt display */
function formatPrettyVrn(vrn: string | undefined | null): string {
  if (!vrn?.trim()) return '—';
  const s = vrn.replace(/\s+/g, '').toUpperCase();
  const m = /^([A-Z]{2})(\d{2})([A-Z]{1,3})(\d{1,4})$/.exec(s);
  if (m) return `${m[1]} ${m[2]} ${m[3]} ${m[4]}`;
  return vrn.trim();
}

/** `--` when missing or not a finite number; otherwise `₹` + en-IN grouped amount. */
function vehicleBalanceDisplay(value: unknown): string {
  if (value == null) return '--';
  const n = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(n)) return '--';
  return `₹${n.toLocaleString('en-IN')}`;
}

function profileRegisteredFromAssignments(assignments: DriverAssignment[]): string {
  const times = assignments
    .map((a) => a.assignedAt)
    .filter((s): s is string => typeof s === 'string' && Boolean(s.trim()))
    .map((s) => Date.parse(s))
    .filter((n) => !Number.isNaN(n));
  if (times.length === 0) return '—';
  return new Date(Math.min(...times)).toLocaleString('en-IN', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function vehicleIdForTransactions(
  home: DriverHome | null,
  assignments: DriverAssignment[],
  activeCardsFiltered: DriverUiBinding[],
  activeIndex: number
): string | null {
  const selected = activeCardsFiltered[activeIndex];
  if (selected?.vehicleId?.trim()) return selected.vehicleId.trim();
  if (home?.vehicleId?.trim()) return home.vehicleId.trim();
  const row =
    assignments.find((a) => a.status === 'ACTIVE' && !a.requiresPairing && a.vehicleId?.trim()) ??
    assignments.find((a) => a.vehicleId?.trim());
  return row?.vehicleId?.trim() ?? null;
}

function istHour(date: Date): number {
  const hourPart = new Intl.DateTimeFormat('en-IN', {
    timeZone: 'Asia/Kolkata',
    hour: 'numeric',
    hour12: false,
  }).formatToParts(date).find((p) => p.type === 'hour');
  const h = hourPart ? parseInt(hourPart.value, 10) : NaN;
  return Number.isFinite(h) ? h : 12;
}

/** IST-based greeting (India does not observe DST). */
function greetingForIndia(date = new Date()): string {
  const h = istHour(date);
  if (h >= 5 && h < 12) return 'Good Morning';
  if (h >= 12 && h < 17) return 'Good Afternoon';
  return 'Good Evening';
}

type OnboardingSubmitKey =
  | null
  | 'login_send_otp'
  | 'login_verify_otp'
  | 'login_resend_otp'
  | 'fo_unlock'
  | 'invite_validate'
  | 'invite_send_otp'
  | 'invite_verify_otp'
  | 'invite_resend_otp'
  | 'invite_set_pin';

export default function Page() {
  // ============ STATE ============
  const [onboardingStep, setOnboardingStep] = useState<
    | 'login'
    | 'login_otp'
    | 'set_pin'
    | 'confirm_pin'
    | 'complete'
    | 'forgot_pin'
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
  const [scanSessionOtpCountdown, setScanSessionOtpCountdown] = useState(0);
  const [pin, setPin] = useState('');
  const [pinConfirm, setPinConfirm] = useState('');
  const [sessionState, setSessionState] = useState<
    'idle' | 'scanning' | 'confirmation' | 'pin_confirm' | 'otp_entry' | 'authorized' | 'complete'
  >('idle');
  const [sessionPin, setSessionPin] = useState('');
  const [sessionOtp, setSessionOtp] = useState('');
  const [lastQrPayResult, setLastQrPayResult] = useState<QrPayResult | null>(null);
  const [pairingCode, setPairingCode] = useState('');
  const [pairingError, setPairingError] = useState('');
  const [activeTab, setActiveTab] = useState<'card' | 'scan' | 'assignments' | 'transactions' | 'profile'>('card');
  const [txnFilter, setTxnFilter] = useState<'all' | 'successful' | 'failed'>('all');
  const [currentMainScreen, setCurrentMainScreen] = useState<'home_empty' | 'home_active' | 'assignment_notification' | 'pairing_code' | 'assignment_accepted'>('home_empty');
  const [activeCard, setActiveCard] = useState(0);
  const [selectedAssignment, setSelectedAssignment] = useState<string | null>(null);
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
  const [newPin, setNewPin] = useState("");
  const [isNewUser, setIsNewUser] = useState(false);
  const [successToast, setSuccessToast] = useState<string | null>(null);
  const [otpDigits, setOtpDigits] = useState(Array(6).fill(''));
  const [activeScanBinding, setActiveScanBinding] = useState<DriverUiBinding | null>(null);
  const [selectedScanBinding, setSelectedScanBinding] = useState<DriverUiBinding | null>(null);
  const [foScopedToken, setFoScopedToken] = useState<string | null>(null);
  const [otpPhaseToken, setOtpPhaseToken] = useState<string | null>(null);
  const [inviteSessionToken, setInviteSessionToken] = useState<string | null>(null);
  const [inviteOtpRefNumber, setInviteOtpRefNumber] = useState<string | null>(null);
  const [inviteMobileVerificationToken, setInviteMobileVerificationToken] = useState<string | null>(null);
  const [validatedInvitePreview, setValidatedInvitePreview] = useState<{
    driverName: string;
    foName: string;
    foCompanyId?: number;
  } | null>(null);
  const [foOrganizationList, setFoOrganizationList] = useState<FoListEntry[]>([]);
  const [selectedFoCompanyId, setSelectedFoCompanyId] = useState<number | null>(null);
  const [apiHome, setApiHome] = useState<DriverHome | null>(null);
  const [apiProfileState, setApiProfileState] = useState<DriverProfile | null>(null);
  const [apiAssignments, setApiAssignments] = useState<DriverAssignment[]>([]);
  const [apiTxns, setApiTxns] = useState<DriverTxnRow[]>([]);
  const [apiBanner, setApiBanner] = useState<string | null>(null);
  const [apiLoading, setApiLoading] = useState(false);
  const [sessionRestored, setSessionRestored] = useState(false);
  const [onboardingActionLoading, setOnboardingActionLoading] = useState<OnboardingSubmitKey>(null);
  const [pairingVerifyLoading, setPairingVerifyLoading] = useState(false);
  const [qrPayVerifyLoading, setQrPayVerifyLoading] = useState(false);
  const [shareReceiptLoading, setShareReceiptLoading] = useState(false);
  const [sessionFoDisplayName, setSessionFoDisplayName] = useState<string | null>(null);
  const [foPinEntry, setFoPinEntry] = useState('');
  const [qrTxnId, setQrTxnId] = useState('');
  const [qrPayFields, setQrPayFields] = useState<FleetpayQrPayload | null>(null);
  const [scanReceiptFromHistory, setScanReceiptFromHistory] = useState(false);
  const [receiptHistoryDriverName, setReceiptHistoryDriverName] = useState<string | null>(null);
  const fuelReceiptCaptureRef = useRef<HTMLDivElement | null>(null);

  const pairingRefs = [
    useRef<HTMLInputElement | null>(null),
    useRef<HTMLInputElement | null>(null),
    useRef<HTMLInputElement | null>(null),
    useRef<HTMLInputElement | null>(null),
    useRef<HTMLInputElement | null>(null),
    useRef<HTMLInputElement | null>(null),
  ];

  // ============ DERIVED STATE ============
  const screenBindings: DriverUiBinding[] =
    onboardingStep === 'complete' && foScopedToken
      ? mapAssignmentsToUiBindings(apiHome, apiAssignments)
      : [];
  const activeCards = screenBindings.filter((b) => b.paired && b.state === 'ACTIVE');
  const currentCard = activeCards[activeCard];
  const pendingAssignmentCount = screenBindings.filter((b) => b.state === 'PENDING_ACCEPTANCE' || (!b.paired && b.state === 'ACTIVE')).length;
  const homeEmptyNoVehicle = activeCards.length === 0;
  const homeEmptyNoTransactions = apiTxns.length === 0;
  const filteredTxnRows = apiTxns.filter((t) => {
    if (txnFilter === 'all') return true;
    if (txnFilter === 'successful') return t.status === 'SUCCESS';
    if (txnFilter === 'failed') return t.status !== 'SUCCESS';
    return true;
  });

  /*
  const openTxnInReceiptView = useCallback(
    (txn: DriverTxnRow) => {
      const vKey = (s: string) => s.replace(/\s+/g, '').toUpperCase();
      const binding = screenBindings.find((b) => vKey(b.vrn) === vKey(txn.vehicleRegNo));
      if (!binding) {
        setApiBanner('Receipt unavailable: vehicle is not in your assignments.');
        return;
      }
      setScanReceiptFromHistory(true);
      setReceiptHistoryDriverName(txn.driverName?.trim() || null);
      setQrPayFields(null);
      setLastQrPayResult({
        serverTxnId: txn.serverTxnId,
        vehicleRegNo: txn.vehicleRegNo,
        amountINR: txn.amountINR,
        newBalanceINR: 0,
        txnTime: txn.createdOn,
        status: txn.status === 'FAILED' ? 'FAILED' : 'SUCCESS',
      });
      setActiveScanBinding(binding);
      setSelectedScanBinding(binding);
      setSessionPin('');
      setSessionState('complete');
      setActiveTab('scan');
    },
    [screenBindings],
  );
  */
  const activeBindings = screenBindings.filter((b) => b.paired && b.state === 'ACTIVE');
  const pendingBindings = screenBindings.filter((b) => b.state === 'PENDING_ACCEPTANCE');
  const repairBindings = screenBindings.filter((b) => !b.paired && b.state === 'ACTIVE');
  const assignmentFallback =
    pendingBindings[0] ?? repairBindings[0] ?? activeBindings[0] ?? screenBindings[0] ?? null;
  const driverDisplayName = apiProfileState?.name?.trim() ? apiProfileState.name : 'Driver';
  const driverDisplayInitials = apiProfileState?.name
    ? driverInitialsFromName(apiProfileState.name)
    : '?';
  const loginInviteOtpResendActive = otpCountdown > 0;
  const scanSessionOtpResendActive = scanSessionOtpCountdown > 0;
  const showMobileFormatError =
    mobileNumber.length > 0 && !/^[6789]/.test(mobileNumber);
  const fleetPinFoName =
    selectedFoCompanyId != null
      ? foOrganizationList.find(
          (f) => f.foCompanyId === selectedFoCompanyId && f.foStatus === 'ACTIVE'
        )?.foName?.trim() ?? ''
      : '';
  const profileRegisteredDisplay = profileRegisteredFromAssignments(apiAssignments);
  const profileFleetOperatorDisplay =
    sessionFoDisplayName?.trim() || apiHome?.foName?.trim() || '—';

  // ============ HANDLERS ============
  const handleInviteCodeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const max = 24;
    const val = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, max);
    setInviteCode(val);
  };

  const handleMobileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value.replace(/\D/g, '').slice(0, 10);
    if (val !== mobileNumber) {
      setInviteOtpRefNumber(null);
      setInviteMobileVerificationToken(null);
      setApiBanner(null);
    }
    setMobileNumber(val);
  };

  const handleOtpChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value.replace(/\D/g, '').slice(0, 6);
    setOtp(val);
  };

  const handlePinInput = (digit: string, isConfirm: boolean = false) => {
    setApiBanner(null);
    if (isConfirm) {
      if (pinConfirm.length < 6) setPinConfirm(pinConfirm + digit);
    } else {
      if (pin.length < 6) setPin(pin + digit);
    }
  };

  const handlePinBackspace = (isConfirm: boolean = false) => {
    setApiBanner(null);
    if (isConfirm) {
      setPinConfirm(pinConfirm.slice(0, -1));
    } else {
      setPin(pin.slice(0, -1));
    }
  };

  const handleSessionPinInput = (digit: string) => {
    setApiBanner(null);
    if (sessionPin.length < 6) setSessionPin(sessionPin + digit);
  };

  const handleSessionPinBackspace = () => {
    setApiBanner(null);
    setSessionPin(sessionPin.slice(0, -1));
  };

  const handleFleetpayScan = useCallback(
    (text: string) => {
      setApiBanner(null);
      const parsed = parseFleetpayPayUri(text);
      console.log(parsed);
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
    setApiBanner(null);
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
    setOnboardingActionLoading('login_verify_otp');
    try {
      setApiBanner(null);
      const tr = await driverOauthOtpGrant(DRIVER_API_BASE, mobileNumber, enteredOtp);
      const partial = oauthAccessToken(tr);
      if (!partial) {
        setApiBanner('Login failed: no token.');
        return;
      }
      setOtpPhaseToken(partial);
      const fos = await driverFoList(DRIVER_API_BASE, partial);
      const active = fos.filter((f) => f.foStatus === 'ACTIVE');
      setFoOrganizationList(active);
      if (!active.length) {
        setApiBanner('No active fleet — use your invite code.');
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
      setApiBanner(bannerForOtpFailure(e));
      setOtpDigits(Array(6).fill(''));
    } finally {
      setOnboardingActionLoading(null);
    }
  };

  const completeOnboarding = () => {
    setActiveTab('card');
    setOnboardingStep('complete');
  };

  const handleLogout = () => {
    if (typeof window !== 'undefined') {
      try {
        localStorage.removeItem(DRIVER_APP_FO_TOKEN_KEY);
        clearFleetOperatorLocalStorage();
      } catch {
        /* ignore */
      }
    }
    setOnboardingStep('login');
    setActiveTab('card');
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
    setSessionFoDisplayName(null);
    setApiHome(null);
    setApiProfileState(null);
    setApiAssignments([]);
    setApiTxns([]);
    setApiBanner(null);
    setFoPinEntry('');
    setInviteOtpRefNumber(null);
    setInviteMobileVerificationToken(null);
    setOtpDigits(Array(6).fill(''));
    setOnboardingActionLoading(null);
    setPairingVerifyLoading(false);
    setQrPayVerifyLoading(false);
    setShareReceiptLoading(false);
    setApiLoading(false);
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
    if (!loginInviteOtpResendActive) return undefined;
    const id = window.setInterval(() => {
      setOtpCountdown((c) => (c <= 1 ? 0 : c - 1));
    }, 1000);
    return () => window.clearInterval(id);
  }, [loginInviteOtpResendActive]);

  useEffect(() => {
    if (!scanSessionOtpResendActive) return undefined;
    const id = window.setInterval(() => {
      setScanSessionOtpCountdown((c) => (c <= 1 ? 0 : c - 1));
    }, 1000);
    return () => window.clearInterval(id);
  }, [scanSessionOtpResendActive]);

  useEffect(() => {
    if (sessionState === 'otp_entry') {
      setScanSessionOtpCountdown(60);
    } else {
      setScanSessionOtpCountdown(0);
    }
  }, [sessionState]);

  useEffect(() => {
    try {
      if (typeof window === 'undefined') return;
      const t = localStorage.getItem(DRIVER_APP_FO_TOKEN_KEY)?.trim();
      if (t) {
        setApiLoading(true);
        setFoScopedToken(t);
        setOnboardingStep('complete');
        try {
          const foName = localStorage.getItem(DRIVER_APP_FO_NAME_KEY)?.trim();
          if (foName) setSessionFoDisplayName(foName);
        } catch {
          /* ignore */
        }
      }
    } catch {
      /* ignore */
    } finally {
      setSessionRestored(true);
    }
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined' || !foScopedToken) return;
    try {
      localStorage.setItem(DRIVER_APP_FO_TOKEN_KEY, foScopedToken);
    } catch {
      /* ignore */
    }
  }, [foScopedToken]);

  useEffect(() => {
    if (otpDigits.join('').length === 6 && onboardingStep === 'login_otp') void handleLoginOtpVerify();
  }, [otpDigits, onboardingStep]);

  useEffect(() => {
    if (!foScopedToken || onboardingStep !== 'complete') return;
    let cancelled = false;
    (async () => {
      setApiLoading(true);
      try {
        setApiBanner(null);
        const [homeRes, profileRes, assignmentsRes, foListRes] = await Promise.allSettled([
          driverGetHome(DRIVER_API_BASE, foScopedToken),
          driverGetProfile(DRIVER_API_BASE, foScopedToken),
          driverGetAssignments(DRIVER_API_BASE, foScopedToken),
          driverFoList(DRIVER_API_BASE, foScopedToken),
        ]);
        if (cancelled) return;

        if (homeRes.status === 'fulfilled') setApiHome(homeRes.value);
        if (profileRes.status === 'fulfilled') setApiProfileState(profileRes.value);
        if (assignmentsRes.status === 'fulfilled') setApiAssignments(assignmentsRes.value);

        if (foListRes.status === 'fulfilled') {
          const active = foListRes.value.filter((f) => f.foStatus === 'ACTIVE');
          let storedId: number | null = null;
          try {
            const raw = localStorage.getItem(DRIVER_APP_FO_COMPANY_ID_KEY);
            if (raw != null) {
              const p = parseInt(raw, 10);
              if (Number.isFinite(p)) storedId = p;
            }
          } catch {
            /* ignore */
          }
          const matched =
            storedId != null ? active.find((f) => f.foCompanyId === storedId) : undefined;
          const chosen = matched ?? active[0];
          const foNm = chosen?.foName?.trim();
          if (foNm) {
            persistFleetOperatorLocalStorage(foNm, chosen?.foCompanyId ?? storedId);
            setSessionFoDisplayName(foNm);
          }
        }

        const failures = [homeRes, profileRes, assignmentsRes].filter(
          (r): r is PromiseRejectedResult => r.status === 'rejected'
        );
        const authFailure = failures.find((r) => {
          const m = r.reason instanceof Error ? r.reason.message : String(r.reason);
          return /\b401\b|Unauthorized|invalid_token|expired/i.test(m);
        });
        if (authFailure) {
          try {
            localStorage.removeItem(DRIVER_APP_FO_TOKEN_KEY);
            clearFleetOperatorLocalStorage();
          } catch {
            /* ignore */
          }
          setFoScopedToken(null);
          setSessionFoDisplayName(null);
          setApiHome(null);
          setApiProfileState(null);
          setApiAssignments([]);
          setApiTxns([]);
          setOnboardingStep('login');
          setActiveTab('card');
          const m = authFailure.reason instanceof Error ? authFailure.reason.message : String(authFailure.reason);
          setApiBanner(m);
        } else if (failures.length > 0) {
          const m = failures[0].reason instanceof Error ? failures[0].reason.message : String(failures[0].reason);
          setApiBanner(m);
        }
      } catch (e) {
        if (cancelled) return;
        const msg = e instanceof Error ? e.message : String(e);
        setApiBanner(msg);
      } finally {
        setApiLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [foScopedToken, onboardingStep]);

  useEffect(() => {
    if (!foScopedToken || onboardingStep !== 'complete') return;
    let cancelled = false;
    (async () => {
      const bindings = mapAssignmentsToUiBindings(apiHome, apiAssignments);
      const cards = bindings.filter((b) => b.paired && b.state === 'ACTIVE');
      const idx = cards.length === 0 ? 0 : Math.min(activeCard, Math.max(0, cards.length - 1));
      const vid = vehicleIdForTransactions(apiHome, apiAssignments, cards, idx);
      if (!vid) {
        if (!cancelled) setApiTxns([]);
        return;
      }
      try {
        const txResult = await driverGetTransactions(DRIVER_API_BASE, foScopedToken, vid, 0);
        if (cancelled) return;
        setApiTxns(txResult.rows);
      } catch (e) {
        if (cancelled) return;
        const m = e instanceof Error ? e.message : String(e);
        if (/\b401\b|Unauthorized|invalid_token|expired/i.test(m)) {
          try {
            localStorage.removeItem(DRIVER_APP_FO_TOKEN_KEY);
            clearFleetOperatorLocalStorage();
          } catch {
            /* ignore */
          }
          setFoScopedToken(null);
          setSessionFoDisplayName(null);
          setApiHome(null);
          setApiProfileState(null);
          setApiAssignments([]);
          setApiTxns([]);
          setOnboardingStep('login');
          setActiveTab('card');
          setApiBanner(m);
        } else {
          setApiBanner(m);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [foScopedToken, onboardingStep, activeCard, apiHome, apiAssignments]);

  useEffect(() => {
    if (!apiBanner) return undefined;
    const id = window.setTimeout(() => setApiBanner(null), 5000);
    return () => window.clearTimeout(id);
  }, [apiBanner]);

  useEffect(() => {
    if (currentMainScreen === "pairing_code") {
      setPairingDigits(["","","","","",""])
      setTimeout(() => {
        pairingRefs[0].current?.focus()
      }, 100)
    }
  }, [currentMainScreen]);

  // ============ RENDER SCREENS ============

  if (!sessionRestored) {
    return (
      <div className="fixed inset-0 z-[500] flex min-h-screen w-full flex-col items-center justify-center bg-gray-100">
        <Loader2 className="h-10 w-10 animate-spin text-green-700" aria-hidden />
        <p className="mt-3 text-sm text-gray-600">Loading…</p>
      </div>
    );
  }

  // Onboarding and PIN Login
  if (onboardingStep !== 'complete') {
    return (
      <div className="relative w-full min-h-screen bg-gray-100 flex flex-col">
          <div className="flex-1 w-full min-h-0 overflow-y-auto flex flex-col justify-center p-6">
            {/* Screen: Login */}
            {onboardingStep === 'login' && (
              <>
                <div className="mx-auto flex w-full max-w-md flex-col gap-6">
                  <div className="flex flex-col items-center space-y-3 text-center">
                    <div className="rounded-lg border border-zinc-600/80 bg-zinc-700 px-2.5 py-2">
                      <img src="/mgl-logo.png" alt="MGL Fleet" className="w-20 object-contain" />
                    </div>
                    <p className="text-xl font-medium text-gray-500">Driver App</p>
                  </div>

                  <div className="rounded-2xl border border-gray-200 bg-white p-6 shadow-[0_1px_3px_rgba(15,23,42,0.08)]">
                    <h2 className="text-lg font-bold leading-tight text-[#1A202C]">Sign in to continue</h2>

                    <div className="mt-6 space-y-2">
                      <label htmlFor="login-mobile" className="block text-sm font-normal text-[#718096]">
                        Mobile number
                      </label>
                      {showMobileFormatError && (
                        <div className="rounded-xl border border-red-200 bg-red-50 px-3 py-2.5 text-sm text-red-900">
                          {VALID_MOBILE_ERROR}
                        </div>
                      )}
                      <div className="flex overflow-hidden rounded-xl border border-gray-200 bg-white focus-within:border-gray-300 focus-within:ring-2 focus-within:ring-green-700/20">
                        <span className="flex shrink-0 items-center border-r border-gray-200 bg-white px-3 py-3 text-sm text-[#718096]">
                          +91
                        </span>
                        <input
                          id="login-mobile"
                          type="tel"
                          value={mobileNumber}
                          onChange={handleMobileChange}
                          placeholder="98765 01234"
                          inputMode="numeric"
                          maxLength={10}
                          autoComplete="tel-national"
                          className="min-w-0 flex-1 border-0 bg-white px-3 py-3 text-sm text-[#1A202C] outline-none placeholder:text-[#94A3B8]"
                        />
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        void (async () => {
                          if (!isValidIndianMobile(mobileNumber)) return;
                          setApiBanner(null);
                          setOtpDigits(Array(6).fill(''));
                          setOnboardingActionLoading('login_send_otp');
                          try {
                            const cm = await driverCheckMobile(DRIVER_API_BASE, mobileNumber);
                            if (cm === 'NEW_USER') {
                              setApiBanner('New user — continue with invite code.');
                              setInviteOtpRefNumber(null);
                              setInviteMobileVerificationToken(null);
                              setOnboardingStep('1c');
                              return;
                            }
                            await driverSendLoginOtp(DRIVER_API_BASE, mobileNumber);
                            setOtpCountdown(60);
                            setOnboardingStep('login_otp');
                          } catch (e) {
                            setApiBanner(bannerForGenericFailure(e));
                          } finally {
                            setOnboardingActionLoading(null);
                          }
                        })();
                      }}
                      disabled={
                        !isValidIndianMobile(mobileNumber) || onboardingActionLoading === 'login_send_otp'
                      }
                      className={`mt-6 w-full rounded-xl py-3.5 text-sm font-semibold transition ${
                        onboardingActionLoading === 'login_send_otp' || isValidIndianMobile(mobileNumber)
                          ? 'bg-[#43a047] text-white hover:bg-[#388e3c]'
                          : 'cursor-not-allowed bg-[#E2E8F0] text-[#94A3B8]'
                      }`}
                    >
                      {onboardingActionLoading === 'login_send_otp' ? (
                        <span className="inline-flex items-center justify-center gap-2 text-white">
                          <Loader2 className="h-5 w-5 shrink-0 animate-spin" aria-hidden />
                          Sending…
                        </span>
                      ) : (
                        'Send OTP'
                      )}
                    </button>

                    <div className="my-6 h-px w-full bg-gray-200" aria-hidden />

                    <button
                      type="button"
                      onClick={() => {
                        setInviteCode('');
                        setOtp('');
                        setApiBanner(null);
                        setInviteOtpRefNumber(null);
                        setInviteMobileVerificationToken(null);
                        setMobileNumber('');
                        setOnboardingStep('1c');
                      }}
                      className="w-full rounded-xl border border-gray-200 bg-white py-3.5 text-sm font-medium text-[#1A202C] transition hover:bg-gray-50"
                    >
                      New user? I have an invite code
                    </button>
                  </div>

                  <p className="text-center text-xs text-gray-400">
                    By continuing, I agree to MGL Fleet Terms of Service
                  </p>
                </div>
              </>
            )}

            {/* Screen: Login OTP */}
            {onboardingStep === 'login_otp' && (
              <>
                <button
                  type="button"
                  onClick={() => {
                    setApiBanner(null);
                    setOnboardingStep('login');
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-6"
                >
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
                        setApiBanner(null);
                        if (newOtpDigits[i] && i < 5) {
                          (document.querySelectorAll('.otp-digit-login')[i + 1] as HTMLInputElement)?.focus();
                        }
                      }}
                      className="otp-digit-login w-10 h-10 text-center text-lg font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-700 focus:ring-2 focus:ring-green-100"
                    />
                  ))}
                </div>

                <button
                  onClick={handleLoginOtpVerify}
                  disabled={
                    otpDigits.join('').length !== 6 ||
                    onboardingActionLoading === 'login_verify_otp' ||
                    onboardingActionLoading === 'login_resend_otp'
                  }
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-xl transition mb-3 inline-flex items-center justify-center gap-2"
                >
                  {onboardingActionLoading === 'login_verify_otp' ? (
                    <>
                      <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                      Verifying…
                    </>
                  ) : (
                    'Verify'
                  )}
                </button>

                {otpCountdown > 0 ? (
                  <p className="text-center text-xs text-gray-500">Resend OTP in {otpCountdown}s</p>
                ) : (
                  <button
                    onClick={() => {
                      void (async () => {
                        setOnboardingActionLoading('login_resend_otp');
                        try {
                          await driverSendLoginOtp(DRIVER_API_BASE, mobileNumber);
                          setOtpCountdown(60);
                          setApiBanner(null);
                        } catch (e) {
                          setApiBanner(bannerForGenericFailure(e));
                        } finally {
                          setOnboardingActionLoading(null);
                        }
                      })();
                    }}
                    disabled={
                      onboardingActionLoading === 'login_resend_otp' ||
                      onboardingActionLoading === 'login_verify_otp'
                    }
                    className="w-full text-green-700 hover:text-green-800 font-medium py-2 text-sm inline-flex items-center justify-center gap-2 disabled:opacity-50"
                  >
                    {onboardingActionLoading === 'login_resend_otp' ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin shrink-0" aria-hidden />
                        Sending…
                      </>
                    ) : (
                      'Resend OTP'
                    )}
                  </button>
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
                <p className="text-sm text-gray-600 mb-1">Enter your PIN for this Fleet Operator</p>
                <p className="mb-6 text-lg font-semibold text-gray-900">{fleetPinFoName || '—'}</p>
                <PinDisplay value={foPinEntry} />
                <Numpad
                  onPress={(digit) => {
                    setApiBanner(null);
                    if (foPinEntry.length < 6) setFoPinEntry(foPinEntry + digit);
                  }}
                  onBackspace={() => {
                    setApiBanner(null);
                    setFoPinEntry(foPinEntry.slice(0, -1));
                  }}
                />
                <button
                  disabled={
                    foPinEntry.length !== 6 ||
                    selectedFoCompanyId === null ||
                    onboardingActionLoading === 'fo_unlock'
                  }
                  onClick={() => {
                    void (async () => {
                      const selId = selectedFoCompanyId;
                      const fos = foOrganizationList;
                      if (selId === null || !otpPhaseToken) return;
                      setOnboardingActionLoading('fo_unlock');
                      try {
                        setApiBanner(null);
                        const tr = await driverFoSelect(
                          DRIVER_API_BASE,
                          otpPhaseToken,
                          selId,
                          foPinEntry
                        );
                        const scoped = oauthAccessToken(tr);
                        if (!scoped) throw new Error('Missing fleet token');
                        setApiLoading(true);
                        setFoScopedToken(scoped);
                        const picked = fos.find((f) => f.foCompanyId === selId && f.foStatus === 'ACTIVE');
                        const foNm = picked?.foName?.trim();
                        if (foNm) {
                          persistFleetOperatorLocalStorage(foNm, selId);
                          setSessionFoDisplayName(foNm);
                        }
                        setOtpPhaseToken(null);
                        setFoPinEntry('');
                        setApiBanner(null);
                        setOnboardingStep('complete');
                        setActiveTab('card');
                      } catch (e) {
                        setApiBanner(bannerForPinFailure(e));
                      } finally {
                        setOnboardingActionLoading(null);
                      }
                    })();
                  }}
                  className="w-full mt-8 bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition inline-flex items-center justify-center gap-2"
                >
                  {onboardingActionLoading === 'fo_unlock' ? (
                    <>
                      <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                      Unlocking…
                    </>
                  ) : (
                    'Unlock app'
                  )}
                </button>
              </>
            )}

            {/* Screen: PIN Login — removed; use mobile OTP from Login */}
            {onboardingStep === 'set_pin' && (
              <>
                <h2 className="text-xl font-bold mb-2">{isNewUser ? 'Create your PIN' : 'Set new PIN'}</h2>
                <p className="text-sm text-gray-600 mb-6">{isNewUser ? "You'll use this every time you sign in" : 'Choose a new 6-digit PIN'}</p>
                <PinDisplay value={newPin} />
                <Numpad onPress={(digit) => { setApiBanner(null); if (newPin.length < 6) setNewPin(newPin + digit); }} onBackspace={() => { setApiBanner(null); setNewPin(newPin.slice(0, -1)); }} />
                <button onClick={() => { setPinConfirm(''); setApiBanner(null); setOnboardingStep('confirm_pin'); }} disabled={newPin.length !== 6} className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6">
                  Next
                </button>
              </>
            )}

            {/* Screen: Confirm PIN */}
            {onboardingStep === 'confirm_pin' && (
              <>
                <button
                  type="button"
                  onClick={() => {
                    setPinConfirm('');
                    setApiBanner(null);
                    setOnboardingStep('set_pin');
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-6"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Confirm your PIN</h2>
                <p className="text-sm text-gray-600 mb-6">Enter the same PIN again</p>
                <PinDisplay value={pinConfirm} />
                <Numpad onPress={(digit) => { setApiBanner(null); if (pinConfirm.length < 6) setPinConfirm(pinConfirm + digit); }} onBackspace={() => { setApiBanner(null); setPinConfirm(pinConfirm.slice(0, -1)); }} isConfirm />
                <button
                  onClick={() => {
                    if (newPin === pinConfirm) {
                      setApiBanner(null);
                      if (isNewUser) {
                        setOnboardingStep('registered');
                      } else {
                        setSuccessToast('PIN updated successfully');
                        setTimeout(() => setSuccessToast(null), 2000);
                        setNewPin('');
                        setPinConfirm('');
                        setIsNewUser(false);
                        setOnboardingStep('login');
                      }
                    } else {
                      setApiBanner("PINs didn't match. Try again.");
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
                    setActiveTab('card');
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
                    setInviteMobileVerificationToken(null);
                    setInviteOtpRefNumber(null);
                    setOtp('');
                    setOnboardingStep('1c');
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-4"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Invite Code</h2>
                <p className="text-sm text-gray-600 mb-6">
                  Enter the code shared by your Fleet Operator
                </p>
                <input
                  type="text"
                  value={inviteCode}
                  onChange={(e) => {
                    handleInviteCodeChange(e);
                    setValidatedInvitePreview(null);
                    setInviteSessionToken(null);
                  }}
                  maxLength={24}
                  placeholder="A3K9M2…"
                  className="w-full px-4 py-3 border border-gray-300 rounded-2xl text-center text-lg tracking-widest font-bold focus:outline-none focus:ring-2 focus:ring-green-700 mb-4"
                />
                {validatedInvitePreview && (
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
                        if (!inviteMobileVerificationToken) {
                          setApiBanner('Complete mobile OTP verification first.');
                          return;
                        }
                        setOnboardingActionLoading('invite_validate');
                        try {
                          const r = await driverInviteValidate(
                            DRIVER_API_BASE,
                            mobileNumber,
                            inviteCode,
                            inviteMobileVerificationToken
                          );
                          setInviteSessionToken(r.sessionToken);
                          setValidatedInvitePreview({
                            driverName: r.driverName,
                            foName: r.foName,
                            foCompanyId: r.foCompanyId,
                          });
                          setApiBanner(null);
                          setOnboardingStep('1e');
                        } finally {
                          setOnboardingActionLoading(null);
                        }
                      } catch (e) {
                        setApiBanner(bannerForGenericFailure(e));
                      }
                    })();
                  }}
                  disabled={inviteCode.length < 6 || onboardingActionLoading === 'invite_validate'}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition inline-flex items-center justify-center gap-2"
                >
                  {onboardingActionLoading === 'invite_validate' ? (
                    <>
                      <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                      Checking…
                    </>
                  ) : (
                    'Continue'
                  )}
                </button>
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
                {showMobileFormatError && (
                  <div className="bg-red-50 border border-red-300 rounded-2xl p-3 mb-4 text-red-900 text-sm">{VALID_MOBILE_ERROR}</div>
                )}
                <div className="flex gap-2 mb-4">
                  <span className="text-lg font-bold text-gray-600 pt-3">+91</span>
                  <input
                    type="tel"
                    value={mobileNumber}
                    onChange={handleMobileChange}
                    placeholder="98765 43210"
                    inputMode="numeric"
                    maxLength={10}
                    className="flex-1 px-4 py-3 border border-gray-300 rounded-2xl focus:outline-none focus:ring-2 focus:ring-green-700"
                  />
                </div>
                <button
                  onClick={() => {
                    void (async () => {
                      if (!isValidIndianMobile(mobileNumber)) return;
                      setApiBanner(null);
                      setOnboardingActionLoading('invite_send_otp');
                      try {
                        const cm = await driverCheckMobile(DRIVER_API_BASE, mobileNumber);
                        if (cm !== 'NEW_USER') {
                          setApiBanner('Use “Send OTP” on the login screen.');
                          return;
                        }
                        const ref = await driverInviteMobileSendOtp(DRIVER_API_BASE, mobileNumber);
                        setInviteOtpRefNumber(ref);
                        setOtp('');
                        setApiBanner(null);
                        setOtpCountdown(60);
                        setOnboardingStep('1d');
                      } catch (e) {
                        setApiBanner(bannerForGenericFailure(e));
                      } finally {
                        setOnboardingActionLoading(null);
                      }
                    })();
                  }}
                  disabled={!isValidIndianMobile(mobileNumber) || onboardingActionLoading === 'invite_send_otp'}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition inline-flex items-center justify-center gap-2"
                >
                  {onboardingActionLoading === 'invite_send_otp' ? (
                    <>
                      <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                      Sending…
                    </>
                  ) : (
                    'Send OTP'
                  )}
                </button>
              </>
            )}

            {onboardingStep === '1d' && (
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
                        setApiBanner(null);
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
                <button
                  onClick={() => {
                    void (async () => {
                      if (!inviteOtpRefNumber || otp.length !== 6) return;
                      setOnboardingActionLoading('invite_verify_otp');
                      try {
                        const tok = await driverInviteMobileVerifyOtp(
                          DRIVER_API_BASE,
                          mobileNumber,
                          inviteOtpRefNumber,
                          otp
                        );
                        setInviteMobileVerificationToken(tok);
                        setApiBanner(null);
                        setOtp('');
                        setOnboardingStep('1b');
                      } catch (e) {
                        setApiBanner(bannerForOtpFailure(e));
                      } finally {
                        setOnboardingActionLoading(null);
                      }
                    })();
                  }}
                  disabled={
                    otp.length !== 6 ||
                    !inviteOtpRefNumber ||
                    onboardingActionLoading === 'invite_verify_otp' ||
                    onboardingActionLoading === 'invite_resend_otp'
                  }
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mb-2 inline-flex items-center justify-center gap-2"
                >
                  {onboardingActionLoading === 'invite_verify_otp' ? (
                    <>
                      <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                      Verifying…
                    </>
                  ) : (
                    'Verify OTP'
                  )}
                </button>
                {otpCountdown > 0 ? (
                  <p className="text-center text-xs text-gray-500">Resend OTP in {otpCountdown}s</p>
                ) : (
                  <button
                    onClick={() => {
                      void (async () => {
                        setOnboardingActionLoading('invite_resend_otp');
                        try {
                          const ref = await driverInviteMobileSendOtp(DRIVER_API_BASE, mobileNumber);
                          setInviteOtpRefNumber(ref);
                          setApiBanner(null);
                          setOtpCountdown(60);
                        } catch (e) {
                          setApiBanner(bannerForGenericFailure(e));
                        } finally {
                          setOnboardingActionLoading(null);
                        }
                      })();
                    }}
                    disabled={
                      onboardingActionLoading === 'invite_resend_otp' ||
                      onboardingActionLoading === 'invite_verify_otp'
                    }
                    className="w-full text-green-700 hover:text-green-800 font-medium py-2 text-sm inline-flex items-center justify-center gap-2 disabled:opacity-50"
                  >
                    {onboardingActionLoading === 'invite_resend_otp' ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin shrink-0" aria-hidden />
                        Sending…
                      </>
                    ) : (
                      'Resend OTP'
                    )}
                  </button>
                )}
              </>
            )}

            {/* Screen 1e: PIN Setup */}
            {onboardingStep === '1e' && (
              <>
                <h2 className="text-xl font-bold mb-2">Create your app PIN</h2>
                <p className="text-sm text-gray-600 mb-6">6 digits for fleet login and fuel authorization</p>
                <PinDisplay value={pin} />
                <Numpad onPress={(digit) => { if (pin.length < 6) handlePinInput(digit, false); }} onBackspace={() => handlePinBackspace(false)} />
                <button
                  onClick={() => setOnboardingStep('1f')}
                  disabled={pin.length !== 6}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6"
                >
                  Next
                </button>
              </>
            )}

            {/* Screen 1f: PIN Confirm */}
            {onboardingStep === '1f' && (
              <>
                <button
                  type="button"
                  onClick={() => {
                    setPinConfirm('');
                    setApiBanner(null);
                    setOnboardingStep('1e');
                  }}
                  className="flex items-center gap-2 text-gray-600 mb-4"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Confirm your PIN</h2>
                <p className="text-sm text-gray-600 mb-6">Enter the same PIN again</p>
                <PinDisplay value={pinConfirm} />
                <Numpad onPress={(digit) => { if (pinConfirm.length < 6) handlePinInput(digit, true); }} onBackspace={() => handlePinBackspace(true)} isConfirm />
                <button
                  onClick={() => {
                    void (async () => {
                      const preview = validatedInvitePreview;
                      if (pin !== pinConfirm) {
                        setApiBanner("PINs don't match. Try again.");
                        setPinConfirm('');
                        return;
                      }
                      setApiBanner(null);
                      if (!inviteSessionToken) {
                        setApiBanner('Session missing — go back to invite step.');
                        return;
                      }
                      setOnboardingActionLoading('invite_set_pin');
                      try {
                        const tr = await driverInviteSetPin(DRIVER_API_BASE, inviteSessionToken, pin);
                        const scoped = oauthAccessToken(tr);
                        if (!scoped) throw new Error('Missing access token');
                        setApiLoading(true);
                        setFoScopedToken(scoped);
                        const inviteFo = preview?.foName?.trim();
                        if (inviteFo) {
                          persistFleetOperatorLocalStorage(inviteFo, preview?.foCompanyId ?? null);
                          setSessionFoDisplayName(inviteFo);
                        }
                        setInviteSessionToken(null);
                        setPin('');
                        setPinConfirm('');
                        setApiBanner(null);
                        setOnboardingStep('complete');
                        setActiveTab('card');
                      } catch (e) {
                        setApiBanner(bannerForPinFailure(e));
                      } finally {
                        setOnboardingActionLoading(null);
                      }
                    })();
                  }}
                  disabled={pinConfirm.length !== 6 || onboardingActionLoading === 'invite_set_pin'}
                  className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition mt-6 inline-flex items-center justify-center gap-2"
                >
                  {onboardingActionLoading === 'invite_set_pin' ? (
                    <>
                      <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                      Saving…
                    </>
                  ) : (
                    'Confirm PIN'
                  )}
                </button>
              </>
            )}

            {/* Screen: Forgot PIN */}
            {onboardingStep === 'forgot_pin' && (
              <>
                <button
                  type="button"
                  onClick={() => setOnboardingStep('login')}
                  className="flex items-center gap-2 text-gray-600 mb-4"
                >
                  <ChevronLeft className="w-5 h-5" /> Back
                </button>
                <h2 className="text-xl font-bold mb-2">Reset PIN</h2>
                <p className="text-sm text-gray-600 mb-6">
                  Sign out and open Login with your mobile OTP, or contact your fleet operator for help.
                </p>
                <button
                  type="button"
                  onClick={() => setOnboardingStep('login')}
                  className="w-full bg-green-700 hover:bg-green-800 text-white font-medium py-3 rounded-2xl transition"
                >
                  Back to login
                </button>
              </>
            )}
          </div>
          {apiBanner && (
            <div
              role="alert"
              className="pointer-events-auto fixed left-3 right-3 z-[90] flex max-h-[min(40vh,220px)] items-start gap-2 overflow-y-auto rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-xs text-amber-950 shadow-lg bottom-[max(12px,env(safe-area-inset-bottom,0px))]"
            >
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-amber-700" aria-hidden />
              <span className="min-w-0 flex-1 leading-snug">{apiBanner}</span>
              <button
                type="button"
                onClick={() => setApiBanner(null)}
                className="shrink-0 font-semibold text-amber-900"
              >
                Dismiss
              </button>
            </div>
          )}
      </div>
    );
  }

  return (
    <div className="relative flex min-h-screen w-full flex-col bg-gray-100">
        {foScopedToken && apiLoading && (
          <div className="pointer-events-auto fixed inset-0 z-[500] flex flex-col items-center justify-center bg-gray-100 gap-3">
            <Loader2 className="h-10 w-10 animate-spin text-green-700" aria-hidden />
            <p className="text-sm text-gray-600">Loading…</p>
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
                    if (!assignment) {
                      return <p className="text-center text-sm text-gray-600 py-8">No assignment selected.</p>;
                    }

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
                    if (!assignment) {
                      return <p className="text-center text-sm text-gray-600 py-8">No assignment selected.</p>;
                    }

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
                                if (!foScopedToken) {
                                  setPairingError('Sign in required.');
                                  return;
                                }
                                setPairingVerifyLoading(true);
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
                                } finally {
                                  setPairingVerifyLoading(false);
                                }
                              })();
                            }}
                            disabled={pairingDigits.some((d) => d === '') || pairingVerifyLoading}
                            className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition inline-flex items-center justify-center gap-2"
                          >
                            {pairingVerifyLoading ? (
                              <>
                                <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                                Verifying…
                              </>
                            ) : (
                              'Verify & Activate'
                            )}
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
                if (!assignment) {
                  return <p className="text-center text-sm text-gray-600">No assignment.</p>;
                }

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
                      Go to My Vehicles
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
                    <p className="text-[#c8e6c9] text-sm font-normal">{greetingForIndia()}</p>
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
            className={`flex-1 overflow-y-auto pb-[calc(5.5rem+env(safe-area-inset-bottom,0px))] ${
              activeTab === 'card' || activeTab === 'assignments'
                ? 'bg-[#eceff1]'
                : 'bg-white'
            }`}
          >
            {/* Card Tab */}
            {activeTab === 'card' && (
              currentCard ? (
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
                        <p className="text-sm text-gray-600 leading-snug pr-2 min-w-0 flex-1">
                          {(sessionFoDisplayName?.trim() || currentCard.fo?.trim()) || '—'}
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
                          {vehicleBalanceDisplay(activeCards[activeCard]?.balance)}
                        </p>
                        {(activeCards[activeCard]?.incentiveBalance ?? 0) > 0 && (
                          <p className="text-xs text-gray-500 mt-2">
                            Card {vehicleBalanceDisplay(activeCards[activeCard]?.cardBalance)} · Incentive{' '}
                            {vehicleBalanceDisplay(activeCards[activeCard]?.incentiveBalance)}
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
                  {!homeEmptyNoTransactions ? (
                    <button type="button" onClick={() => setActiveTab('transactions')} className="text-sm text-[#2e7d32] font-semibold">
                      View all
                    </button>
                  ) : null}
                </div>
                <div className="pb-2 space-y-3">
                    {homeEmptyNoTransactions ? (
                      <div className="rounded-xl border border-gray-100 bg-white px-3.5 py-10 text-center shadow-[0_2px_12px_rgba(0,0,0,0.05)]">
                        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-gray-50">
                          <History className="h-7 w-7 text-gray-400" aria-hidden />
                        </div>
                        <p className="text-sm font-medium text-gray-800">No transactions yet</p>
                        <p className="mt-1 text-xs text-gray-500 max-w-[260px] mx-auto leading-relaxed">
                          Fuel payments and wallet activity will show here once you use Scan & Pay.
                        </p>
                      </div>
                    ) : (
                      apiTxns.slice(0, 3).map((txn) => {
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
                    )}
                </div>
              </div>
              ) : (
              <div className="p-4 space-y-4">
                {pendingAssignmentCount > 0 && (
                  <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <AlertCircle className="w-5 h-5 text-amber-600 flex-shrink-0" />
                      <div>
                        <p className="text-sm font-medium text-amber-900">{pendingAssignmentCount} assignment{pendingAssignmentCount > 1 ? 's' : ''} need your attention</p>
                      </div>
                    </div>
                    <button type="button" onClick={() => setActiveTab('assignments')} className="text-sm font-medium text-green-700 hover:text-green-800">View</button>
                  </div>
                )}

                {homeEmptyNoVehicle && homeEmptyNoTransactions ? (
                  <div className="rounded-[14px] border border-gray-200 bg-white px-6 py-14 text-center shadow-[0_2px_12px_rgba(0,0,0,0.04)]">
                    <div className="mx-auto mb-5 flex h-[72px] w-[72px] items-center justify-center rounded-full bg-[#f1f4f2]">
                      <Truck className="h-9 w-9 text-[#7d9188]" aria-hidden />
                    </div>
                    <p className="text-lg font-semibold text-gray-900">No vehicles or transactions</p>
                    <p className="mt-2 text-sm text-gray-500 leading-relaxed max-w-sm mx-auto">
                      There&apos;s nothing to show yet. When your fleet operator assigns you a vehicle and you use Scan & Pay, your balance and activity will appear here.
                    </p>
                    {pendingAssignmentCount > 0 ? (
                      <button
                        type="button"
                        onClick={() => setActiveTab('assignments')}
                        className="mt-8 w-full max-w-xs mx-auto bg-[#43a047] hover:bg-[#388e3c] text-white font-semibold py-3 rounded-2xl text-[15px] transition-colors shadow-sm"
                      >
                        Go to vehicles
                      </button>
                    ) : (
                      <button
                        type="button"
                        onClick={() => setActiveTab('assignments')}
                        className="mt-8 text-sm font-semibold text-[#2e7d32] hover:text-[#1b5e20]"
                      >
                        Browse vehicles
                      </button>
                    )}
                  </div>
                ) : (
                  <>
                    <div className="rounded-[14px] border border-gray-200 bg-white px-6 py-12 text-center shadow-[0_2px_12px_rgba(0,0,0,0.04)]">
                      <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[#f1f4f2]">
                        <Truck className="h-7 w-7 text-[#7d9188]" aria-hidden />
                      </div>
                      <p className="text-base font-semibold text-gray-900">No active vehicle</p>
                      <p className="mt-2 text-sm text-gray-500 max-w-sm mx-auto leading-relaxed">
                        You don&apos;t have a paired vehicle right now. Accept an assignment to unlock Scan & Pay.
                      </p>
                      {pendingAssignmentCount > 0 ? (
                        <button
                          type="button"
                          onClick={() => setActiveTab('assignments')}
                          className="mt-6 w-full max-w-xs mx-auto bg-[#43a047] hover:bg-[#388e3c] text-white font-semibold py-3 rounded-2xl text-[15px] transition-colors shadow-sm"
                        >
                          View vehicles
                        </button>
                      ) : null}
                    </div>

                    <div className="flex justify-between items-center pt-2 pb-2">
                      <p className="font-semibold text-base text-gray-900">Recent</p>
                      {apiTxns.length > 0 ? (
                        <button type="button" onClick={() => setActiveTab('transactions')} className="text-sm text-[#2e7d32] font-semibold">
                          View all
                        </button>
                      ) : null}
                    </div>
                    <div className="pb-2 space-y-3">
                      {apiTxns.slice(0, 3).map((txn) => {
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
                      })}
                    </div>
                  </>
                )}
              </div>
              )
            )}

            {/* Scan & Pay Tab */}
            {activeTab === 'scan' && (
              <div className="p-4 space-y-4 pb-[calc(5.5rem+env(safe-area-inset-bottom,0px))]">
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
                          Go to My Vehicles
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
                          <div className="flex justify-between text-sm pt-1">
                            <span className="text-gray-600">Available balance</span>
                            <span className="font-semibold text-green-700 tabular-nums">
                              {vehicleBalanceDisplay(selectedScanBinding.balance)}
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
                      <p className="text-center text-xs text-gray-600 leading-relaxed px-2">
                        Point camera at the QR on the POS screen
                      </p>

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
                        <span className="font-medium text-green-700">
                          {vehicleBalanceDisplay(activeScanBinding.balance)}
                        </span>
                      </div>
                      {/* <div className="flex justify-between text-sm border-t border-gray-200 pt-2">
                        <span className="text-gray-600">Spend limit</span>
                        <span className="font-medium text-gray-900">₹{activeScanBinding.spendLimit?.toLocaleString('en-IN') || '5,000'}</span>
                      </div> */}
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
                          if (!foScopedToken || !activeScanBinding || !qrPayFields) return;
                          if (sessionPin.length !== 6) return;
                          setQrPayVerifyLoading(true);
                          try {
                            setApiBanner(null);
                            const payRes = await driverQrPay(DRIVER_API_BASE, foScopedToken, {
                              txnId: qrPayFields.txnId,
                              vehicleRegNo: activeScanBinding.vrn.replace(/\s+/g, ''),
                              pin: sessionPin,
                              mid: qrPayFields.mid,
                              terminalId: qrPayFields.terminalId,
                              amountPaise: qrPayFields.amountPaise,
                              expiryEpoch: qrPayFields.expiryEpoch,
                              sign: qrPayFields.sign,
                            });
                            setScanReceiptFromHistory(false);
                            setReceiptHistoryDriverName(null);
                            setLastQrPayResult(payRes);
                            setSessionPin('');
                            setSessionState('complete');
                            const payVid = activeScanBinding.vehicleId?.trim();
                            if (!payVid) {
                              const homeOnly = await driverGetHome(DRIVER_API_BASE, foScopedToken);
                              setApiHome(homeOnly);
                              setApiBanner('Could not refresh transactions (missing vehicle id).');
                              return;
                            }
                            const [home, txResult] = await Promise.all([
                              driverGetHome(DRIVER_API_BASE, foScopedToken),
                              driverGetTransactions(DRIVER_API_BASE, foScopedToken, payVid, 0),
                            ]);
                            setApiHome(home);
                            setApiTxns(txResult.rows);
                          } catch (e) {
                            setApiBanner(bannerForPinFailure(e));
                          } finally {
                            setQrPayVerifyLoading(false);
                          }
                        })();
                      }}
                      disabled={sessionPin.length !== 6 || !qrPayFields || qrPayVerifyLoading}
                      className="w-full bg-green-700 hover:bg-green-800 disabled:bg-gray-300 text-white font-medium py-3 rounded-2xl transition inline-flex items-center justify-center gap-2"
                    >
                      {qrPayVerifyLoading ? (
                        <>
                          <Loader2 className="h-5 w-5 animate-spin shrink-0" aria-hidden />
                          Processing…
                        </>
                      ) : (
                        'Verify PIN'
                      )}
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

                    {scanSessionOtpCountdown > 0 ? (
                      <p className="text-center text-xs text-gray-500">Resend OTP in {scanSessionOtpCountdown}s</p>
                    ) : (
                      <button
                        type="button"
                        onClick={() => setScanSessionOtpCountdown(60)}
                        className="w-full text-green-700 font-medium py-2 text-sm"
                      >
                        Resend OTP
                      </button>
                    )}
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

                    <button onClick={() => { setScanReceiptFromHistory(false); setReceiptHistoryDriverName(null); setSessionState('complete'); }} className="w-full bg-green-700 text-white font-medium py-3 rounded-2xl">
                      Fueling Complete
                    </button>
                  </>
                )}

                {sessionState === 'complete' && activeScanBinding && (() => {
                  const payFailed = lastQrPayResult?.status === 'FAILED';
                  const amtPaiseFallback = qrPayFields?.amountPaise;
                  const amountInrNum =
                    lastQrPayResult != null &&
                    typeof lastQrPayResult.amountINR === 'number' &&
                    Number.isFinite(lastQrPayResult.amountINR)
                      ? lastQrPayResult.amountINR
                      : amtPaiseFallback != null
                        ? amtPaiseFallback / 100
                        : NaN;
                  const amountDisplay = Number.isFinite(amountInrNum)
                    ? `₹${amountInrNum.toLocaleString('en-IN', {
                        minimumFractionDigits: 0,
                        maximumFractionDigits: 2,
                      })}`
                    : '—';
                  const vrnPretty = formatPrettyVrn(lastQrPayResult?.vehicleRegNo ?? activeScanBinding.vrn);
                  const stationName = qrPayFields?.merchantName ?? '—';
                  const txnIdDisp = lastQrPayResult?.serverTxnId ?? '—';
                  const txnDateDisp = formatPayApiTxnDate(lastQrPayResult?.txnTime);
                  const newBalDisp =
                    !scanReceiptFromHistory &&
                    lastQrPayResult != null &&
                    typeof lastQrPayResult.newBalanceINR === 'number' &&
                    Number.isFinite(lastQrPayResult.newBalanceINR)
                      ? `₹${lastQrPayResult.newBalanceINR.toLocaleString('en-IN')}`
                      : null;
                  const hdrBar = payFailed ? 'bg-red-950' : 'bg-emerald-950';

                  const receiptShareText = (): string => {
                    const headline = payFailed ? 'Transaction failed' : 'Fueling complete';
                    let t = `${headline}\nStation: ${stationName}\nVehicle: ${vrnPretty}`;
                    if (receiptHistoryDriverName) t += `\nDriver: ${receiptHistoryDriverName}`;
                    t += `\nAmount: ${amountDisplay}`;
                    if (!payFailed && newBalDisp) t += `\nNew balance: ${newBalDisp}`;
                    if (lastQrPayResult?.authCode?.trim())
                      t += `\nAuth code: ${lastQrPayResult.authCode}`;
                    t += `\nTXN ID: ${txnIdDisp}\nTransaction date: ${txnDateDisp}`;
                    if (payFailed) t += `\nStatus: FAILED`;
                    return t;
                  };

                  const receiptRow = (label: string, value: string, opts?: { valueClass?: string }) => (
                    <div className="flex justify-between gap-3 py-3 text-sm border-b border-gray-100">
                      <span className="shrink-0 text-gray-500">{label}</span>
                      <span
                        className={`min-w-0 text-right font-bold text-gray-900 ${opts?.valueClass ?? ''}`}
                      >
                        {value}
                      </span>
                    </div>
                  );

                  return (
                  <div className="-mx-4 space-y-4 px-4 py-4">
                    <div
                      ref={fuelReceiptCaptureRef}
                      className="overflow-hidden rounded-2xl bg-white shadow-[0_8px_30px_rgba(0,0,0,0.08)]"
                    >
                      <div className="border-b border-gray-100 bg-white px-6 pb-6 pt-8 text-center">
                        {payFailed ? (
                          <>
                            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-red-600">
                              <XCircle className="h-9 w-9 text-white" strokeWidth={2.5} aria-hidden />
                            </div>
                            <h2 className="text-xl font-bold text-red-700">Transaction Failed</h2>
                          </>
                        ) : (
                          <>
                            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-[#2e7d32]">
                              <Check className="h-9 w-9 text-white" strokeWidth={3} aria-hidden />
                            </div>
                            <h2 className="text-xl font-bold text-[#2e7d32]">Fueling Complete</h2>
                          </>
                        )}
                      </div>
                      <div className={`flex flex-col items-center gap-2 px-4 py-5 ${hdrBar}`}>
                        <div className="rounded-lg border border-zinc-600/80 bg-zinc-700 px-2.5 py-2">
                          <img
                            src="/mgl-logo.png"
                            alt="MGL"
                            className="mx-auto block h-9 w-auto max-w-[120px] object-contain"
                          />
                        </div>
                        <p className="text-center text-xs font-normal text-white/90">Official Receipt</p>
                      </div>
                      <div className="px-4 pb-5 pt-0">
                        {receiptRow('Station', stationName)}
                        {receiptRow('Vehicle', vrnPretty)}
                        {receiptHistoryDriverName ? receiptRow('Driver', receiptHistoryDriverName) : null}
                        {payFailed
                          ? receiptRow('Status', 'FAILED', { valueClass: 'text-red-600' })
                          : null}
                        {receiptRow('Amount', amountDisplay)}
                        {!payFailed && newBalDisp
                          ? receiptRow('New balance', newBalDisp, { valueClass: 'text-[#2e7d32]' })
                          : null}
                        {lastQrPayResult?.authCode?.trim()
                          ? receiptRow('Auth code', lastQrPayResult.authCode.trim(), {
                              valueClass: 'font-mono text-xs font-semibold tracking-wide',
                            })
                          : null}
                        <div className="mt-4 border-t border-dashed border-gray-300 px-1 pb-1 pt-4 text-center">
                          <p className="break-all font-mono text-[11px] tracking-tight text-gray-500">
                            {txnIdDisp === '—' ? 'TXN ID: —' : `TXN ID: ${txnIdDisp}`}
                          </p>
                          <p className="mt-1 font-mono text-[11px] text-gray-500">{txnDateDisp}</p>
                        </div>
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        setScanReceiptFromHistory(false);
                        setReceiptHistoryDriverName(null);
                        setSessionState('idle');
                        setActiveTab('card');
                        setActiveScanBinding(null);
                        setQrPayFields(null);
                        setLastQrPayResult(null);
                      }}
                      className={`w-full rounded-xl py-3.5 font-semibold text-white ${
                        payFailed ? 'bg-gray-700 hover:bg-gray-800' : 'bg-[#2e7d32] hover:bg-[#27692a]'
                      }`}
                    >
                      Done
                    </button>

                    <button
                      type="button"
                      onClick={() => {
                        void (async () => {
                          setShareReceiptLoading(true);
                          try {
                            await new Promise<void>((resolve) =>
                              requestAnimationFrame(() => requestAnimationFrame(() => resolve()))
                            );

                            const el = fuelReceiptCaptureRef.current;
                            if (!el) {
                              setApiBanner('Receipt not ready to share.');
                              return;
                            }

                            const { toBlob } = await import('html-to-image');
                            const blob = await toBlob(el, {
                              cacheBust: true,
                              backgroundColor: '#ffffff',
                              pixelRatio: Math.min(3, typeof window !== 'undefined' ? window.devicePixelRatio || 2 : 2),
                            });

                            if (!blob) {
                              setApiBanner('Could not create receipt image.');
                              return;
                            }

                            const file = new File([blob], 'mgl-fueling-receipt.png', { type: 'image/png' });
                            const title = payFailed ? 'MGL — Transaction failed' : 'MGL — Fueling complete';

                            const tryShareFiles = async (payload: ShareData) => {
                              if (typeof navigator === 'undefined' || typeof navigator.share !== 'function')
                                return false;
                              if (!navigator.canShare?.(payload)) return false;
                              await navigator.share(payload);
                              return true;
                            };

                            try {
                              if (await tryShareFiles({ title, files: [file] })) return;

                              try {
                                if (
                                  navigator.canShare?.({ files: [file], text: title }) &&
                                  (await tryShareFiles({ files: [file], text: title }))
                                )
                                  return;
                              } catch {
                                /* try next */
                              }

                              try {
                                if (await tryShareFiles({ title, files: [file], text: receiptShareText() })) return;
                              } catch {
                                /* try download */
                              }
                            } catch (e: unknown) {
                              if (
                                e &&
                                typeof e === 'object' &&
                                'name' in e &&
                                (e as { name: string }).name === 'AbortError'
                              )
                                return;
                            }

                            try {
                              if (
                                typeof navigator.clipboard?.write !== 'undefined' &&
                                typeof ClipboardItem !== 'undefined'
                              ) {
                                await navigator.clipboard.write([
                                  new ClipboardItem({ [blob.type]: blob }),
                                ]);
                                setSuccessToast('Receipt image copied');
                                setTimeout(() => setSuccessToast(null), 2500);
                                return;
                              }
                            } catch {
                              /* fallback download */
                            }

                            try {
                              const url = URL.createObjectURL(blob);
                              const a = document.createElement('a');
                              a.href = url;
                              a.download = 'mgl-fueling-receipt.png';
                              document.body.appendChild(a);
                              a.click();
                              a.remove();
                              URL.revokeObjectURL(url);
                              setSuccessToast('Receipt saved to your device');
                              setTimeout(() => setSuccessToast(null), 2500);
                            } catch {
                              setApiBanner('Could not share or save receipt image');
                            }
                          } finally {
                            setShareReceiptLoading(false);
                          }
                        })();
                      }}
                      disabled={shareReceiptLoading}
                      className="flex w-full items-center justify-center gap-2 rounded-xl border border-gray-200 bg-white py-3.5 font-medium text-gray-900 disabled:opacity-60"
                    >
                      {shareReceiptLoading ? (
                        <Loader2 className="h-5 w-5 shrink-0 animate-spin" aria-hidden />
                      ) : (
                        <Share className="h-5 w-5" aria-hidden />
                      )}
                      {shareReceiptLoading ? 'Sharing…' : 'Share receipt'}
                    </button>
                  </div>
                  );
                })()}
              </div>
            )}

            {/* Assignments tab */}
            {activeTab === 'assignments' && (
              <div className="space-y-4 bg-[#eceff1] p-4 pb-6 font-sans min-h-0">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900">My Vehicles</h2>
                  <p className="mt-1 text-xs text-gray-600">
                    {activeBindings.length} active · {pendingBindings.length + repairBindings.length} need attention
                  </p>
                </div>

                {activeBindings.length > 0 && (
                  <div className="space-y-4">
                    {activeBindings.map((binding) => {
                      const scanDisabled =
                        binding.scanPayStatus === 'out_window' ||
                        binding.scanPayStatus === 'locked_unpaired' ||
                        binding.scanPayStatus === 'locked_repair';
                      const openDetails = () => {
                        if (binding.authMode === 'trip_linked') {
                          setShowTripDetails(true);
                          setSelectedTripBinding(binding);
                        } else if (binding.authMode === 'shift_based') {
                          setShowShiftSchedule(true);
                          setSelectedShiftBinding(binding);
                        } else {
                          setAssignmentDetailBinding(binding);
                        }
                      };
                      return (
                        <div
                          key={binding.id}
                          className="overflow-hidden rounded-xl bg-white shadow-[0_2px_12px_rgba(0,0,0,0.06)]"
                        >
                          <div className="h-2 bg-[#43a047]" aria-hidden />
                          <div className="px-5 pt-4">
                            <div className="flex items-start justify-between gap-3">
                              <p className="font-mono text-xl font-bold leading-tight tracking-wide text-gray-900">
                                {binding.vrn}
                              </p>
                              <span className="shrink-0 rounded-full border border-[#43a047] bg-green-50 px-3 py-0.5 text-xs font-semibold text-green-700">
                                Active
                              </span>
                            </div>
                            <p className="mt-2 text-sm text-gray-600">{binding.fo?.trim() || '—'}</p>
                            <div className="mt-5 flex items-baseline justify-between">
                              <span className="text-sm text-gray-600">Balance</span>
                              <span className="text-xl font-bold tabular-nums text-gray-900">
                                {vehicleBalanceDisplay(binding.balance ?? binding.cardBalance)}
                              </span>
                            </div>
                          </div>
                          <div className="mx-5 my-3 border-t border-gray-200" />
                          <div className="grid grid-cols-3 gap-2 px-4 pb-4">
                            <button
                              type="button"
                              disabled={scanDisabled}
                              onClick={() => {
                                setSelectedScanBinding(binding);
                                setSessionState('scanning');
                                setActiveTab('scan');
                              }}
                              className="flex flex-col items-center justify-center gap-1.5 rounded-lg border border-green-200 bg-green-50 px-1 py-3 text-xs font-medium text-[#2e7d32] transition hover:bg-green-100 disabled:cursor-not-allowed disabled:opacity-40"
                            >
                              <QrCode className="h-6 w-6 shrink-0 text-[#43a047]" aria-hidden />
                              Scan & Pay
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                const i = activeCards.findIndex((c) => c.id === binding.id);
                                if (i >= 0) setActiveCard(i);
                                setActiveTab('transactions');
                              }}
                              className="flex flex-col items-center justify-center gap-1.5 rounded-lg border border-gray-200 bg-white px-1 py-3 text-xs font-medium text-gray-600 transition hover:bg-gray-50"
                            >
                              <FileText className="h-6 w-6 shrink-0 text-gray-500" aria-hidden />
                              Transactions
                            </button>
                            <button
                              type="button"
                              onClick={openDetails}
                              className="flex flex-col items-center justify-center gap-1.5 rounded-lg border border-gray-200 bg-white px-1 py-3 text-xs font-medium text-gray-600 transition hover:bg-gray-50"
                            >
                              <Info className="h-6 w-6 shrink-0 text-gray-500" aria-hidden />
                              Details
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                {(pendingBindings.length > 0 || repairBindings.length > 0) && (
                  <div className="space-y-3">
                    <h3 className="text-xs uppercase font-semibold text-amber-600 tracking-wide">Needs attention</h3>
                    
                    {/* Pending Acceptance */}
                    {pendingBindings.map((binding) => (
                      <div key={binding.id} className="border-2 border-dashed border-amber-300 bg-white rounded-xl p-4 space-y-3">
                        <div className="flex justify-between items-start">
                          <p className="font-mono text-xl font-bold leading-tight tracking-wide text-gray-900">{binding.vrn}</p>
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
                          <p className="font-mono text-xl font-bold leading-tight tracking-wide text-gray-900">{binding.vrn}</p>
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

                {activeBindings.length === 0 && pendingBindings.length === 0 && repairBindings.length === 0 && (
                  <div className="rounded-xl bg-white py-14 text-center shadow-[0_2px_12px_rgba(0,0,0,0.05)]">
                    <Truck className="mx-auto mb-4 h-12 w-12 text-gray-300" aria-hidden />
                    <p className="mb-1 font-medium text-gray-600">No vehicles yet</p>
                    <p className="text-sm text-gray-500">Your Fleet Operator will assign vehicles here</p>
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
                  {filteredTxnRows.length === 0 ? (
                    <div className="rounded-xl border border-gray-100 bg-white px-4 py-14 text-center shadow-[0_2px_12px_rgba(0,0,0,0.05)]">
                      <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-gray-50">
                        <History className="h-7 w-7 text-gray-400" aria-hidden />
                      </div>
                      <p className="text-sm font-semibold text-gray-900">
                        {apiTxns.length === 0
                          ? 'No transactions yet'
                          : txnFilter === 'successful'
                            ? 'No successful transactions'
                            : txnFilter === 'failed'
                              ? 'No failed transactions'
                              : 'No transactions'}
                      </p>
                      <p className="mx-auto mt-2 max-w-sm text-xs text-gray-500 leading-relaxed">
                        {apiTxns.length === 0
                          ? 'Fuel payments and wallet activity will show here once you use Scan & Pay.'
                          : 'Nothing matches this filter. Try All or another tab.'}
                      </p>
                    </div>
                  ) : (
                    filteredTxnRows.map((txn) => (
                      <div key={txn.serverTxnId} className="bg-white border border-gray-200 rounded-xl p-3">
                        <div className="flex justify-between items-start mb-1">
                          <div>
                            <p className="text-sm font-medium text-gray-900">{txn.serverTxnId}</p>
                            <p className="text-xs text-gray-600">
                              {txn.vehicleRegNo}
                              {txn.driverName ? ` · ${txn.driverName}` : ''}
                            </p>
                          </div>
                          <p className="text-sm font-bold text-red-600">₹{txn.amountINR}</p>
                        </div>
                        <div className="flex flex-wrap items-center gap-2">
                          <span
                            className={`inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ${
                              txn.status === 'SUCCESS'
                                ? 'bg-green-50 text-green-800'
                                : 'bg-amber-50 text-amber-800'
                            }`}
                          >
                            {txn.status}
                          </span>
                          <p className="text-xs text-gray-600">{txn.createdOn}</p>
                        </div>
                      </div>
                    ))
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
                    {apiProfileState ? `Driver · FO ${apiProfileState.foStatus ?? ''}` : 'Driver'}
                  </p>
                </div>

                <div className="space-y-4">
                  <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
                    <h3 className="px-4 py-3 font-semibold text-gray-900 border-b border-gray-200">Account</h3>
                    <div className="divide-y divide-gray-200">
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">Mobile</span>
                        <span className="font-medium">
                          {apiProfileState?.maskedMobile ?? '—'}
                        </span>
                      </div>
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">Registered</span>
                        <span className="font-medium text-right">{profileRegisteredDisplay}</span>
                      </div>
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">Fleet Operator</span>
                        <span className="font-medium text-right min-w-0 max-w-[60%] break-words">
                          {profileFleetOperatorDisplay}
                        </span>
                      </div>
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">Driver ID</span>
                        <span className="font-medium">
                          {apiProfileState?.driverId ?? '—'}
                        </span>
                      </div>
                      <div className="px-4 py-3 flex justify-between text-sm">
                        <span className="text-gray-600">Licence Number</span>
                        <span className="font-medium">
                          {apiProfileState?.dlNumber ?? '—'}
                        </span>
                      </div>
                    </div>
                  </div>

                  {apiAssignments.length > 0 ? (
                  <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
                    <h3 className="px-4 py-3 font-semibold text-gray-900 border-b border-gray-200">My Vehicles</h3>
                    {apiAssignments.map((a) => (
                          <div key={a.vehicleDriverId} className="px-4 py-3 border-b border-gray-200 last:border-0">
                            <p className="font-medium text-gray-900 text-sm">{a.vehicleRegNo}</p>
                            {/* <p className="text-xs text-gray-600 mt-1">{a.assignmentType}</p> */}
                            <div className="flex gap-2 items-center mt-2">
                              <span className="px-2 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium">{a.status}</span>
                              <span className="w-2 h-2 bg-green-600 rounded-full" />
                            </div>
                          </div>
                        ))}
                  </div>
                  ) : null}

                  <button onClick={handleLogout} className="w-full border-2 border-red-300 text-red-600 font-medium py-3 rounded-2xl hover:bg-red-50 transition">
                    Sign out
                  </button>
                </div>
              </div>
            )}
          </div>

          </>
          )}

          {/* Bottom Navigation */}
          <div className="pointer-events-auto fixed bottom-0 left-0 right-0 z-[70] border-t border-gray-200 bg-white shadow-[0_-4px_24px_rgba(0,0,0,0.08)]">
            <div className="mx-auto flex max-w-lg items-end justify-around gap-1 px-2 pt-2 pb-[max(0.5rem,env(safe-area-inset-bottom,0px))] min-h-[4.25rem]">
            {[{ id: 'card', icon: Home, label: 'Home' }, { id: 'scan', icon: QrCode, label: 'Scan & Pay' }, { id: 'assignments', icon: Truck, label: 'My Vehicles' }, { id: 'profile', icon: User, label: 'Profile' }].map((tab) => (
              <button key={tab.id} type="button" onClick={() => setActiveTab(tab.id as typeof activeTab)} className={`flex min-h-[3.25rem] flex-1 flex-col items-center justify-end gap-1 py-1 transition ${activeTab === tab.id ? 'text-green-700' : 'text-gray-500'}`}>
                <tab.icon className="h-6 w-6 shrink-0" />
                <span className="max-w-[5.5rem] text-center text-xs font-medium leading-tight">{tab.label}</span>
              </button>
            ))}
            </div>
          </div>
        </div>

        {apiBanner && (
          <div
            role="alert"
            className="pointer-events-auto fixed left-3 right-3 z-[90] flex max-h-[min(40vh,220px)] items-start gap-2 overflow-y-auto rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-xs text-amber-950 shadow-lg bottom-[calc(5.5rem+env(safe-area-inset-bottom,0px)+10px)]"
          >
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-amber-700" aria-hidden />
            <span className="min-w-0 flex-1 leading-snug">{apiBanner}</span>
            <button
              type="button"
              onClick={() => setApiBanner(null)}
              className="shrink-0 font-semibold text-amber-900"
            >
              Dismiss
            </button>
          </div>
        )}

        {/* Assignment sheet: sibling of main scroll area */}
        {assignmentDetailBinding && (
          <div
            className="pointer-events-auto absolute inset-x-0 top-0 bottom-[calc(5.5rem+env(safe-area-inset-bottom,0px))] z-[80] flex min-h-0 w-full flex-col justify-end bg-black/50 overflow-hidden"
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
                    {vehicleBalanceDisplay(
                      assignmentDetailBinding.balance ?? assignmentDetailBinding.cardBalance
                    )}
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
    </div>
  );
}
