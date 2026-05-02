import { ModuleWithProviders, NgModule } from '@angular/core';
import type { FleetSDKConfig } from '@mgl/fleet-core-sdk';
import { FleetService } from './fleet.service';
import { FLEET_SDK_CONFIG } from './fleet.tokens';

/** Legacy NgModule bootstrap — prefer `initFleetNativeSdk` + standalone `provideRouter`. Shell stays lazy-loaded. */
@NgModule({})
export class FleetModule {
  static forRoot(config: FleetSDKConfig): ModuleWithProviders<FleetModule> {
    return {
      ngModule: FleetModule,
      providers: [
        { provide: FLEET_SDK_CONFIG, useValue: config },
        FleetService,
      ],
    };
  }
}
