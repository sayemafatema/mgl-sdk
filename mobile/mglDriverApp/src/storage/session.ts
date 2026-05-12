import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY_ACCESS_TOKEN = 'mgl.session.accessToken';
const KEY_API_BASE = 'mgl.session.apiBase';
const KEY_FO_COMPANY_ID = 'mgl.session.foCompanyId';

export async function getAccessToken(): Promise<string | null> {
  return AsyncStorage.getItem(KEY_ACCESS_TOKEN);
}

export async function setAccessToken(token: string | null): Promise<void> {
  if (!token) {
    await AsyncStorage.removeItem(KEY_ACCESS_TOKEN);
    return;
  }
  await AsyncStorage.setItem(KEY_ACCESS_TOKEN, token);
}

export async function getApiBase(): Promise<string | null> {
  return AsyncStorage.getItem(KEY_API_BASE);
}

export async function setApiBase(apiBase: string | null): Promise<void> {
  if (!apiBase) {
    await AsyncStorage.removeItem(KEY_API_BASE);
    return;
  }
  await AsyncStorage.setItem(KEY_API_BASE, apiBase);
}

export async function getFoCompanyId(): Promise<number | null> {
  const raw = await AsyncStorage.getItem(KEY_FO_COMPANY_ID);
  if (raw == null || !raw.trim()) return null;
  const n = parseInt(raw, 10);
  return Number.isFinite(n) ? n : null;
}

export async function setFoCompanyId(id: number | null): Promise<void> {
  if (id == null) {
    await AsyncStorage.removeItem(KEY_FO_COMPANY_ID);
    return;
  }
  await AsyncStorage.setItem(KEY_FO_COMPANY_ID, String(id));
}
