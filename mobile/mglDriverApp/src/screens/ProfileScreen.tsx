import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import type { RootStackParamList } from '../navigation/RootNavigator';
import { getAccessToken } from '../storage/session';
import { useEffect, useState } from 'react';

type Props = NativeStackScreenProps<RootStackParamList, 'Profile'>;

export default function ProfileScreen({ navigation }: Props) {
  const [hasSession, setHasSession] = useState(false);

  useEffect(() => {
    void (async () => {
      const t = await getAccessToken();
      setHasSession(Boolean(t));
    })();
  }, []);

  return (
    <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
      <View style={styles.header}>
        <Text style={styles.name}>Driver</Text>
        <Text style={styles.sub}>Fleet driver</Text>
      </View>

      <Text style={styles.sectionLabel}>Security</Text>
      <View style={styles.card}>
        <TouchableOpacity
          style={styles.row}
          disabled={!hasSession}
          onPress={() => navigation.navigate('ChangePin')}
          accessibilityRole="button"
        >
          <Text style={styles.rowText}>Change PIN</Text>
          <Text style={styles.chev}>›</Text>
        </TouchableOpacity>
        {/* Registered device — placeholder for future device binding
        <View style={styles.divider} />
        <TouchableOpacity
          style={styles.row}
          onPress={() => Alert.alert('Registered device', 'This session is bound to the device you used to sign in.')}
          accessibilityRole="button"
        >
          <Text style={styles.rowText}>Registered device</Text>
          <Text style={styles.chev}>›</Text>
        </TouchableOpacity>
        */}
      </View>

      {!hasSession ? (
        <Text style={styles.warn}>Sign in to change PIN.</Text>
      ) : null}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 16, paddingBottom: 32 },
  header: {
    backgroundColor: '#1b3022',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  name: { color: '#fff', fontSize: 20, fontWeight: '700' },
  sub: { color: '#c8e6c9', marginTop: 6, fontSize: 13 },
  sectionLabel: {
    marginBottom: 8,
    paddingHorizontal: 2,
    fontSize: 11,
    fontWeight: '600',
    letterSpacing: 0.8,
    color: '#9e9e9e',
    textTransform: 'uppercase',
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#e0e0e0',
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
    minHeight: 48,
  },
  rowText: { fontSize: 15, color: '#222' },
  chev: { fontSize: 22, color: '#bdbdbd', fontWeight: '300' },
  divider: {
    marginLeft: 16,
    height: StyleSheet.hairlineWidth,
    backgroundColor: '#eee',
  },
  warn: { marginTop: 12, fontSize: 13, color: '#c62828' },
});
