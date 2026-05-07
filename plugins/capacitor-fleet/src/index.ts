import { Capacitor, registerPlugin } from '@capacitor/core';
import type {
  FleetSdkInitializeOptions,
  FleetSdkPresentOptions,
  FleetSdkSuccessPayload,
  MGLFleetSdkPlugin,
} from './definitions';

export const MGLFleetSdk = registerPlugin<MGLFleetSdkPlugin>('MGLFleetSdk', {
  web: () => import('./web').then((m) => new m.MGLFleetSdkWeb()),
});

/** Use this from the host app (e.g. button click) so `initialize` always runs before `presentFleetFlow`. */
export interface OpenMglFleetNativeFlowOptions {
  initialize: FleetSdkInitializeOptions;
  present?: FleetSdkPresentOptions;
}

/**
 * Opens the native Fleet fullscreen flow. No-op on web (logs a warning).
 * Always calls {@link MGLFleetSdk.initialize} first — required by the native SDK.
 */
export async function openMglFleetNativeFlow(
  options: OpenMglFleetNativeFlowOptions,
): Promise<FleetSdkSuccessPayload | null> {
  if (!Capacitor.isNativePlatform()) {
    console.warn(
      '[@mgl/capacitor-fleet-sdk] Fleet runs on a device/emulator only (not `ng serve` / browser). Platform:',
      Capacitor.getPlatform(),
    );
    return null;
  }
  await MGLFleetSdk.initialize(options.initialize);
  return MGLFleetSdk.presentFleetFlow(options.present ?? {});
}

export type {
  FleetSdkInitializeOptions,
  FleetSdkPresentOptions,
  FleetSdkSuccessPayload,
  MGLFleetSdkPlugin,
} from './definitions';
