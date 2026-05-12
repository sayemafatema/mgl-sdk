import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useState } from 'react';
import { ActivityIndicator, Alert, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { driverPinReset } from '../mgl/driver-api';
import { useDualPinEntry } from '../../../../components/mgl/driver-pin-flow';
import type { RootStackParamList } from '../navigation/RootNavigator';
import { getAccessToken, getApiBase, getFoCompanyId } from '../storage/session';
import { PinDots, PinNumpad } from '../components/PinEntryUi';

type Props = NativeStackScreenProps<RootStackParamList, 'ChangePin'>;

export default function ChangePinScreen({ navigation }: Props) {
  const pinFlow = useDualPinEntry();
  const [busy, setBusy] = useState(false);

  return (
    <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
      <TouchableOpacity
        accessibilityRole="button"
        disabled={busy}
        onPress={() => {
          pinFlow.phase === 'second' ? pinFlow.goBackToFirst() : navigation.goBack();
        }}
        style={styles.backRow}
      >
        <Text style={styles.backText}>{'← Back'}</Text>
      </TouchableOpacity>

      <Text style={styles.title}>
        {pinFlow.phase === 'first' ? 'Enter New PIN' : 'Confirm New PIN'}
      </Text>
      <Text style={styles.sub}>
        {pinFlow.phase === 'first'
          ? 'Numeric 6-digit PIN only.'
          : 'Re-enter the same PIN.'}
      </Text>

      <PinDots filled={pinFlow.activeValue.length} />
      <PinNumpad
        disabled={busy}
        onDigit={pinFlow.appendDigit}
        onBackspace={pinFlow.backspace}
      />

      {pinFlow.error ? <Text style={styles.err}>{pinFlow.error}</Text> : null}

      <TouchableOpacity
        accessibilityRole="button"
        disabled={
          busy ||
          (pinFlow.phase === 'first' ? pinFlow.pinFirst.length !== 6 : pinFlow.pinSecond.length !== 6)
        }
        style={[
          styles.primaryBtn,
          (busy ||
            (pinFlow.phase === 'first' ? pinFlow.pinFirst.length !== 6 : pinFlow.pinSecond.length !== 6)) &&
            styles.primaryBtnDisabled,
        ]}
        onPress={() => {
          if (busy) return;
          if (pinFlow.phase === 'first') {
            pinFlow.goToConfirmStep();
            return;
          }
          const matched = pinFlow.tryFinish();
          if (!matched) return;
          void (async () => {
            const token = await getAccessToken();
            const rawBase = (await getApiBase())?.trim();
            const foCompanyId = await getFoCompanyId();
            if (!token) {
              Alert.alert('Not signed in', 'Log in before changing PIN.');
              return;
            }
            if (!rawBase) {
              Alert.alert('API base missing', 'Set API base from the Login screen.');
              return;
            }
            if (foCompanyId == null) {
              Alert.alert('Fleet ID missing', 'Sign out and sign in again so your fleet can be saved.');
              return;
            }
            const base = rawBase.replace(/\/$/, '');
            setBusy(true);
            try {
              await driverPinReset(base, token, foCompanyId, matched);
              pinFlow.resetFlow();
              Alert.alert('PIN changed successfully', '', [
                { text: 'OK', onPress: () => navigation.navigate('Profile') },
              ]);
            } catch (e) {
              Alert.alert(
                'Could not change PIN',
                e instanceof Error ? e.message : String(e)
              );
            } finally {
              setBusy(false);
            }
          })();
        }}
      >
        {busy ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.primaryBtnText}>
            {pinFlow.phase === 'first' ? 'Confirm PIN' : 'Change PIN'}
          </Text>
        )}
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 16, paddingBottom: 40 },
  backRow: { marginBottom: 16, paddingVertical: 6 },
  backText: { fontSize: 15, fontWeight: '600', color: '#616161' },
  title: { fontSize: 20, fontWeight: '700', color: '#111' },
  sub: { fontSize: 14, color: '#666', marginTop: 8, marginBottom: 4 },
  err: {
    marginTop: 14,
    textAlign: 'center',
    fontSize: 13,
    color: '#c62828',
    fontWeight: '600',
  },
  primaryBtn: {
    marginTop: 24,
    backgroundColor: '#2e7d32',
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
  },
  primaryBtnDisabled: { backgroundColor: '#bdbdbd' },
  primaryBtnText: { color: '#fff', fontSize: 16, fontWeight: '700' },
});
