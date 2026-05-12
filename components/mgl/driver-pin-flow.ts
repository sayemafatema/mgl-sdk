import { useCallback, useState } from 'react';

export const DRIVER_APP_PIN_LENGTH = 6 as const;

export const PIN_VALIDATION_NEED_SIX_DIGITS = 'PIN must be 6 digits';

export const PIN_VALIDATION_MISMATCH = 'PINs do not match';

export type DualPinPhase = 'first' | 'second';

/** Keeps numeric-only PIN; caps at DRIVER_APP_PIN_LENGTH. */
export function appendDriverPin(current: string, rawDigit: string): string {
  const d = rawDigit.replace(/\D/g, '');
  const ch = d.length ? d[d.length - 1] ?? '' : '';
  if (!/^\d$/.test(ch)) return current;
  if (current.length >= DRIVER_APP_PIN_LENGTH) return current;
  return current + ch;
}

export function validateCompleteSixDigit(pin: string): string | null {
  const p = pin.replace(/\D/g, '').slice(0, DRIVER_APP_PIN_LENGTH);
  if (p.length === 0) return PIN_VALIDATION_NEED_SIX_DIGITS;
  if (p.length !== DRIVER_APP_PIN_LENGTH) return PIN_VALIDATION_NEED_SIX_DIGITS;
  return null;
}

export function pinsMatch(pinA: string, pinB: string): boolean {
  return pinA.length === DRIVER_APP_PIN_LENGTH && pinB.length === DRIVER_APP_PIN_LENGTH && pinA === pinB;
}

export type UseDualPinEntryResult = {
  phase: DualPinPhase;
  pinFirst: string;
  pinSecond: string;
  activeValue: string;
  error: string | null;
  appendDigit: (digit: string) => void;
  backspace: () => void;
  goToConfirmStep: () => boolean;
  goBackToFirst: () => void;
  tryFinish: () => string | null;
  resetFlow: () => void;
};

export function useDualPinEntry(): UseDualPinEntryResult {
  const [phase, setPhase] = useState<DualPinPhase>('first');
  const [pinFirst, setPinFirst] = useState('');
  const [pinSecond, setPinSecond] = useState('');
  const [error, setError] = useState<string | null>(null);

  const resetFlow = useCallback(() => {
    setPhase('first');
    setPinFirst('');
    setPinSecond('');
    setError(null);
  }, []);

  const appendDigit = useCallback(
    (digit: string) => {
      setError(null);
      if (phase === 'first') {
        setPinFirst((prev) => appendDriverPin(prev, digit));
      } else {
        setPinSecond((prev) => appendDriverPin(prev, digit));
      }
    },
    [phase]
  );

  const backspace = useCallback(() => {
    setError(null);
    if (phase === 'first') {
      setPinFirst((prev) => prev.slice(0, -1));
    } else {
      setPinSecond((prev) => prev.slice(0, -1));
    }
  }, [phase]);

  const goToConfirmStep = useCallback(() => {
    const msg = validateCompleteSixDigit(pinFirst);
    if (msg != null) {
      setError(msg);
      return false;
    }
    setPinSecond('');
    setPhase('second');
    setError(null);
    return true;
  }, [pinFirst]);

  const goBackToFirst = useCallback(() => {
    setPhase('first');
    setPinSecond('');
    setError(null);
  }, []);

  const tryFinish = useCallback(() => {
    const m1 = validateCompleteSixDigit(pinFirst);
    if (m1 != null) {
      setError(m1);
      return null;
    }
    const m2 = validateCompleteSixDigit(pinSecond);
    if (m2 != null) {
      setError(m2);
      return null;
    }
    if (!pinsMatch(pinFirst, pinSecond)) {
      setError(PIN_VALIDATION_MISMATCH);
      setPinSecond('');
      return null;
    }
    setError(null);
    return pinFirst;
  }, [pinFirst, pinSecond]);

  const activeValue = phase === 'first' ? pinFirst : pinSecond;

  return {
    phase,
    pinFirst,
    pinSecond,
    activeValue,
    error,
    appendDigit,
    backspace,
    goToConfirmStep,
    goBackToFirst,
    tryFinish,
    resetFlow,
  };
}
