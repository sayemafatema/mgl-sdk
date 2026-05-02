import type { DriversApi } from '../api/drivers-api';
import type { FleetEventBus } from '../events/event-bus';
import type { Driver, DriverUpdatePayload } from '../models/driver';
import type { FleetStoreApi } from '../store/fleet-store';

export class DriverService {
  constructor(
    private readonly api: DriversApi | null,
    private readonly store: FleetStoreApi,
    private readonly events: FleetEventBus,
    private readonly useMock: boolean
  ) {}

  async getDrivers(): Promise<Driver[]> {
    if (this.useMock || !this.api) {
      const drivers = this.store.getState().drivers;
      this.events.emit('DRIVERS_REFRESHED', drivers);
      return drivers;
    }
    try {
      const { drivers } = await this.api.list();
      this.store.getState().setDrivers(drivers);
      this.events.emit('DRIVERS_REFRESHED', drivers);
      return drivers;
    } catch (err) {
      this.events.emit('ERROR', err);
      throw err;
    }
  }

  async getDriverDetails(id: string): Promise<Driver> {
    if (this.useMock || !this.api) {
      const found = this.store.getState().drivers.find((d) => d.id === id);
      if (!found) throw new Error(`Driver not found: ${id}`);
      return found;
    }
    try {
      const { driver } = await this.api.get(id);
      this.store.getState().upsertDriver(driver);
      return driver;
    } catch (err) {
      this.events.emit('ERROR', err);
      throw err;
    }
  }

  async updateDriver(data: DriverUpdatePayload): Promise<void> {
    const { id, ...patch } = data;
    if (this.useMock || !this.api) {
      const prev = this.store.getState().drivers.find((d) => d.id === id);
      if (!prev) throw new Error(`Driver not found: ${id}`);
      const next: Driver = {
        ...prev,
        ...patch,
        id,
      };
      this.store.getState().upsertDriver(next);
      this.events.emit('DRIVER_UPDATED', next);
      return;
    }
    try {
      const { driver } = await this.api.update(id, patch);
      this.store.getState().upsertDriver(driver);
      this.events.emit('DRIVER_UPDATED', driver);
    } catch (err) {
      this.events.emit('ERROR', err);
      throw err;
    }
  }
}
