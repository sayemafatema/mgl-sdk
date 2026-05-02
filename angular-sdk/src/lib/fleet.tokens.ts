import { InjectionToken } from '@angular/core';
import type { FleetSDKConfig } from '@mgl/fleet-core-sdk';

export const FLEET_SDK_CONFIG = new InjectionToken<FleetSDKConfig>('FLEET_SDK_CONFIG');
