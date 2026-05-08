import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Alert, Button, Pressable, Share, StyleSheet, Text, View } from 'react-native';
import type { ReceiptRouteParams, RootStackParamList } from '../navigation/RootNavigator';

type Props = NativeStackScreenProps<RootStackParamList, 'Receipt'>;

function shareMessage(p: ReceiptRouteParams): string {
  let t = `Fueling complete\nStation: ${p.stationName}\nVehicle: ${p.vehicleRegNo}\nAmount: ₹${p.amountDisplay}`;
  if (p.serverTxnId) t += `\nTxn: ${p.serverTxnId}`;
  return t;
}

export default function ReceiptScreen({ route, navigation }: Props) {
  const { stationName, vehicleRegNo, amountDisplay } = route.params;

  async function onShare() {
    try {
      const message = shareMessage(route.params);
      await Share.share({ title: 'Fueling complete', message });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      Alert.alert('Share failed', msg);
    }
  }

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <View style={styles.iconWrap}>
          <Text style={styles.icon}>✓</Text>
        </View>
        <Text style={styles.heading}>Fueling Complete</Text>

        <View style={styles.divider} />

        <View style={styles.row}>
          <Text style={styles.rowLabel}>Station</Text>
          <Text style={styles.rowValue}>{stationName}</Text>
        </View>
        <View style={styles.row}>
          <Text style={styles.rowLabel}>Vehicle</Text>
          <Text style={styles.rowValue}>{vehicleRegNo}</Text>
        </View>

        <View style={[styles.row, styles.amountRow]}>
          <Text style={styles.amountLabel}>Amount</Text>
          <Text style={styles.amountValue}>₹{amountDisplay}</Text>
        </View>
      </View>

      <Pressable style={styles.shareBtn} onPress={() => void onShare()}>
        <Text style={styles.shareBtnText}>Share receipt</Text>
      </Pressable>

      <Button title="Done" onPress={() => navigation.popToTop()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, gap: 12, justifyContent: 'center' },
  card: {
    borderWidth: 1,
    borderColor: '#e5e7eb',
    borderRadius: 16,
    padding: 20,
    backgroundColor: '#fff',
    alignItems: 'center',
  },
  iconWrap: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#dcfce7',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  icon: { fontSize: 22, color: '#15803d', fontWeight: '700' },
  heading: { fontSize: 20, fontWeight: '700', color: '#111827', marginBottom: 4 },
  divider: { height: 1, backgroundColor: '#e5e7eb', alignSelf: 'stretch', marginVertical: 16 },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
    alignSelf: 'stretch',
    marginBottom: 10,
  },
  rowLabel: { fontSize: 14, color: '#6b7280' },
  rowValue: { fontSize: 14, fontWeight: '600', color: '#111827', flex: 1, textAlign: 'right' },
  amountRow: {
    marginBottom: 0,
    marginTop: 8,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#e5e7eb',
  },
  amountLabel: { fontSize: 14, fontWeight: '600', color: '#111827' },
  amountValue: { fontSize: 14, fontWeight: '700', color: '#15803d' },
  shareBtn: {
    borderWidth: 2,
    borderColor: '#15803d',
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
  },
  shareBtnText: { fontSize: 16, fontWeight: '600', color: '#15803d' },
});
