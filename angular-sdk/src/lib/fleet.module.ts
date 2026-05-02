import { ModuleWithProviders, NgModule } from '@angular/core';
import type { FleetSDKConfig } from '@mgl/fleet-core-sdk';
import { FleetShellModule } from './fleet-shell.module';
import { FleetService } from './fleet.service';
import { FLEET_SDK_CONFIG } from './fleet.tokens';

@NgModule({
  imports: [FleetShellModule],
  exports: [FleetShellModule],
})
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
