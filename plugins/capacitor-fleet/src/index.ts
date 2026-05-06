import { registerPlugin } from '@capacitor/core';
import type { MGLFleetSdkPlugin } from './definitions';

export const MGLFleetSdk = registerPlugin<MGLFleetSdkPlugin>('MGLFleetSdk', {
  web: () => import('./web').then((m) => new m.MGLFleetSdkWeb()),
});

export type {
  FleetSdkInitializeOptions,
  FleetSdkPresentOptions,
  FleetSdkSuccessPayload,
  MGLFleetSdkPlugin,
} from './definitions';
