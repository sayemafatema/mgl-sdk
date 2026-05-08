import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnDestroy,
  OnInit,
} from '@angular/core';
import {
  MOCK_INVITE_CODES,
  type FleetAppSnapshot,
  type FleetBinding,
} from '@mgl/fleet-core-sdk';
import { FleetService } from './fleet.service';

@Component({
  selector: 'mgl-fleet-flow-host',
  templateUrl: './fleet-flow-host.component.html',
  styleUrls: ['./fleet-flow-host.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FleetFlowHostComponent implements OnInit, OnDestroy {
  s!: FleetAppSnapshot;
  readonly inviteLookup = MOCK_INVITE_CODES;
  private off?: () => void;

  constructor(
    private readonly fleet: FleetService,
    private readonly cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const eng = this.engine();
    this.s = eng.getSnapshot();
    this.off = eng.subscribe(() => {
      this.s = eng.getSnapshot();
      this.cdr.markForCheck();
    });
  }

  ngOnDestroy(): void {
    this.off?.();
  }

  engine() {
    return this.fleet.raw().appFlow;
  }

  skipDev(): void {
    this.engine().skipToMainApp();
  }

  onMobileInput(ev: Event): void {
    this.engine().setMobileNumber((ev.target as HTMLInputElement).value);
  }

  sendLoginOtp(): void {
    this.engine().loginSendOtp();
  }

  otpLoginDigit(i: number, ev: Event): void {
    const v = (ev.target as HTMLInputElement).value;
    this.engine().setLoginOtpDigit(i, v);
    (ev.target as HTMLInputElement).value = '';
  }

  authBack(): void {
    this.engine().authBack();
  }

  pinDigit(d: string): void {
    this.engine().loginPinAppend(d);
  }

  pinBs(): void {
    this.engine().loginPinBackspace();
  }

  forgotPin(): void {
    this.engine().goToForgotPin();
  }

  forgotSendOtp(): void {
    this.engine().forgotPinSendOtp();
  }

  forgotOtpDigit(i: number, ev: Event): void {
    const v = (ev.target as HTMLInputElement).value;
    this.engine().setForgotOtpDigit(i, v);
    (ev.target as HTMLInputElement).value = '';
  }

  verifyForgotOtp(): void {
    this.engine().verifyForgotOtp();
  }

  npAppend(k: string): void {
    this.engine().newPinAppend(k);
  }

  npBs(): void {
    this.engine().newPinBackspace();
  }

  npNext(): void {
    this.engine().goConfirmNewPin();
  }

  cpAppend(k: string): void {
    this.engine().confirmPinAppend(k);
  }

  cpBs(): void {
    this.engine().confirmPinBackspace();
  }

  cpSubmit(): void {
    this.engine().submitConfirmPin();
  }

  regContinue(): void {
    this.engine().registeredContinueHome();
  }

  goInvite(): void {
    this.engine().goInviteSignup();
  }

  onInviteInput(ev: Event): void {
    this.engine().setInviteCode((ev.target as HTMLInputElement).value);
  }

  inviteNext(): void {
    this.engine().inviteContinue();
  }

  inviteSendOtp(): void {
    this.engine().inviteSendOtp();
  }

  invOtpDigit(i: number, ev: Event): void {
    const v = (ev.target as HTMLInputElement).value;
    this.engine().setInviteOtpDigit(i, v);
    (ev.target as HTMLInputElement).value = '';
  }

  ipAppend(k: string): void {
    this.engine().invitePinAppend(k);
  }

  ipBs(): void {
    this.engine().invitePinBackspace();
  }

  ipNext(): void {
    this.engine().invitePinNext();
  }

  ipcAppend(k: string): void {
    this.engine().invitePinConfirmAppend(k);
  }

  ipcBs(): void {
    this.engine().invitePinConfirmBackspace();
  }

  inviteDone(): void {
    this.engine().inviteConfirmSubmit();
  }

  tab(t: FleetAppSnapshot['activeTab']): void {
    this.engine().setTab(t);
  }

  demoAssignment(): void {
    this.engine().openAssignmentDemo();
  }

  demoPairing(): void {
    this.engine().openPairingDemo();
  }

  assignAccept(): void {
    this.engine().acceptAssignmentDemo();
  }

  assignBack(): void {
    this.engine().setMainOverlay('home');
  }

  assignDismiss(): void {
    this.engine().dismissAssignmentFlow();
  }

  pairDigit(i: number, ev: Event): void {
    const v = (ev.target as HTMLInputElement).value;
    this.engine().setPairingDigit(i, v);
    (ev.target as HTMLInputElement).value = '';
  }

  pairSubmit(): void {
    this.engine().submitPairingCode();
  }

  prevCard(): void {
    const cards = this.engine().activeCards();
    let i = this.s.activeCardIndex;
    if (i > 0) i--;
    this.engine().setActiveCardIndex(i);
  }

  nextCard(): void {
    const cards = this.engine().activeCards();
    let i = this.s.activeCardIndex;
    if (i < cards.length - 1) i++;
    this.engine().setActiveCardIndex(i);
  }

  dotCard(i: number): void {
    this.engine().setActiveCardIndex(i);
  }

  scanPick(b: FleetBinding): void {
    this.engine().scanPickBinding(b.id);
  }

  simulateScan(): void {
    this.engine().scanBeginConfirmation();
  }

  cancelConfirm(): void {
    this.engine().scanCancelConfirmation();
  }

  confirmFuel(): void {
    this.engine().scanConfirmAuthorize();
  }

  onSessionPin(ev: Event): void {
    this.engine().setSessionPin((ev.target as HTMLInputElement).value);
  }

  logout(): void {
    this.engine().logout();
  }

  cards(): FleetBinding[] {
    return this.engine().activeCards();
  }

  scanAvail(): FleetBinding[] {
    return this.engine().scanAvailableBindings();
  }

  selectedScan(): FleetBinding | null {
    return this.engine().selectedScanBinding();
  }

  card(): FleetBinding | null {
    return this.engine().currentCard();
  }

  assignment(): FleetBinding {
    return this.engine().assignmentDemoBinding();
  }

  pendingAssignmentCount(): number {
    return this.engine().pendingAssignmentCount();
  }

  timeGreeting(): string {
    const h = new Date().getHours();
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  nums(): number[] {
    return [1, 2, 3, 4, 5, 6, 7, 8, 9];
  }

  otpSlots(): number[] {
    return [0, 1, 2, 3, 4, 5];
  }

  lockedBindings(): FleetBinding[] {
    return this.s.bindings.filter(
      (b) =>
        b.scanPayStatus === 'locked_unpaired' ||
        b.scanPayStatus === 'locked_repair'
    );
  }
}
