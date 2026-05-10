export type FleetpayQrApiFields = {
  mid: string;
  terminalId: string;
  amountPaise: number;
  expiryEpoch: number;
  sign: string;
};

export type FleetpayQrPayload = FleetpayQrApiFields & {
  txnId: string;
  merchantName?: string;
  currency?: string;
};

export function parseFleetpayPayUri(raw: string): FleetpayQrPayload | null {
  const s = raw.trim();
  if (!/^fleetpay:\/\//i.test(s)) return null;
  let url: URL;
  try {
    url = new URL(s);
  } catch {
    return null;
  }
  const pathNorm = url.pathname.replace(/\/+$/, '').toLowerCase();
  const payPathOk = pathNorm === '' || pathNorm.endsWith('/pay');
  const payHostOk = url.hostname.toLowerCase() === 'pay';
  if (!payHostOk && !payPathOk) return null;
  const txnId = url.searchParams.get('txn') ?? '';
  const mid = url.searchParams.get('mid') ?? '';
  const terminalId = url.searchParams.get('tid') ?? '';
  const am = url.searchParams.get('am');
  const exp = url.searchParams.get('exp');
  const sign = url.searchParams.get('sign') ?? '';
  const mn = url.searchParams.get('mn');

  if (!txnId || !mid || !terminalId || !sign || am == null || exp == null) return null;

  const amountPaise = Number(am);
  const expiryEpoch = Number(exp);
  if (!Number.isFinite(amountPaise) || !Number.isFinite(expiryEpoch)) return null;

  let merchantName: string | undefined;
  if (mn) {
    try {
      merchantName = decodeURIComponent(mn.replace(/\+/g, ' '));
    } catch {
      merchantName = mn;
    }
  }

  return {
    txnId,
    mid,
    terminalId,
    amountPaise,
    expiryEpoch,
    sign,
    merchantName,
    currency: url.searchParams.get('cu') ?? undefined,
  };
}

export function paiseToInrDisplay(amountPaise: number): string {
  return (amountPaise / 100).toLocaleString('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

