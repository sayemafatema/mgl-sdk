import type {
  Driver,
  FleetBinding,
  FleetDriverProfile,
  FleetTransaction,
  FleetVehicleSummary,
} from '../models/driver';
import {
  MOCK_BINDINGS,
  MOCK_DRIVERS,
  MOCK_FLEET_PROFILE,
  MOCK_TRANSACTIONS,
  MOCK_VEHICLES,
} from '../services/mock-data';

export interface FleetStoreSnapshot {
  drivers: Driver[];
  profile: FleetDriverProfile | null;
  bindings: FleetBinding[];
  vehicles: FleetVehicleSummary[];
  transactions: FleetTransaction[];
}

export interface FleetStore extends FleetStoreSnapshot {
  setDrivers: (drivers: Driver[]) => void;
  upsertDriver: (driver: Driver) => void;
  setProfile: (p: FleetDriverProfile | null) => void;
  setBindings: (b: FleetBinding[]) => void;
  resetDemoState: () => void;
}

function snapshotFromMocks(seed?: Partial<FleetStoreSnapshot>): FleetStoreSnapshot {
  return {
    drivers: [...MOCK_DRIVERS],
    profile: { ...MOCK_FLEET_PROFILE },
    bindings: [...MOCK_BINDINGS],
    vehicles: [...MOCK_VEHICLES],
    transactions: [...MOCK_TRANSACTIONS],
    ...seed,
  };
}

export interface FleetStoreApi {
  getState: () => FleetStore;
  subscribe: (listener: (state: FleetStore) => void) => () => void;
}

/** Vanilla observable store — no framework dependency */
export function createFleetStore(seed?: Partial<FleetStoreSnapshot>): FleetStoreApi {
  const listeners = new Set<(state: FleetStore) => void>();

  const applySnapshot = (snap: FleetStoreSnapshot): void => {
    store.drivers = snap.drivers;
    store.profile = snap.profile;
    store.bindings = snap.bindings;
    store.vehicles = snap.vehicles;
    store.transactions = snap.transactions;
  };

  const notify = (): void => {
    listeners.forEach((l) => l(store));
  };

  const store = {} as FleetStore;
  const initial = snapshotFromMocks(seed);
  applySnapshot(initial);

  store.setDrivers = (drivers) => {
    store.drivers = drivers;
    notify();
  };

  store.upsertDriver = (driver) => {
    const idx = store.drivers.findIndex((d) => d.id === driver.id);
    if (idx >= 0) {
      store.drivers = store.drivers.map((d) => (d.id === driver.id ? driver : d));
    } else {
      store.drivers = [...store.drivers, driver];
    }
    notify();
  };

  store.setProfile = (profile) => {
    store.profile = profile;
    notify();
  };

  store.setBindings = (bindings) => {
    store.bindings = bindings;
    notify();
  };

  store.resetDemoState = () => {
    applySnapshot(snapshotFromMocks());
    notify();
  };

  return {
    getState: () => store,
    subscribe: (listener) => {
      listeners.add(listener);
      listener(store);
      return () => listeners.delete(listener);
    },
  };
}
