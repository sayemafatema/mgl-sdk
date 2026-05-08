import type { FleetpayQrApiFields } from './fleetpay-qr';

/** Driver App API (Phase 2 auth + Phase 3 features).
 *  Per environment: set `NEXT_PUBLIC_DRIVER_API_BASE` (e.g. local `http://localhost:8080`, other UAT/prod hosts).
 *  When unset, defaults to fleet UAT: `https://api-fleet-uat.enkash.in`
 *  Force UI-only/mock: `NEXT_PUBLIC_DRIVER_API_MOCK=true`.
 */

export const DEFAULT_DRIVER_API_BASE = 'https://api-fleet-uat.enkash.in';

export const getDriverApiBase = (): string => {
  if (typeof process === 'undefined') return '';
  if (process.env.NEXT_PUBLIC_DRIVER_API_MOCK === 'true') return '';
  const fromEnv = process.env.NEXT_PUBLIC_DRIVER_API_BASE?.trim();
  if (fromEnv) return fromEnv.replace(/\/$/, '');
  return DEFAULT_DRIVER_API_BASE;
};

export const isDriverApiEnabled = () => getDriverApiBase().length > 0;

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

export type DriverHome = {
  hasActiveVehicle: boolean;
  vehicleRegNo?: string | null;
  vehicleId?: string | null;
  assignmentType?: 'WHOLE_TIME' | 'SHIFT' | 'TRIP' | null;
  isCurrentlyEligible?: boolean;
  totalBalanceINR?: number;
  shiftDaysOfWeek?: string | null;
  shiftStartTime?: string | null;
  shiftEndTime?: string | null;
  tripDate?: string | null;
  tripStartTime?: string | null;
  tripEndTime?: string | null;
  tripStartLocation?: string | null;
};

export type DriverAssignment = {
  vehicleDriverId: number;
  vehicleId: string;
  vehicleRegNo: string;
  assignmentType: 'WHOLE_TIME' | 'SHIFT' | 'TRIP';
  status: 'ACTIVE' | 'PENDING_ACCEPTANCE';
  requiresPairing: boolean;
  shiftDaysOfWeek?: string | null;
  shiftStartTime?: string | null;
  shiftEndTime?: string | null;
  tripDate?: string | null;
  tripStartTime?: string | null;
  tripEndTime?: string | null;
  tripStartLocation?: string | null;
  assignedAt?: string | null;
};

export type DriverProfile = {
  driverId: string;
  name: string;
  maskedMobile: string;
  dlNumber?: string;
  dlExpiryDate?: string;
  addressLine1?: string;
  addressLine2?: string;
  city?: string;
  state?: string;
  pinCode?: string;
  foStatus?: string;
  pinSetAt?: string | null;
};

export type QrPayResult = {
  serverTxnId: string;
  vehicleRegNo: string;
  amountINR: number;
  newBalanceINR: number;
  authCode?: string;
  txnTime?: string;
};

export type DriverTxnRow = {
  serverTxnId: string;
  vehicleRegNo: string;
  amountINR: number;
  status: string;
  driverName: string;
  createdOn: string;
};

/** UI assignment row shape used by demo page (subset of MOCK_BINDINGS). */
export type DriverUiBinding = {
  id: string;
  vrn: string;
  fo: string;
  authMode: 'vehicle_linked' | 'shift_based' | 'trip_linked';
  state: 'ACTIVE' | 'PENDING_ACCEPTANCE';
  paired: boolean;
  scanPayStatus:
    | 'always_available'
    | 'in_window'
    | 'trip_window'
    | 'locked_unpaired'
    | 'locked_repair'
    | 'out_window';
  shiftDays?: string[];
  shiftStart?: string;
  shiftEnd?: string;
  tripDate?: string;
  tripStart?: string;
  tripEnd?: string;
  origin?: string;
  destination?: string;
  assignedBy?: string;
  validPairingCode?: string;
  balance?: number;
  cardBalance?: number;
  incentiveBalance?: number;
  spendLimit?: number;
  assignedAt?: string;
  repairReason?: string;
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

/** Backend envelope (UAT): `{ "payload": ..., "errorResponse": null, "response_code": 200, "response_message": "SUCCESS" }` */
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
    if (w.status === 'FAILURE')
      throw new Error(w.message || 'Request failed');
    return (w.data ?? null) as T;
  }
  return peeled as T;
}

/** Unwrap `{ "data": T }` inside fleet payload (driver-app auth JSON). */
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

export function parseCheckMobileStatus(body: unknown): CheckMobileStatus {
  const cand = unwrapDriverBody<{ status?: unknown }>(body);
  const s =
    cand && typeof cand === 'object' && cand !== null && 'status' in cand
      ? (cand as { status: unknown }).status
      : undefined;
  const out = typeof s === 'string' ? s : undefined;
  if (out !== 'NEW_USER' && out !== 'RETURNING_USER')
    throw new Error('Unexpected check-mobile response');
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

/** Flow 2 — returning driver: GET login OTP (User must exist). */
export async function driverSendLoginOtp(baseUrl: string, mobile: string): Promise<void> {
  const q = encodeURIComponent(mobile);
  await fetchJsonOk(`${baseUrl}/api/v0/otp/login?username=${q}`);
}

/** @deprecated Use {@link driverSendLoginOtp}. */
export const driverSendOtp = driverSendLoginOtp;

/** Flow 1 — new user (no User): rate-limited send; returns otp ref for verify-otp. */
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
  const data = unwrapDriverBody<{ mobileVerificationToken?: string }>(body);
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

/** Flow 2 — exchange login OTP for token-1 (fo-list / fo-select only; not FO-scoped). */
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

export function oauthAccessToken(t: TokenResponse): string | undefined {
  return t.accessToken ?? t.access_token;
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

function foAuthHeader(bearerFoScoped: string) {
  return { Authorization: `Bearer ${bearerFoScoped}` };
}

export async function driverGetHome(baseUrl: string, token: string): Promise<DriverHome> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/home`, {
    headers: foAuthHeader(token),
  });
  return unwrapDriverBody<DriverHome>(body);
}

export async function driverGetBalance(baseUrl: string, token: string): Promise<number> {
  const { res, body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/balance`, {
    headers: foAuthHeader(token),
  });
  if (typeof body === 'number') return body;
  const wrapped = unwrapDriverBody<number>(body);
  if (typeof wrapped === 'number') return wrapped;
  return Number(body);
}

export async function driverGetProfile(baseUrl: string, token: string): Promise<DriverProfile> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/profile`, {
    headers: foAuthHeader(token),
  });
  return unwrapDriverBody(body) as DriverProfile;
}

export async function driverGetAssignments(
  baseUrl: string,
  token: string
): Promise<DriverAssignment[]> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/assignments`, {
    headers: foAuthHeader(token),
  });
  const data = unwrapDriverBody<DriverAssignment[]>(body);
  return Array.isArray(data) ? data : [];
}

export async function driverAcceptPairing(
  baseUrl: string,
  token: string,
  pairingCode: string
): Promise<{ vehicleRegNo: string; status: string }> {
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/vehicle/accept-pairing`, {
    method: 'POST',
    headers: { ...foAuthHeader(token), 'Content-Type': 'application/json' },
    body: JSON.stringify({ pairingCode }),
  });
  return unwrapDriverBody(body) as { vehicleRegNo: string; status: string };
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

export async function driverGetTransactions(
  baseUrl: string,
  token: string,
  page = 0
): Promise<DriverTxnRow[]> {
  const q = page > 0 ? `?page=${page}` : '';
  const { body } = await fetchJsonOk(`${baseUrl}/api/v0/driver-app/transactions${q}`, {
    headers: foAuthHeader(token),
  });
  const data = unwrapDriverBody<DriverTxnRow[]>(body);
  return Array.isArray(data) ? data : [];
}

function normVrn(v: string): string {
  return v.replace(/\s+/g, ' ').trim().toUpperCase();
}

function parseShiftDays(csv: string | null | undefined): string[] | undefined {
  if (!csv) return undefined;
  return csv.split(',').map((d) => {
    const t = d.trim();
    return t.slice(0, 1) + t.slice(1, 3).toLowerCase();
  });
}

function assignmentTypeToAuthMode(t: DriverAssignment['assignmentType']): DriverUiBinding['authMode'] {
  switch (t) {
    case 'WHOLE_TIME':
      return 'vehicle_linked';
    case 'SHIFT':
      return 'shift_based';
    default:
      return 'trip_linked';
  }
}

export function mapAssignmentsToUiBindings(home: DriverHome | null, rows: DriverAssignment[]): DriverUiBinding[] {
  const homeVrn = home?.vehicleRegNo ? normVrn(home.vehicleRegNo) : null;
  return rows.map((a) => {
    const authMode = assignmentTypeToAuthMode(a.assignmentType);
    const vrnKey = normVrn(a.vehicleRegNo);
    const matchesHome = !!(home?.hasActiveVehicle && homeVrn && vrnKey === homeVrn);
    const activeEligible = a.status === 'ACTIVE' && !a.requiresPairing;
    const homeEligible =
      home?.isCurrentlyEligible === true ||
      (home?.isCurrentlyEligible == null && activeEligible);
    const eligible = matchesHome ? homeEligible : activeEligible;

    let scanPayStatus: DriverUiBinding['scanPayStatus'] = 'always_available';

    if (a.status === 'PENDING_ACCEPTANCE' && a.requiresPairing)
      scanPayStatus = 'locked_unpaired';
    else if (!eligible) scanPayStatus = 'out_window';
    else if (a.assignmentType === 'WHOLE_TIME') scanPayStatus = 'always_available';
    else if (a.assignmentType === 'SHIFT') scanPayStatus = 'in_window';
    else scanPayStatus = 'trip_window';

    const shiftDaysParsed = parseShiftDays(a.shiftDaysOfWeek ?? undefined);

    const balance =
      matchesHome && home?.totalBalanceINR != null ? home.totalBalanceINR : undefined;

    return {
      id: String(a.vehicleDriverId),
      vrn: a.vehicleRegNo,
      fo: '',
      authMode,
      state: a.status,
      paired: !(a.status === 'PENDING_ACCEPTANCE' && a.requiresPairing),
      scanPayStatus,
      shiftDays: shiftDaysParsed,
      shiftStart: a.shiftStartTime ?? undefined,
      shiftEnd: a.shiftEndTime ?? undefined,
      tripDate: a.tripDate ?? undefined,
      tripStart: a.tripStartTime ?? undefined,
      tripEnd: a.tripEndTime ?? undefined,
      origin: a.tripStartLocation ?? undefined,
      destination: undefined,
      assignedBy: undefined,
      balance,
      cardBalance: balance ?? 0,
      incentiveBalance: 0,
      assignedAt: a.assignedAt ?? undefined,
    };
  });
}
