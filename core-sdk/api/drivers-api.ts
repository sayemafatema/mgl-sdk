import type { Driver, DriverUpdatePayload } from '../models/driver';
import { HttpClient } from './http-client';

/** REST shapes aligned with docs/openapi/fleet-api.yaml */
export class DriversApi {
  constructor(private http: HttpClient) {}

  async list(): Promise<{ drivers: Driver[] }> {
    return this.http.request<{ drivers: Driver[] }>('/fleet/drivers');
  }

  async get(id: string): Promise<{ driver: Driver }> {
    return this.http.request<{ driver: Driver }>(`/fleet/drivers/${encodeURIComponent(id)}`);
  }

  async update(id: string, body: Omit<DriverUpdatePayload, 'id'>): Promise<{ driver: Driver }> {
    return this.http.request<{ driver: Driver }>(
      `/fleet/drivers/${encodeURIComponent(id)}`,
      { method: 'PATCH', body: JSON.stringify(body) }
    );
  }
}
