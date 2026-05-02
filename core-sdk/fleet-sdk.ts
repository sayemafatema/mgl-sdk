import { DriversApi } from './api/drivers-api';
import { HttpClient } from './api/http-client';
import { FleetEventBus } from './events/event-bus';
import type { Driver, DriverUpdatePayload } from './models';
import { FleetAppEngine } from './services/fleet-app-engine';
import { DriverService } from './services/driver-service';
import type { FleetSDKConfig } from './sdk-types';
import type { FleetStore, FleetStoreSnapshot } from './store/fleet-store';
import { createFleetStore } from './store/fleet-store';

export class FleetSDK {
  private readonly http: HttpClient;
  private readonly events = new FleetEventBus();
  private readonly store = createFleetStore();
  private readonly driversApi: DriversApi | null;
  private readonly drivers: DriverService;
  private readonly _appFlow = new FleetAppEngine();

  constructor(private readonly config: FleetSDKConfig) {
    this.http = new HttpClient(config);
    const useMock = config.useMock ?? true;
    this.driversApi = useMock ? null : new DriversApi(this.http);
    this.drivers = new DriverService(
      this.driversApi,
      this.store,
      this.events,
      useMock
    );
  }

  /**
   * Full end-to-end driver-app flow state (login / invite / PIN / tabs / scan),
   * matching the original React demo — no per-screen host wiring.
   */
  get appFlow(): FleetAppEngine {
    return this._appFlow;
  }

  setAuthToken(token: string | undefined): void {
    this.config.authToken = token;
    this.http.setAuthToken(token);
    this.events.emit('SESSION_READY', { authenticated: Boolean(token) });
  }

  async getDrivers(): Promise<Driver[]> {
    return this.drivers.getDrivers();
  }

  async getDriverDetails(id: string): Promise<Driver> {
    return this.drivers.getDriverDetails(id);
  }

  async updateDriver(data: DriverUpdatePayload): Promise<void> {
    return this.drivers.updateDriver(data);
  }

  on(event: string, callback: (payload: unknown) => void): void {
    this.events.on(event, callback);
  }

  emit(event: string, payload?: unknown): void {
    this.events.emit(event, payload);
  }

  subscribe(listener: (state: FleetStore) => void): () => void {
    return this.store.subscribe(listener);
  }

  getSnapshot(): FleetStoreSnapshot {
    const s = this.store.getState();
    return {
      drivers: s.drivers,
      profile: s.profile,
      bindings: s.bindings,
      vehicles: s.vehicles,
      transactions: s.transactions,
    };
  }

  getStore() {
    return this.store;
  }
}

export type { FleetSDKConfig } from './sdk-types';
