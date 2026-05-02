import type {
  FleetBinding,
  FleetDriverProfile,
  FleetTransaction,
} from '../models/driver';
import {
  MOCK_BINDINGS,
  MOCK_FLEET_PROFILE,
  MOCK_INVITE_CODES,
  MOCK_PAIRING_CODES,
  MOCK_TRANSACTIONS,
} from './mock-data';

/** Mirrors `app/page.tsx` onboarding & main-app phases (demo behaviour). */
export type AuthStep =
  | 'login'
  | 'login_otp'
  | 'pin_login'
  | 'set_pin'
  | 'confirm_pin'
  | 'registered'
  | 'invite_code'
  | 'invite_mobile'
  | 'invite_otp'
  | 'invite_pin'
  | 'invite_confirm_pin'
  | 'forgot_pin'
  | 'forgot_otp'
  | 'complete';

export type MainOverlay =
  | 'home'
  | 'assignment_notification'
  | 'pairing_code'
  | 'assignment_accepted';

export type ActiveTab = 'card' | 'scan' | 'assignments' | 'transactions' | 'profile';

export type ScanSession =
  | 'idle'
  | 'scanning'
  | 'confirmation'
  | 'otp_entry'
  | 'authorized'
  | 'complete';

export interface FleetAppSnapshot {
  authStep: AuthStep;
  profile: FleetDriverProfile;
  mobileNumber: string;
  otpDigitsLogin: string[];
  otpErrorLogin: string;
  inviteCode: string;
  inviteOtp: string;
  invitePin: string;
  invitePinConfirm: string;
  loginPin: string;
  loginPinError: string;
  wrongAttempts: number;
  disableLoginNumpad: boolean;
  newPin: string;
  pinConfirm: string;
  pinError: string;
  isNewUser: boolean;
  successToast: string | null;
  mainOverlay: MainOverlay;
  activeTab: ActiveTab;
  activeCardIndex: number;
  sessionState: ScanSession;
  sessionPin: string;
  pairingDigits: string[];
  pairingError: string;
  pairingAttempts: number;
  selectedScanBindingId: string | null;
  bindings: FleetBinding[];
  transactions: FleetTransaction[];
  pendingPairingCode: string;
}

const DEMO_OTP = '123456';
const DEMO_PIN = '123456';

function cloneBindings(base: FleetBinding[]): FleetBinding[] {
  return base.map((b) => ({ ...b }));
}

export class FleetAppEngine {
  private listeners = new Set<() => void>();
  private state: FleetAppSnapshot;

  constructor() {
    this.state = this.initialState();
  }

  private initialState(): FleetAppSnapshot {
    return {
      authStep: 'login',
      profile: { ...MOCK_FLEET_PROFILE },
      mobileNumber: '',
      otpDigitsLogin: Array(6).fill(''),
      otpErrorLogin: '',
      inviteCode: '',
      inviteOtp: '',
      invitePin: '',
      invitePinConfirm: '',
      loginPin: '',
      loginPinError: '',
      wrongAttempts: 0,
      disableLoginNumpad: false,
      newPin: '',
      pinConfirm: '',
      pinError: '',
      isNewUser: false,
      successToast: null,
      mainOverlay: 'home',
      activeTab: 'card',
      activeCardIndex: 0,
      sessionState: 'idle',
      sessionPin: '',
      pairingDigits: Array(6).fill(''),
      pairingError: '',
      pairingAttempts: 0,
      selectedScanBindingId: null,
      bindings: cloneBindings(MOCK_BINDINGS),
      transactions: [...MOCK_TRANSACTIONS],
      pendingPairingCode: '234567',
    };
  }

  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    listener();
    return () => this.listeners.delete(listener);
  }

  private emit(): void {
    this.listeners.forEach((l) => l());
  }

  private patch(p: Partial<FleetAppSnapshot>): void {
    this.state = { ...this.state, ...p };
    this.emit();
  }

  getSnapshot(): FleetAppSnapshot {
    return this.state;
  }

  skipToMainApp(): void {
    this.patch({
      authStep: 'complete',
      mainOverlay: 'home',
      activeTab: 'card',
      loginPin: '',
      otpDigitsLogin: Array(6).fill(''),
    });
  }

  setMobileNumber(value: string): void {
    this.patch({ mobileNumber: value.replace(/\D/g, '').slice(0, 10) });
  }

  loginSendOtp(): void {
    if (this.state.mobileNumber.length !== 10) return;
    this.patch({
      authStep: 'login_otp',
      otpDigitsLogin: Array(6).fill(''),
      otpErrorLogin: '',
    });
  }

  setLoginOtpDigit(index: number, digit: string): void {
    const d = digit.replace(/\D/g, '').slice(-1);
    const next = [...this.state.otpDigitsLogin];
    next[index] = d;
    this.patch({ otpDigitsLogin: next });
    if (next.join('').length === 6) {
      this.verifyLoginOtp();
    }
  }

  verifyLoginOtp(): void {
    const entered = this.state.otpDigitsLogin.join('');
    if (entered !== DEMO_OTP) {
      this.patch({ otpErrorLogin: 'Incorrect OTP. Try again.' });
      setTimeout(() => {
        this.patch({ otpDigitsLogin: Array(6).fill(''), otpErrorLogin: '' });
      }, 1200);
      return;
    }
    this.patch({
      authStep: 'pin_login',
      loginPin: '',
      loginPinError: '',
      otpErrorLogin: '',
    });
  }

  loginPinAppend(digit: string): void {
    if (this.state.disableLoginNumpad || this.state.loginPin.length >= 6) return;
    const next = this.state.loginPin + digit;
    this.patch({ loginPin: next, loginPinError: '' });
    if (next.length === 6) this.submitLoginPin(next);
  }

  loginPinBackspace(): void {
    if (this.state.disableLoginNumpad) return;
    this.patch({ loginPin: this.state.loginPin.slice(0, -1) });
  }

  private submitLoginPin(pin: string): void {
    if (pin === DEMO_PIN) {
      this.patch({
        authStep: 'complete',
        loginPinError: '',
        wrongAttempts: 0,
        disableLoginNumpad: false,
      });
      return;
    }
    const attempts = this.state.wrongAttempts + 1;
    const disable = attempts >= 3;
    this.patch({
      loginPinError: 'Incorrect PIN',
      loginPin: '',
      wrongAttempts: attempts,
      disableLoginNumpad: disable,
    });
  }

  goToForgotPin(): void {
    this.patch({
      authStep: 'forgot_pin',
      inviteOtp: '',
      otpDigitsLogin: Array(6).fill(''),
    });
  }

  forgotPinSendOtp(): void {
    this.patch({ authStep: 'forgot_otp', inviteOtp: '' });
  }

  setForgotOtpDigit(index: number, digit: string): void {
    const d = digit.replace(/\D/g, '').slice(-1);
    const chars = this.state.inviteOtp.split('');
    while (chars.length < 6) chars.push('');
    chars[index] = d;
    this.patch({ inviteOtp: chars.join('').slice(0, 6) });
  }

  verifyForgotOtp(): void {
    if (this.state.inviteOtp !== DEMO_OTP) return;
    this.patch({
      authStep: 'set_pin',
      inviteOtp: '',
      newPin: '',
      pinConfirm: '',
      pinError: '',
      isNewUser: false,
    });
  }

  newPinAppend(digit: string): void {
    if (this.state.newPin.length >= 6) return;
    this.patch({ newPin: this.state.newPin + digit });
  }

  newPinBackspace(): void {
    this.patch({ newPin: this.state.newPin.slice(0, -1) });
  }

  goConfirmNewPin(): void {
    if (this.state.newPin.length !== 6) return;
    this.patch({ authStep: 'confirm_pin', pinConfirm: '', pinError: '' });
  }

  confirmPinAppend(digit: string): void {
    if (this.state.pinConfirm.length >= 6) return;
    this.patch({ pinConfirm: this.state.pinConfirm + digit });
  }

  confirmPinBackspace(): void {
    this.patch({ pinConfirm: this.state.pinConfirm.slice(0, -1) });
  }

  submitConfirmPin(): void {
    if (this.state.pinConfirm.length !== 6) return;
    if (this.state.newPin !== this.state.pinConfirm) {
      this.patch({
        pinError: "PINs didn't match. Try again.",
        pinConfirm: '',
        authStep: 'set_pin',
      });
      return;
    }
    if (this.state.isNewUser) {
      this.patch({ authStep: 'registered', pinError: '' });
    } else {
      this.patch({
        successToast: 'PIN updated successfully',
        newPin: '',
        pinConfirm: '',
        pinError: '',
        authStep: 'pin_login',
      });
      setTimeout(() => this.patch({ successToast: null }), 2000);
    }
  }

  registeredContinueHome(): void {
    this.patch({
      authStep: 'complete',
      isNewUser: false,
      newPin: '',
      pinConfirm: '',
    });
  }

  authBack(): void {
    const step = this.state.authStep;
    if (step === 'login_otp') this.patch({ authStep: 'login' });
    else if (step === 'invite_code') this.patch({ authStep: 'login' });
    else if (step === 'invite_mobile') this.patch({ authStep: 'invite_code' });
    else if (step === 'invite_otp') this.patch({ authStep: 'invite_mobile' });
    else if (step === 'forgot_otp') this.patch({ authStep: 'forgot_pin' });
    else if (step === 'forgot_pin') {
      this.patch({
        authStep: 'pin_login',
        inviteOtp: '',
      });
    }
  }

  goInviteSignup(): void {
    this.patch({ authStep: 'invite_code', inviteCode: '' });
  }

  setInviteCode(raw: string): void {
    this.patch({
      inviteCode: raw.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6),
    });
  }

  inviteContinue(): void {
    const code = this.state.inviteCode;
    if (code.length !== 6 || !MOCK_INVITE_CODES[code]) return;
    this.patch({ authStep: 'invite_mobile', mobileNumber: '' });
  }

  inviteSendOtp(): void {
    if (this.state.mobileNumber.length !== 10) return;
    this.patch({ authStep: 'invite_otp', inviteOtp: '' });
  }

  setInviteOtpDigit(index: number, digit: string): void {
    const d = digit.replace(/\D/g, '').slice(-1);
    const chars = this.state.inviteOtp.split('');
    while (chars.length < 6) chars.push('');
    chars[index] = d;
    const joined = chars.join('').slice(0, 6);
    this.patch({ inviteOtp: joined });
    if (joined.length === 6) this.verifyInviteOtp();
  }

  verifyInviteOtp(): void {
    if (this.state.inviteOtp !== DEMO_OTP) return;
    this.patch({
      authStep: 'invite_pin',
      invitePin: '',
      invitePinConfirm: '',
      pinError: '',
    });
  }

  invitePinAppend(digit: string): void {
    if (this.state.invitePin.length >= 6) return;
    this.patch({ invitePin: this.state.invitePin + digit });
  }

  invitePinBackspace(): void {
    this.patch({ invitePin: this.state.invitePin.slice(0, -1) });
  }

  invitePinNext(): void {
    if (this.state.invitePin.length !== 6) return;
    this.patch({
      authStep: 'invite_confirm_pin',
      invitePinConfirm: '',
      pinError: '',
    });
  }

  invitePinConfirmAppend(digit: string): void {
    if (this.state.invitePinConfirm.length >= 6) return;
    this.patch({
      invitePinConfirm: this.state.invitePinConfirm + digit,
    });
  }

  invitePinConfirmBackspace(): void {
    this.patch({
      invitePinConfirm: this.state.invitePinConfirm.slice(0, -1),
    });
  }

  inviteConfirmSubmit(): void {
    if (this.state.invitePinConfirm.length !== 6) return;
    if (this.state.invitePin !== this.state.invitePinConfirm) {
      this.patch({
        pinError: "PINs don't match, try again",
        invitePinConfirm: '',
      });
      return;
    }
    this.patch({
      authStep: 'complete',
      pinError: '',
      isNewUser: true,
    });
  }

  setTab(tab: ActiveTab): void {
    const extra: Partial<FleetAppSnapshot> = { activeTab: tab };
    if (tab === 'scan') {
      const avail = this.scanAvailableBindings();
      if (avail.length && !this.state.selectedScanBindingId) {
        extra.selectedScanBindingId = avail[0].id;
      }
    }
    this.patch(extra);
  }

  setMainOverlay(o: MainOverlay): void {
    this.patch({ mainOverlay: o });
  }

  openAssignmentDemo(): void {
    this.patch({ mainOverlay: 'assignment_notification', activeTab: 'card' });
  }

  acceptAssignmentDemo(): void {
    this.patch({ mainOverlay: 'assignment_accepted' });
  }

  dismissAssignmentFlow(): void {
    this.patch({ mainOverlay: 'home', activeTab: 'assignments' });
  }

  openPairingDemo(): void {
    this.patch({
      mainOverlay: 'pairing_code',
      pairingDigits: Array(6).fill(''),
      pairingError: '',
    });
  }

  setPairingDigit(i: number, v: string): void {
    const d = v.replace(/\D/g, '').slice(-1);
    const next = [...this.state.pairingDigits];
    next[i] = d;
    this.patch({ pairingDigits: next });
  }

  submitPairingCode(): void {
    const code = this.state.pairingDigits.join('');
    if (code.length !== 6) return;
    const info = MOCK_PAIRING_CODES[code];
    if (!info) {
      const attempts = this.state.pairingAttempts + 1;
      this.patch({
        pairingError: 'Invalid pairing code',
        pairingAttempts: attempts,
        pairingDigits: Array(6).fill(''),
      });
      return;
    }
    this.patch({
      mainOverlay: 'home',
      pairingError: '',
      activeTab: 'assignments',
    });
  }

  setActiveCardIndex(i: number): void {
    const active = this.activeCards();
    if (i >= 0 && i < active.length) this.patch({ activeCardIndex: i });
  }

  activeCards(): FleetBinding[] {
    return this.state.bindings.filter(
      (b) => b.paired && b.state === 'ACTIVE'
    );
  }

  scanAvailableBindings(): FleetBinding[] {
    return this.state.bindings.filter(
      (b) =>
        b.paired &&
        b.state === 'ACTIVE' &&
        (b.scanPayStatus === 'always_available' ||
          b.scanPayStatus === 'in_window')
    );
  }

  selectedScanBinding(): FleetBinding | null {
    const id = this.state.selectedScanBindingId;
    if (!id) return null;
    return this.state.bindings.find((b) => b.id === id) ?? null;
  }

  currentCard(): FleetBinding | null {
    const cards = this.activeCards();
    return cards[this.state.activeCardIndex] ?? cards[0] ?? null;
  }

  pendingAssignmentCount(): number {
    return this.state.bindings.filter(
      (b) =>
        b.state === 'PENDING_ACCEPTANCE' ||
        (!b.paired && b.state === 'ACTIVE')
    ).length;
  }

  assignmentDemoBinding(): FleetBinding {
    return (
      this.state.bindings.find((b) => b.state === 'PENDING_ACCEPTANCE') ??
      this.state.bindings[3] ??
      this.state.bindings[0]
    );
  }

  scanPickBinding(id: string): void {
    this.patch({ selectedScanBindingId: id });
  }

  scanBeginConfirmation(): void {
    const avail = this.scanAvailableBindings();
    if (!avail.length) return;
    const id = this.state.selectedScanBindingId ?? avail[0].id;
    this.patch({ selectedScanBindingId: id, sessionState: 'confirmation' });
  }

  scanCancelConfirmation(): void {
    this.patch({ sessionState: 'idle' });
  }

  scanConfirmAuthorize(): void {
    if (this.state.sessionPin !== DEMO_PIN) return;
    this.patch({ sessionState: 'idle', sessionPin: '' });
  }

  setSessionPin(pin: string): void {
    this.patch({ sessionPin: pin.replace(/\D/g, '').slice(0, 6) });
  }

  logout(): void {
    this.state = this.initialState();
    this.emit();
  }
}
