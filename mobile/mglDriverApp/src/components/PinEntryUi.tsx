import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';

export function PinDots({ filled }: { filled: number }) {
  return (
    <View style={styles.dots}>
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <View key={String(i)} style={[styles.dot, i < filled ? styles.dotFilled : styles.dotEmpty]} />
      ))}
    </View>
  );
}

export function PinNumpad(props: {
  onDigit: (d: string) => void;
  onBackspace: () => void;
  disabled?: boolean;
}) {
  const { onDigit, onBackspace, disabled } = props;
  return (
    <View style={styles.pad}>
      {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => (
        <TouchableOpacity
          key={String(n)}
          disabled={disabled}
          style={[styles.key, disabled && styles.keyDisabled]}
          onPress={() => onDigit(String(n))}
        >
          <Text style={styles.keyText}>{n}</Text>
        </TouchableOpacity>
      ))}
      <TouchableOpacity
        disabled={disabled}
        style={[styles.keyWide, disabled && styles.keyDisabled]}
        onPress={onBackspace}
      >
        <Text style={[styles.keyText, styles.backTxt]}>{' ← '}</Text>
      </TouchableOpacity>
      <TouchableOpacity
        disabled={disabled}
        style={[styles.key, disabled && styles.keyDisabled]}
        onPress={() => onDigit('0')}
      >
        <Text style={styles.keyText}>0</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  dots: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
    marginVertical: 22,
  },
  dot: { width: 14, height: 14, borderRadius: 7, borderWidth: 2 },
  dotEmpty: { borderColor: '#ccc', backgroundColor: '#fff' },
  dotFilled: { borderColor: '#2e7d32', backgroundColor: '#2e7d32' },
  pad: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    justifyContent: 'center',
    marginTop: 8,
  },
  key: {
    width: '28%',
    maxWidth: 96,
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 10,
    backgroundColor: '#f0f0f0',
  },
  keyWide: {
    width: '59%',
    maxWidth: 208,
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 10,
    backgroundColor: '#fce4e4',
  },
  keyDisabled: { opacity: 0.35 },
  keyText: { fontSize: 20, fontWeight: '700', color: '#222' },
  backTxt: { color: '#b71c1c' },
});
