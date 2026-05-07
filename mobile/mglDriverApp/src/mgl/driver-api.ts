import type { FleetpayQrApiFields } from './fleetpay-qr';
import { getApiBase } from '../storage/session';
import { encode as b64encode } from 'base-64';

export const DEFAULT_DRIVER_API_BASE = 'https://api-fleet-uat.enkash.in';

export async function resolveDriverApiBase(): Promise<string> {
  const saved = (await getApiBase())?.trim();
  if (saved) return saved.replace(/\/$/, '');
  return DEFAULT_DRIVER_API_BASE;
}

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

async function fetchJsonOk<T>(
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
    const msg =
      body && typeof body === 'object' && 'message' in body && typeof (body as { message: string }).message === 'string'
        ? (body as { message: string }).message
        : `HTTP ${res.status}`;
    throw new Error(msg);
  }
  return { res, body };
}

export function oauthAccessToken(t: TokenResponse): string | undefined {
  return t.accessToken ?? t.access_token;
}

export async function exchangeOtpForTokenDirect(params: {
  apiBase: string;
  mobile: string;
  otp: string;
  clientId?: string;
  clientSecret?: string;
}): Promise<TokenResponse> {
  const CID = params.clientId ?? 'mgl-driver-app-client';
  const SECRET = params.clientSecret ?? 'driver-app-secret';
  const basic = b64encode(`${CID}:${SECRET}`);

  const body = new URLSearchParams({
    grant_type: 'password',
    username: params.mobile,
    password: params.otp,
    client_id: CID,
    client_secret: SECRET,
    scope: 'read write',
  }).toString();

  const res = await fetch(`${params.apiBase.replace(/\/$/, '')}/oauth/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${basic}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      Accept: 'application/json',
    },
    body,
  });
  const parsed = await parseJson(res);
  if (!res.ok) {
    const msg =
      parsed &&
      typeof parsed === 'object' &&
      'error_description' in parsed &&
      typeof (parsed as { error_description: string }).error_description === 'string'
        ? (parsed as { error_description: string }).error_description
        : `oauth ${res.status}`;
    throw new Error(msg);
  }
  return parsed as TokenResponse;
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
  return unwrapIfWrapped(body) as QrPayResult;
}

