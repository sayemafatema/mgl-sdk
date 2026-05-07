import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useState } from 'react';
import { Alert, Button, StyleSheet, Text, TextInput, View } from 'react-native';
import { exchangeOtpForTokenDirect, oauthAccessToken, resolveDriverApiBase } from '../mgl/driver-api';
import { setAccessToken, setApiBase } from '../storage/session';
import type { RootStackParamList } from '../navigation/RootNavigator';

type Props = NativeStackScreenProps<RootStackParamList, 'Login'>;

export default function LoginScreen({ navigation }: Props) {
  const [apiBase, setApiBaseState] = useState<string>('');
  const [mobile, setMobile] = useState<string>('');
  const [otp, setOtp] = useState<string>('');
  const [loading, setLoading] = useState(false);

  async function onLogin() {
    const m = mobile.trim();
    const o = otp.trim();
    if (m.length < 10 || o.length < 4) {
      Alert.alert('Invalid input', 'Enter mobile and OTP.');
      return;
    }

    setLoading(true);
    try {
      const base = (apiBase.trim() || (await resolveDriverApiBase())).replace(/\/$/, '');
      await setApiBase(base);
      const tok = await exchangeOtpForTokenDirect({ apiBase: base, mobile: m, otp: o });
      const access = oauthAccessToken(tok);
      if (!access) throw new Error('Missing access token');
      await setAccessToken(access);
      navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      Alert.alert('Login failed', msg);
    } finally {
      setLoading(false);
    }
  }

  async function onContinueWithoutLogin() {
    // Keeps app usable for UI + scan testing; pay will fail without token.
    const base = (apiBase.trim() || (await resolveDriverApiBase())).replace(/\/$/, '');
    await setApiBase(base);
    await setAccessToken(null);
    navigation.reset({ index: 0, routes: [{ name: 'Home' }] });
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>MGL Driver</Text>

      <Text style={styles.label}>API Base (optional)</Text>
      <TextInput
        value={apiBase}
        onChangeText={setApiBaseState}
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
        autoCorrect={false}
        style={styles.input}
      />

      <Text style={styles.label}>OTP</Text>
      <TextInput
        value={otp}
        onChangeText={setOtp}
        placeholder="1234"
        keyboardType="number-pad"
        autoCapitalize="none"
        autoCorrect={false}
        secureTextEntry
        style={styles.input}
      />

      <View style={styles.actions}>
        <Button title={loading ? 'Logging in…' : 'Login'} disabled={loading} onPress={onLogin} />
      </View>
      <View style={styles.actions}>
        <Button title="Continue without login" disabled={loading} onPress={onContinueWithoutLogin} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, gap: 10, justifyContent: 'center' },
  title: { fontSize: 22, fontWeight: '700', textAlign: 'center', marginBottom: 12 },
  label: { fontSize: 13, fontWeight: '600' },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
  },
  actions: { marginTop: 6 },
});

