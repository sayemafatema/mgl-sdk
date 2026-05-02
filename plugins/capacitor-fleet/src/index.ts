import { registerPlugin } from '@capacitor/core';
import type { MGLFleetSdkPlugin } from './definitions';

export const MGLFleetSdk = registerPlugin<MGLFleetSdkPlugin>('MGLFleetSdk');

export type {
  FleetSdkInitializeOptions,
  FleetSdkPresentOptions,
  FleetSdkSuccessPayload,
  MGLFleetSdkPlugin,
} from './definitions';
