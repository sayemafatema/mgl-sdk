import type { FleetSDKConfig } from '../sdk-types';

export class HttpClient {
  constructor(private config: FleetSDKConfig) {}

  setAuthToken(token: string | undefined): void {
    this.config.authToken = token;
  }

  get baseUrl(): string {
    return this.config.apiBaseUrl.replace(/\/$/, '');
  }

  async request<T>(
    path: string,
    init?: RequestInit & { parseJson?: boolean }
  ): Promise<T> {
    const url = `${this.baseUrl}${path.startsWith('/') ? path : `/${path}`}`;
    const headers: HeadersInit = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(init?.headers ?? {}),
    };
    if (this.config.authToken) {
      (headers as Record<string, string>)['Authorization'] =
        `Bearer ${this.config.authToken}`;
    }
    const res = await fetch(url, { ...init, headers });
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new Error(`HTTP ${res.status}: ${text || res.statusText}`);
    }
    if (init?.method === 'HEAD' || res.status === 204) {
      return undefined as T;
    }
    return (await res.json()) as T;
  }
}
