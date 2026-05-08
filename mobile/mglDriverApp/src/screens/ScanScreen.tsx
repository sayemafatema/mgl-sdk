import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useEffect, useState } from 'react';
import { Alert, Button, PermissionsAndroid, Platform, StyleSheet, Text, TextInput, View } from 'react-native';
import CameraScreen from 'react-native-camera-kit';
import type { RootStackParamList } from '../navigation/RootNavigator';
import { resolveDriverApiBase, driverQrPay } from '../mgl/driver-api';
import { parseFleetpayPayUri, paiseToInrDisplay } from '../mgl/fleetpay-qr';
import { getAccessToken } from '../storage/session';

type Props = NativeStackScreenProps<RootStackParamList, 'Scan'>;

export default function ScanScreen({ navigation }: Props) {
  const [vehicleRegNo, setVehicleRegNo] = useState('');
  const [pin, setPin] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void (async () => {
      if (Platform.OS !== 'android') return;
      const granted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.CAMERA);
      if (granted !== PermissionsAndroid.RESULTS.GRANTED) {
        Alert.alert('Camera permission required', 'Enable camera permission to scan QR codes.');
      }
    })();
  }, []);

  const onReadCode = useCallback(
    async (event: { nativeEvent: { codeStringValue?: string } }) => {
      const raw = event?.nativeEvent?.codeStringValue?.trim();
      if (!raw || busy) return;

      const parsed = parseFleetpayPayUri(raw);
      if (!parsed) {
        Alert.alert('Invalid QR', 'Unsupported QR payload.');
        return;
      }

      const vrn = vehicleRegNo.trim();
      const p = pin.trim();
      if (!vrn || p.length < 4) {
        Alert.alert('Missing details', 'Enter vehicle number and PIN before scanning.');
        return;
      }

      setBusy(true);
      try {
        const token = await getAccessToken();
        if (!token) {
          throw new Error('Not logged in. Please login to pay.');
        }
        const baseUrl = await resolveDriverApiBase();
        const res = await driverQrPay(baseUrl, token, {
          txnId: parsed.txnId,
          mid: parsed.mid,
          terminalId: parsed.terminalId,
          amountPaise: parsed.amountPaise,
          expiryEpoch: parsed.expiryEpoch,
          sign: parsed.sign,
          vehicleRegNo: vrn,
          pin: p,
        });

        navigation.replace('Receipt', {
          stationName: parsed.merchantName ?? '—',
          vehicleRegNo: vrn,
          amountDisplay: paiseToInrDisplay(parsed.amountPaise),
          serverTxnId: res.serverTxnId,
        });
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        Alert.alert('Pay failed', msg);
      } finally {
        setBusy(false);
      }
    },
    [busy, navigation, pin, vehicleRegNo]
  );

  return (
    <View style={styles.container}>
      <View style={styles.form}>
        <Text style={styles.label}>Vehicle Reg No</Text>
        <TextInput
          value={vehicleRegNo}
          onChangeText={setVehicleRegNo}
          placeholder="MH01AB1234"
          autoCapitalize="characters"
          autoCorrect={false}
          style={styles.input}
        />

        <Text style={styles.label}>PIN</Text>
        <TextInput
          value={pin}
          onChangeText={setPin}
          placeholder="****"
          keyboardType="number-pad"
          secureTextEntry
          style={styles.input}
        />

        <View style={styles.row}>
          <Button title="Cancel" onPress={() => navigation.goBack()} />
          <View style={{ width: 10 }} />
          <Button title={busy ? 'Processing…' : 'Ready'} disabled />
        </View>

        <Text style={styles.hint}>
          Scan a `fleetpay://...` QR. Amount is read from QR ({paiseToInrDisplay(12345)} example).
        </Text>
      </View>

      <View style={styles.cameraWrap}>
        <CameraScreen
          scanBarcode
          onReadCode={onReadCode}
          showFrame
          laserColor="rgba(0,255,0,0.6)"
          frameColor="rgba(255,255,255,0.5)"
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  form: { padding: 16, gap: 8 },
  label: { fontSize: 13, fontWeight: '600' },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
  },
  row: { flexDirection: 'row', alignItems: 'center', marginTop: 4 },
  hint: { fontSize: 12, color: '#666', marginTop: 6 },
  cameraWrap: { flex: 1, overflow: 'hidden' },
});

