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
import { setAccessToken, setApiBase } from '../storage/session';
import type { RootStackParamList } from '../navigation/RootNavigator';

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
  const [newPin, setNewPin] = useState('');

  const [retOtp, setRetOtp] = useState('');
  const [retToken1, setRetToken1] = useState<string | null>(null);
  const [foList, setFoList] = useState<FoListEntry[]>([]);
  const [selectedFoId, setSelectedFoId] = useState<number | null>(null);
  const [retPin, setRetPin] = useState('');
  const [resetNewPin, setResetNewPin] = useState('');
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
    setNewPin('');
    setRetOtp('');
    setRetToken1(null);
    setFoList([]);
    setSelectedFoId(null);
    setRetPin('');
    setResetNewPin('');
    setRetPinSubStep('login');
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

  /** Flow 1 — send-otp */
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
      Alert.alert('Invite OK', `Welcome — set your PIN (${v.foName}).`);
    } catch (e) {
      Alert.alert('Invite invalid', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onInviteSetPin() {
    const pin = newPin.trim();
    if (!inviteSessionToken || pin.length < 4) {
      Alert.alert('Invalid', 'Validate invite and enter PIN.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      const tr = await driverInviteSetPin(base, inviteSessionToken, pin);
      const access = oauthAccessToken(tr);
      if (!access) throw new Error('Missing access token');
      await setAccessToken(access);
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
      setRetPinSubStep('login');
    } catch (e) {
      Alert.alert('Login OTP failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onReturningFoLogin() {
    if (!retToken1 || selectedFoId == null) {
      Alert.alert('Invalid', 'Complete OTP exchange and select fleet if needed.');
      return;
    }
    const pin = retPin.trim();
    if (pin.length < 4 || pin.length > 6) {
      Alert.alert('Invalid', 'PIN must be 4–6 digits.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      const tr = await driverFoSelect(base, retToken1, selectedFoId, pin);
      const access = oauthAccessToken(tr);
      if (!access) throw new Error('Missing access token');
      await setAccessToken(access);
      navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
    } catch (e) {
      Alert.alert('PIN login failed', e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  async function onReturningPinResetAndLogin() {
    if (!retToken1 || selectedFoId == null) {
      Alert.alert('Invalid', 'Complete OTP exchange and select fleet if needed.');
      return;
    }
    const pin = resetNewPin.trim();
    if (pin.length < 4 || pin.length > 6) {
      Alert.alert('Invalid', 'New PIN must be 4–6 digits.');
      return;
    }
    setLoading(true);
    try {
      const base = await resolvedBase();
      await driverPinReset(base, retToken1, selectedFoId, pin);
      await setAccessToken(null);
      setRetToken1(null);
      setFoList([]);
      setSelectedFoId(null);
      setRetOtp('');
      setRetPin('');
      setResetNewPin('');
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
    const base = await resolvedBase();
    await setAccessToken(null);
    navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
  }

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
          <Text style={styles.label}>Choose PIN</Text>
          <TextInput
            value={newPin}
            onChangeText={setNewPin}
            keyboardType="number-pad"
            secureTextEntry
            placeholder="4–6 digits"
            style={styles.input}
          />
          <View style={styles.actions}>
            <Button title="4 · Complete signup" disabled={loading} onPress={() => void onInviteSetPin()} />
          </View>
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
                    setRetPinSubStep('login');
                    setResetNewPin('');
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
                <Text style={styles.label}>PIN</Text>
                <TextInput value={retPin} onChangeText={setRetPin} keyboardType="number-pad" secureTextEntry style={styles.input} />
                <View style={styles.actions}>
                  <Button title="Login" disabled={loading} onPress={() => void onReturningFoLogin()} />
                </View>
                <TouchableOpacity
                  onPress={() => {
                    setResetNewPin('');
                    setRetPinSubStep('forgot');
                  }}
                  style={styles.forgotPinTouchable}
                >
                  <Text style={styles.forgotPinLink}>Forgot PIN?</Text>
                </TouchableOpacity>
              </>
            ) : (
              <>
                <TouchableOpacity
                  onPress={() => {
                    setResetNewPin('');
                    setRetPinSubStep('login');
                  }}
                  style={styles.backToLoginRow}
                >
                  <Text style={styles.backToLoginText}>← Back to PIN login</Text>
                </TouchableOpacity>
                <Text style={styles.section}>Forgot or locked PIN</Text>
                <Text style={styles.label}>New PIN — you will verify OTP again after reset</Text>
                <TextInput
                  value={resetNewPin}
                  onChangeText={setResetNewPin}
                  keyboardType="number-pad"
                  secureTextEntry
                  placeholder="4–6 digits"
                  style={styles.input}
                />
                <View style={styles.actions}>
                  <Button title="Reset PIN" disabled={loading} onPress={() => void onReturningPinResetAndLogin()} />
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
