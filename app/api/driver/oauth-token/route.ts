import { NextResponse } from 'next/server';

const CID = process.env.DRIVER_OAUTH_CLIENT_ID ?? 'mgl-driver-app-client';
const SECRET = process.env.DRIVER_OAUTH_CLIENT_SECRET ?? 'driver-app-secret';

/** Proxies Flow-2 `POST /oauth/token` with `grant_type=otp` (optional CORS workaround). */
export async function POST(req: Request) {
  try {
    const body = (await req.json()) as { mobile?: string; otp?: string; apiBase?: string };
    const mobile = typeof body.mobile === 'string' ? body.mobile.trim() : '';
    const otp = typeof body.otp === 'string' ? body.otp.trim() : '';
    const apiBase =
      typeof body.apiBase === 'string' ? body.apiBase.trim().replace(/\/$/, '') : '';

    if (mobile.length < 10 || otp.length < 4 || !apiBase) {
      return NextResponse.json({ error: 'mobile, otp, and apiBase required' }, { status: 400 });
    }

    const params = new URLSearchParams({
      grant_type: 'otp',
      username: mobile,
      otp,
      client_id: CID,
      client_secret: SECRET,
    });

    const res = await fetch(`${apiBase}/oauth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
      },
      body: params.toString(),
    });

    const txt = await res.text();
    let parsed: unknown;
    try {
      parsed = txt ? JSON.parse(txt) : null;
    } catch {
      parsed = { raw: txt };
    }

    if (!res.ok) {
      const msg =
        parsed &&
        typeof parsed === 'object' &&
        'error_description' in parsed &&
        typeof (parsed as { error_description: string }).error_description === 'string'
          ? (parsed as { error_description: string }).error_description
          : txt || `oauth ${res.status}`;
      return NextResponse.json({ error: msg }, { status: res.status });
    }

    return NextResponse.json(parsed);
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'oauth proxy failed';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
