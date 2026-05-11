import type { FleetpayQrApiFields } from './fleetpay-qr';
import { getApiBase } from '../storage/session';

/**
 * Driver App auth (aligned with backend):
 * Flow 1 — invite: check-mobile → mobile/send-otp → mobile/verify-otp → invite/validate → invite/set-pin → FO Bearer.
 * Flow 2 — returning: check-mobile → GET /api/v0/otp/login → POST /oauth/token (grant_type=otp) → fo-list → fo-select → FO Bearer.
 * Forgot / reset PIN (same OTP token-1): POST /auth/pin/reset → POST /auth/fo-select with new PIN.
 */

export const DEFAULT_DRIVER_API_BASE = 'https://api-fleet-uat.enkash.in';

export async function resolveDriverApiBase(): Promise<string> {
  const saved = (await getApiBase())?.trim();
  if (saved) return saved.replace(/\/$/, '');
  return DEFAULT_DRIVER_API_BASE;
}

export type CheckMobileStatus = 'NEW_USER' | 'RETURNING_USER';

export type FoListEntry = {
  foCompanyId: number;
  foName: string;
  foStatus: 'ACTIVE' | 'INVITE_PENDING' | 'INACTIVE';
};

export type InviteValidateResult = {
  sessionToken: string;
  driverName: string;
  foName: string;
  foCompanyId: number;
};

export type TokenResponse = {
  accessToken?: string;
  tokenType?: string;
  expiresIn?: number;
  access_token?: string;
  token_type?: string;
  expires_in?: number;
};

export type QrPayResult = {
  serverTxnId: string;
  vehicleRegNo: string;
  amountINR: number;
  newBalanceINR: number;
  authCode?: string;
  txnTime?: string;
};

async function parseJson(res: Response): Promise<unknown> {
  const t = await res.text();
  if (!t) return null;
  try {
    return JSON.parse(t) as unknown;
  } catch {
    return t;
  }
}

function peelFleetEnvelope(raw: unknown): unknown {
  if (!raw || typeof raw !== 'object') return raw;
  const o = raw as Record<string, unknown>;
  if (!('payload' in o) || !('response_message' in o)) return raw;

  if (o.errorResponse != null) {
    const e = o.errorResponse;
    const em =
      typeof e === 'object' && e !== null && 'message' in e
        ? String((e as { message: unknown }).message)
        : typeof e === 'string'
          ? e
          : JSON.stringify(e);
    throw new Error(em || 'Request failed');
  }

  const msg = String(o.response_message ?? '');
  const code = o.response_code;
  if (msg === 'FAILURE') {
    throw new Error('Request failed');
  }
  if (typeof code === 'number' && code >= 400) {
    throw new Error(msg || `Error ${code}`);
  }

  return o.payload;
}

function unwrapIfWrapped<T>(raw: unknown): T {
  const peeled = peelFleetEnvelope(raw);
  if (peeled && typeof peeled === 'object' && 'status' in peeled && 'data' in peeled) {
    const w = peeled as { status: string; data?: unknown; message?: string };
    if (w.status === 'FAILURE') throw new Error(w.message || 'Request failed');
    return (w.data ?? null) as T;
  }
  return peeled as T;
}

function unwrapDriverBody<T>(raw: unknown): T {
  const step = unwrapIfWrapped<unknown>(raw);
  if (
    step !== null &&
    typeof step === 'object' &&
    !Array.isArray(step) &&
    Object.keys(step as object).length === 1 &&
    'data' in step
  ) {
    return (step as { data: T }).data;
  }
  return step as T;
}

function httpErrorMessage(body: unknown, status: number): string {
  if (body && typeof body === 'object') {
    const o = body as Record<string, unknown>;
    if (typeof o.message === 'string') return o.message;
    if (typeof o.error_description === 'string') return o.error_description;
    if (typeof o.error === 'string') return o.error;
  }
  return `HTTP ${status}`;
}

async function fetchJsonOk(
  url: string,
  init?: RequestInit
): Promise<{ res: Response; body: unknown }> {
  const res = await fetch(url, {
    ...init,
    headers: {
      Accept: 'application/json',
      ...init?.headers,
    },
  });
  const body = await parseJson(res);
  if (!res.ok) {
    throw new Error(httpErrorMessage(body, res.status));
  }
  return { res, body };
}

export function oauthAccessToken(t: TokenResponse): string | undefined {
  return t.accessToken ?? t.access_token;
}

export function parseCheckMobileStatus(body: unknown): CheckMobileStatus {
  const cand = unwrapDriverBody<{ status?: unknown }>(body);
  const s =
    cand && typeof cand === 'object' && cand !== null && 'status' in cand
      ? (cand as { status: unknown }).status
      : undefined;
  const out = typeof s === 'string' ? s : undefined;
  if (out !== 'NEW_USER' && out !== 'RETURNING_USER') throw new Error('Unexpected check-mobile response');
  return out;
}

export async function driverCheckMobile(baseUrl: string, mobile: string): Promise<CheckMobileStatus> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/check-mobile`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ mobile }),
  });
  return parseCheckMobileStatus(body);
}

/** Flow 1 — send OTP (no User). */
export async function driverInviteMobileSendOtp(baseUrl: string, mobile: string): Promise<string> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/mobile/send-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ mobile }),
  });
  const data = unwrapDriverBody<string>(body);
  if (typeof data !== 'string' || data.length === 0) throw new Error('Unexpected send-otp response');
  return data;
}

/** Flow 1 — verify OTP → mobileVerificationToken (UUID / opaque). */
export async function driverInviteMobileVerifyOtp(
  baseUrl: string,
  mobile: string,
  otpRefNumber: string,
  otp: string
): Promise<string> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/mobile/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ mobile, otpRefNumber, otp }),
  });
  const data = unwrapDriverBody<{ mobileVerificationToken?: string } | string>(body);
  if (typeof data === 'string' && data.length > 0) return data;
  const tok =
    data && typeof data === 'object' && typeof data.mobileVerificationToken === 'string'
      ? data.mobileVerificationToken
      : undefined;
  if (!tok) throw new Error('Unexpected verify-otp response');
  return tok;
}

export async function driverInviteValidate(
  baseUrl: string,
  mobile: string,
  inviteCode: string,
  mobileVerificationToken: string
): Promise<InviteValidateResult> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/invite/validate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ mobile, inviteCode, mobileVerificationToken }),
  });
  return unwrapDriverBody(body) as InviteValidateResult;
}

export async function driverInviteSetPin(
  baseUrl: string,
  sessionToken: string,
  pin: string
): Promise<TokenResponse> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/invite/set-pin`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionToken, pin }),
  });
  return unwrapDriverBody(body) as TokenResponse;
}

/** Flow 2 — trigger login OTP (User must exist). */
export async function driverSendLoginOtp(baseUrl: string, mobile: string): Promise<void> {
  const q = encodeURIComponent(mobile);
  await fetchJsonOk(`${baseUrl}/api/v0/otp/login?username=${q}`);
}

/** @deprecated Use {@link driverSendLoginOtp}. */
export const driverSendOtp = driverSendLoginOtp;

export async function driverOauthOtpGrant(
  baseUrl: string,
  mobile: string,
  otp: string,
  clientId = 'mgl-driver-app-client',
  clientSecret = 'driver-app-secret'
): Promise<TokenResponse> {
  const form = new URLSearchParams({
    grant_type: 'otp',
    username: mobile.trim(),
    otp: otp.trim(),
    client_id: clientId,
    client_secret: clientSecret,
  });
  const res = await fetch(`${baseUrl.replace(/\/$/, '')}/oauth/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Accept: 'application/json',
    },
    body: form.toString(),
  });
  const parsed = await parseJson(res);
  if (!res.ok) {
    const msg =
      parsed &&
      typeof parsed === 'object' &&
      'error_description' in parsed &&
      typeof (parsed as { error_description: string }).error_description === 'string'
        ? (parsed as { error_description: string }).error_description
        : parsed && typeof parsed === 'object' && 'error' in parsed
          ? String((parsed as { error: unknown }).error)
          : `oauth ${res.status}`;
    throw new Error(msg);
  }
  return parsed as TokenResponse;
}

export async function driverFoList(baseUrl: string, bearerPartial: string): Promise<FoListEntry[]> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/fo-list`, {
    headers: { Authorization: `Bearer ${bearerPartial}` },
  });
  const data = unwrapDriverBody<FoListEntry[]>(body);
  return Array.isArray(data) ? data : [];
}

export async function driverFoSelect(
  baseUrl: string,
  bearerPartial: string,
  foCompanyId: number,
  pin: string
): Promise<TokenResponse> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/fo-select`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${bearerPartial}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ foCompanyId, pin }),
  });
  return unwrapDriverBody(body) as TokenResponse;
}

export async function driverPinReset(
  baseUrl: string,
  bearerPartial: string,
  foCompanyId: number,
  newPin: string
): Promise<string> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/auth/pin/reset`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${bearerPartial}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ foCompanyId, newPin }),
  });
  const data = unwrapDriverBody<string>(body);
  if (typeof data !== 'string') throw new Error('Unexpected pin-reset response');
  return data;
}

function foAuthHeader(bearerFoScoped: string) {
  return { Authorization: `Bearer ${bearerFoScoped}` };
}

export type DriverQrPayPayload = {
  txnId: string;
  vehicleRegNo: string;
  pin: string;
} & FleetpayQrApiFields;

export async function driverQrPay(
  baseUrl: string,
  token: string,
  payload: DriverQrPayPayload
): Promise<QrPayResult> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/qr/pay`, {
    method: 'POST',
    headers: { ...foAuthHeader(token), 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return unwrapDriverBody(body) as QrPayResult;
}
