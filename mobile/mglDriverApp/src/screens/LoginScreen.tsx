import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useState } from 'react';
import {
  Alert,
  Button,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  driverCheckMobile,
  driverFoList,
  driverFoSelect,
  driverInviteMobileSendOtp,
  driverInviteMobileVerifyOtp,
  driverInviteSetPin,
  driverInviteValidate,
  driverOauthOtpGrant,
  driverPinReset,
  driverSendLoginOtp,
  oauthAccessToken,
  resolveDriverApiBase,
  type CheckMobileStatus,
  type FoListEntry,
} from '../mgl/driver-api';
import { setAccessToken, setApiBase, setFoCompanyId } from '../storage/session';
import type { RootStackParamList } from '../navigation/RootNavigator';
import { DRIVER_APP_PIN_LENGTH, useDualPinEntry, validateCompleteSixDigit } from '../../../../components/mgl/driver-pin-flow';
import { PinDots, PinNumpad } from '../components/PinEntryUi';

type Props = NativeStackScreenProps<RootStackParamList, 'Login'>;

export default function LoginScreen({ navigation }: Props) {
  const [apiBaseInput, setApiBaseInput] = useState('');
  const [mobile, setMobile] = useState('');
  const [kind, setKind] = useState<CheckMobileStatus | null>(null);

  const [inviteCode, setInviteCode] = useState('');
  const [newOtpRef, setNewOtpRef] = useState<string | null>(null);
  const [newOtp, setNewOtp] = useState('');
  const [newMvt, setNewMvt] = useState<string | null>(null);
  const [inviteSessionToken, setInviteSessionToken] = useState<string | null>(null);
  const inviteSignupPin = useDualPinEntry();

  const [retOtp, setRetOtp] = useState('');
  const [retToken1, setRetToken1] = useState<string | null>(null);
  const [foList, setFoList] = useState<FoListEntry[]>([]);
  const [selectedFoId, setSelectedFoId] = useState<number | null>(null);
  const fleetLoginPin = useDualPinEntry();
  const forgotFleetPin = useDualPinEntry();
  const [retPinSubStep, setRetPinSubStep] = useState<'login' | 'forgot'>('login');

  const [loading, setLoading] = useState(false);

  async function resolvedBase(): Promise<string> {
    const base = (apiBaseInput.trim() || (await resolveDriverApiBase())).replace(/\/$/, '');
    await setApiBase(base);
    return base;
  }

  function resetSubFlows() {
    setNewOtpRef(null);
    setNewOtp('');
    setNewMvt(null);
    setInviteCode('');
    setInviteSessionToken(null);
    inviteSignupPin.resetFlow();
    setRetOtp('');
    setRetToken1(null);
    setFoList([]);
    setSelectedFoId(null);
    fleetLoginPin.resetFlow();
    forgotFleetPin.resetFlow();
    setRetPinSubStep('login');
    void setFoCompanyId(null);
  }

  async function onCheckMobile() {
    const m = mobile.trim();
    if (m.length < 10) {
      Alert.alert('Invalid', 'Enter 10-digit mobile.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      const cm = await driverCheckMobile(base, m);
      resetSubFlows();
      setKind(cm);
    } catch (e) {
      Alert.alert('Check failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onNewSendOtp() {
    const m = mobile.trim();
    setLoading(true);
    try {
      const base = await resolvedBase();
      const ref = await driverInviteMobileSendOtp(base, m);
      setNewOtpRef(ref);
      Alert.alert('OTP sent', 'Enter the code.');
    } catch (e) {
      Alert.alert('Send OTP failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onNewVerifyOtp() {
    const m = mobile.trim();
    if (!newOtpRef || newOtp.trim().length < 4) {
      Alert.alert('Invalid', 'Send OTP and enter the code.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      const tok = await driverInviteMobileVerifyOtp(base, m, newOtpRef, newOtp.trim());
      setNewMvt(tok);
      Alert.alert('Verified', 'Enter invite code and tap Validate invite.');
    } catch (e) {
      Alert.alert('Verify failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onInviteValidate() {
    const m = mobile.trim();
    if (!newMvt || !inviteCode.trim()) {
      Alert.alert('Invalid', 'Complete OTP verify and enter invite code.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      const v = await driverInviteValidate(base, m, inviteCode.trim(), newMvt);
      setInviteSessionToken(v.sessionToken);
      inviteSignupPin.resetFlow();
      await setFoCompanyId(v.foCompanyId);
      Alert.alert('Invite OK', `Welcome — set your PIN (${v.foName}).`);
    } catch (e) {
      Alert.alert('Invite invalid', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onInviteSetPinComplete() {
    if (!inviteSessionToken) {
      Alert.alert('Invalid', 'Validate invite first.');
      return;
    }
    if (inviteSignupPin.phase === 'first') {
      inviteSignupPin.goToConfirmStep();
      return;
    }
    const pin = inviteSignupPin.tryFinish();
    if (!pin) return;
    setLoading(true);
    try {
      const base = await resolvedBase();
      const tr = await driverInviteSetPin(base, inviteSessionToken, pin);
      const access = oauthAccessToken(tr);
      if (!access) throw new Error('Missing access token');
      await setAccessToken(access);
      inviteSignupPin.resetFlow();
      navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
    } catch (e) {
      Alert.alert('Set PIN failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onReturningSendOtp() {
    const m = mobile.trim();
    setLoading(true);
    try {
      const base = await resolvedBase();
      await driverSendLoginOtp(base, m);
      Alert.alert('OTP sent', 'Enter the login code.');
    } catch (e) {
      Alert.alert('Send OTP failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onReturningExchangeOtp() {
    const m = mobile.trim();
    const o = retOtp.trim();
    if (o.length < 4) {
      Alert.alert('Invalid', 'Enter OTP.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      const tr = await driverOauthOtpGrant(base, m, o);
      const t1 = oauthAccessToken(tr);
      if (!t1) throw new Error('No token from oauth');
      setRetToken1(t1);
      const fos = await driverFoList(base, t1);
      const active = fos.filter((f) => f.foStatus === 'ACTIVE');
      setFoList(active);
      if (!active.length) {
        setRetToken1(null);
        Alert.alert('No fleet', 'No active fleet operators.');
        return;
      }
      setSelectedFoId(active.length === 1 ? active[0].foCompanyId : null);
      fleetLoginPin.resetFlow();
      forgotFleetPin.resetFlow();
      setRetPinSubStep('login');
    } catch (e) {
      Alert.alert('Login OTP failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onFleetLoginPrimaryPress() {
    if (!retToken1 || selectedFoId == null) {
      Alert.alert('Invalid', 'Complete OTP exchange and select fleet if needed.');
      return;
    }
    const pin = fleetLoginPin.pinFirst;
    if (validateCompleteSixDigit(pin) != null) {
      Alert.alert('Invalid', 'Enter a 6-digit PIN.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      const tr = await driverFoSelect(base, retToken1, selectedFoId, pin);
      const access = oauthAccessToken(tr);
      if (!access) throw new Error('Missing access token');
      await setAccessToken(access);
      await setFoCompanyId(selectedFoId);
      fleetLoginPin.resetFlow();
      navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
    } catch (e) {
      fleetLoginPin.resetFlow();
      Alert.alert('PIN login failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onFleetForgotPinSubmit() {
    if (!retToken1 || selectedFoId == null) {
      Alert.alert('Invalid', 'Complete OTP exchange and select fleet if needed.');
      return;
    }
    if (forgotFleetPin.phase === 'first') {
      forgotFleetPin.goToConfirmStep();
      return;
    }
    const pin = forgotFleetPin.tryFinish();
    if (!pin) return;
    setLoading(true);
    try {
      const base = await resolvedBase();
      await driverPinReset(base, retToken1, selectedFoId, pin);
      await setAccessToken(null);
      await setFoCompanyId(null);
      setRetToken1(null);
      setFoList([]);
      setSelectedFoId(null);
      setRetOtp('');
      fleetLoginPin.resetFlow();
      forgotFleetPin.resetFlow();
      setRetPinSubStep('login');
      Alert.alert(
        'PIN reset',
        'Your session was cleared. Send login OTP again, then sign in with your new PIN.'
      );
    } catch (e) {
      Alert.alert('PIN reset failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onContinueWithoutLogin() {
    await resolvedBase();
    await setAccessToken(null);
    await setFoCompanyId(null);
    navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
  }

  const inviteSignupDisabledContinue =
    !inviteSessionToken ||
    loading ||
    (inviteSignupPin.phase === 'first'
      ? inviteSignupPin.pinFirst.length !== 6
      : inviteSignupPin.pinSecond.length !== 6);

  const fleetLoginDisabledContinue =
    !retToken1 || loading || selectedFoId == null || fleetLoginPin.pinFirst.length !== DRIVER_APP_PIN_LENGTH;

  const forgotPinDisabledContinue =
    !retToken1 ||
    loading ||
    selectedFoId == null ||
    (forgotFleetPin.phase === 'first'
      ? forgotFleetPin.pinFirst.length !== 6
      : forgotFleetPin.pinSecond.length !== 6);

  return (
    <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
      <Text style={styles.title}>MGL Driver</Text>

      <Text style={styles.label}>API Base (optional)</Text>
      <TextInput
        value={apiBaseInput}
        onChangeText={setApiBaseInput}
        placeholder="https://api-fleet-uat.enkash.in"
        autoCapitalize="none"
        autoCorrect={false}
        style={styles.input}
      />

      <Text style={styles.label}>Mobile</Text>
      <TextInput
        value={mobile}
        onChangeText={setMobile}
        placeholder="9999999999"
        keyboardType="phone-pad"
        autoCapitalize="none"
        style={styles.input}
      />
      <View style={styles.actions}>
        <Button title={loading ? '…' : 'Check mobile'} disabled={loading} onPress={() => void onCheckMobile()} />
      </View>

      {kind === 'NEW_USER' && (
        <>
          <Text style={styles.section}>New user — invite</Text>
          <View style={styles.actions}>
            <Button title="1 · Send OTP" disabled={loading} onPress={() => void onNewSendOtp()} />
          </View>
          <Text style={styles.label}>OTP</Text>
          <TextInput
            value={newOtp}
            onChangeText={setNewOtp}
            keyboardType="number-pad"
            secureTextEntry
            style={styles.input}
          />
          <View style={styles.actions}>
            <Button title="2 · Verify OTP" disabled={loading} onPress={() => void onNewVerifyOtp()} />
          </View>
          <Text style={styles.label}>Invite code</Text>
          <TextInput
            value={inviteCode}
            onChangeText={setInviteCode}
            placeholder="Invite code"
            autoCapitalize="characters"
            style={styles.input}
          />
          <View style={styles.actions}>
            <Button title="3 · Validate invite" disabled={loading} onPress={() => void onInviteValidate()} />
          </View>
          {inviteSessionToken ? (
            <>
              <Text style={styles.section}>
                {inviteSignupPin.phase === 'first' ? 'Enter New PIN' : 'Confirm New PIN'}
              </Text>
              <Text style={styles.hint}>6 digits, numeric keypad only.</Text>
              <PinDots filled={inviteSignupPin.activeValue.length} />
              <PinNumpad
                disabled={loading}
                onDigit={inviteSignupPin.appendDigit}
                onBackspace={inviteSignupPin.backspace}
              />
              {inviteSignupPin.error ? <Text style={styles.pinErr}>{inviteSignupPin.error}</Text> : null}
              {inviteSignupPin.phase === 'second' ? (
                <TouchableOpacity
                  style={styles.textBtn}
                  accessibilityRole="button"
                  disabled={loading}
                  onPress={() => inviteSignupPin.goBackToFirst()}
                >
                  <Text style={styles.backToLoginText}>{'← Back'}</Text>
                </TouchableOpacity>
              ) : null}
              <View style={styles.actions}>
                <Button
                  title={
                    inviteSignupPin.phase === 'first'
                      ? '4 · Confirm PIN'
                      : loading
                        ? '…'
                        : '5 · Complete signup'
                  }
                  disabled={inviteSignupDisabledContinue}
                  onPress={() => void onInviteSetPinComplete()}
                />
              </View>
            </>
          ) : null}
        </>
      )}

      {kind === 'RETURNING_USER' && (
        <>
          <Text style={styles.section}>Returning driver</Text>
          <View style={styles.actions}>
            <Button title="1 · Send login OTP" disabled={loading} onPress={() => void onReturningSendOtp()} />
          </View>
          <Text style={styles.label}>OTP</Text>
          <TextInput value={retOtp} onChangeText={setRetOtp} keyboardType="number-pad" secureTextEntry style={styles.input} />
          <View style={styles.actions}>
            <Button title="2 · Exchange OTP → fleet list" disabled={loading} onPress={() => void onReturningExchangeOtp()} />
          </View>
          {foList.length > 1 && retToken1 ? (
            <>
              <Text style={styles.label}>Fleet</Text>
              {foList.map((f) => (
                <TouchableOpacity
                  key={f.foCompanyId}
                  style={[styles.foRow, selectedFoId === f.foCompanyId && styles.foRowSelected]}
                  onPress={() => {
                    setSelectedFoId(f.foCompanyId);
                    fleetLoginPin.resetFlow();
                    forgotFleetPin.resetFlow();
                    setRetPinSubStep('login');
                  }}
                >
                  <Text style={styles.foName}>{f.foName}</Text>
                  <Text style={styles.foMeta}>#{f.foCompanyId}</Text>
                </TouchableOpacity>
              ))}
            </>
          ) : null}
          {retToken1 && foList.length > 0 ? (
            retPinSubStep === 'login' ? (
              <>
                <Text style={styles.section}>Enter Fleet PIN</Text>
                <PinDots filled={fleetLoginPin.pinFirst.length} />
                <PinNumpad disabled={loading} onDigit={fleetLoginPin.appendDigit} onBackspace={fleetLoginPin.backspace} />
                {fleetLoginPin.error ? <Text style={styles.pinErr}>{fleetLoginPin.error}</Text> : null}
                <View style={styles.actions}>
                  <Button
                    title={loading ? '…' : 'Unlock app'}
                    disabled={fleetLoginDisabledContinue}
                    onPress={() => void onFleetLoginPrimaryPress()}
                  />
                </View>
                <TouchableOpacity
                  onPress={() => {
                    forgotFleetPin.resetFlow();
                    setRetPinSubStep('forgot');
                  }}
                  style={styles.forgotPinTouchable}
                  accessibilityRole="button"
                >
                  <Text style={styles.forgotPinLink}>Forgot PIN?</Text>
                </TouchableOpacity>
              </>
            ) : (
              <>
                <TouchableOpacity
                  onPress={() => {
                    forgotFleetPin.resetFlow();
                    setRetPinSubStep('login');
                  }}
                  style={styles.backToLoginRow}
                  accessibilityRole="button"
                >
                  <Text style={styles.backToLoginText}>{'← Back to PIN login'}</Text>
                </TouchableOpacity>
                <Text style={styles.section}>Forgot or locked PIN</Text>
                <Text style={styles.label}>
                  {forgotFleetPin.phase === 'first'
                    ? 'Enter New PIN (6 digits). You will verify OTP again after reset.'
                    : 'Confirm New PIN'}
                </Text>
                <PinDots filled={forgotFleetPin.activeValue.length} />
                <PinNumpad disabled={loading} onDigit={forgotFleetPin.appendDigit} onBackspace={forgotFleetPin.backspace} />
                {forgotFleetPin.error ? <Text style={styles.pinErr}>{forgotFleetPin.error}</Text> : null}
                {forgotFleetPin.phase === 'second' ? (
                  <TouchableOpacity
                    style={styles.textBtn}
                    accessibilityRole="button"
                    disabled={loading}
                    onPress={() => forgotFleetPin.goBackToFirst()}
                  >
                    <Text style={styles.backToLoginText}>{'← Back'}</Text>
                  </TouchableOpacity>
                ) : null}
                <View style={styles.actions}>
                  <Button
                    title={
                      forgotFleetPin.phase === 'first' ? 'Confirm PIN' : loading ? '…' : 'Reset PIN'
                    }
                    disabled={forgotPinDisabledContinue}
                    onPress={() => void onFleetForgotPinSubmit()}
                  />
                </View>
              </>
            )
          ) : null}
        </>
      )}

      <View style={styles.actions}>
        <Button title="Continue without login" disabled={loading} onPress={() => void onContinueWithoutLogin()} />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: { flexGrow: 1, padding: 16, gap: 8, paddingBottom: 32 },
  title: { fontSize: 22, fontWeight: '700', textAlign: 'center', marginBottom: 8 },
  section: { fontSize: 15, fontWeight: '700', marginTop: 8 },
  hint: { fontSize: 13, color: '#616161', marginBottom: 2 },
  pinErr: { fontSize: 13, fontWeight: '600', color: '#c62828', textAlign: 'center', marginTop: 6 },
  textBtn: { marginTop: 4, paddingVertical: 6 },
  label: { fontSize: 13, fontWeight: '600' },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
  },
  actions: { marginTop: 4 },
  foRow: { borderWidth: 1, borderColor: '#ddd', borderRadius: 10, padding: 12, marginBottom: 8 },
  foRowSelected: { borderColor: '#2e7d32', backgroundColor: '#e8f5e9' },
  foName: { fontSize: 16, fontWeight: '600' },
  foMeta: { fontSize: 12, color: '#666' },
  forgotPinTouchable: { marginTop: 8, paddingVertical: 8 },
  forgotPinLink: {
    fontSize: 15,
    fontWeight: '600',
    color: '#2e7d32',
    textAlign: 'center',
  },
  backToLoginRow: { marginBottom: 8, paddingVertical: 6 },
  backToLoginText: { fontSize: 15, fontWeight: '600', color: '#666' },
});
