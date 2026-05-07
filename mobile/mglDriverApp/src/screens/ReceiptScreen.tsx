import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Button, Share, StyleSheet, Text, View } from 'react-native';
import type { RootStackParamList } from '../navigation/RootNavigator';

type Props = NativeStackScreenProps<RootStackParamList, 'Receipt'>;

export default function ReceiptScreen({ route, navigation }: Props) {
  const { receiptText } = route.params;

  async function onShare() {
    await Share.share({ message: receiptText });
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Receipt</Text>
      <View style={styles.card}>
        <Text style={styles.text}>{receiptText}</Text>
      </View>
      <View style={styles.actions}>
        <Button title="Share receipt" onPress={onShare} />
      </View>
      <View style={styles.actions}>
        <Button title="Back to Home" onPress={() => navigation.popToTop()} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, gap: 12, justifyContent: 'center' },
  title: { fontSize: 22, fontWeight: '700', textAlign: 'center' },
  card: { borderWidth: 1, borderColor: '#eee', borderRadius: 12, padding: 14, backgroundColor: '#fff' },
  text: { fontSize: 14, lineHeight: 20 },
  actions: { marginTop: 6 },
});

