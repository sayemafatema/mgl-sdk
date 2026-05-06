import { WebPlugin } from '@capacitor/core';
import type {
  FleetSdkInitializeOptions,
  FleetSdkPresentOptions,
  FleetSdkSuccessPayload,
  MGLFleetSdkPlugin,
} from './definitions';

export class MGLFleetSdkWeb extends WebPlugin implements MGLFleetSdkPlugin {
  async initialize(_options: FleetSdkInitializeOptions): Promise<void> {
    /* Web has no native core; callers should guard with Capacitor.isNativePlatform(). */
  }

  async presentFleetFlow(_options?: FleetSdkPresentOptions): Promise<FleetSdkSuccessPayload> {
    throw this.unavailable(
      'MGL Fleet flow is available on iOS and Android only.',
    );
  }
}
