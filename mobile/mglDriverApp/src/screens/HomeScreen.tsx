import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useState } from 'react';
import { Alert, Button, StyleSheet, Text, View } from 'react-native';
import type { RootStackParamList } from '../navigation/RootNavigator';
import { getAccessToken, setAccessToken, setFoCompanyId } from '../storage/session';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export default function HomeScreen({ navigation }: Props) {
  const [hasToken, setHasToken] = useState<boolean>(false);

  function timeGreeting(): string {
    const h = new Date().getHours();
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  useEffect(() => {
    void (async () => {
      const t = await getAccessToken();
      setHasToken(Boolean(t));
    })();
  }, []);

  async function onLogout() {
    await setAccessToken(null);
    await setFoCompanyId(null);
    setHasToken(false);
    Alert.alert('Logged out');
  }

  return (
    <View style={styles.container}>
      <Text style={styles.greeting}>{timeGreeting()}</Text>
      <Text style={styles.title}>Driver App</Text>
      <Text style={styles.meta}>{hasToken ? 'Session: ready' : 'Session: not logged in'}</Text>

      <View style={styles.actions}>
        <Button title="Profile & security" onPress={() => navigation.navigate('Profile')} />
      </View>
      <View style={styles.actions}>
        <Button title="Scan & Pay" onPress={() => navigation.navigate('Scan')} />
      </View>
      <View style={styles.actions}>
        <Button
          title="Share receipt (demo)"
          onPress={() =>
            navigation.navigate('Receipt', {
              stationName: 'MGL Hind Station',
              vehicleRegNo: 'MH56SA3453',
              amountDisplay: '672.00',
              serverTxnId: 'DEMO-TXN',
            })
          }
        />
      </View>
      <View style={styles.actions}>
        <Button title="Logout" onPress={onLogout} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, gap: 12, justifyContent: 'center' },
  greeting: { fontSize: 14, textAlign: 'center', color: '#666' },
  title: { fontSize: 22, fontWeight: '700', textAlign: 'center' },
  meta: { fontSize: 14, textAlign: 'center', color: '#666' },
  actions: { marginTop: 6 },
});

