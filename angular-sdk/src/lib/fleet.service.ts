import { Inject, Injectable, Optional } from '@angular/core';
import {
  FleetSDK,
  type Driver,
  type DriverUpdatePayload,
  type FleetSDKConfig,
} from '@mgl/fleet-core-sdk';
import { Observable, defer, from } from 'rxjs';
import { FLEET_SDK_CONFIG } from './fleet.tokens';

@Injectable()
export class FleetService {
  private readonly sdk: FleetSDK;

  constructor(@Optional() @Inject(FLEET_SDK_CONFIG) config: FleetSDKConfig | null) {
    const resolved = config ?? { apiBaseUrl: 'https://api.example.com', useMock: true };
    this.sdk = new FleetSDK(resolved);
  }

  /** Access headless SDK for events / store subscriptions */
  raw(): FleetSDK {
    return this.sdk;
  }

  setAuthToken(token: string | undefined): void {
    this.sdk.setAuthToken(token);
  }

  getDrivers(): Observable<Driver[]> {
    return defer(() => from(this.sdk.getDrivers()));
  }

  getDriverDetails(id: string): Observable<Driver> {
    return defer(() => from(this.sdk.getDriverDetails(id)));
  }

  updateDriver(data: DriverUpdatePayload): Observable<void> {
    return defer(() => from(this.sdk.updateDriver(data)));
  }
}
