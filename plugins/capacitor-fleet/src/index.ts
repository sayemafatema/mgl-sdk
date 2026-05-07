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

  const init = normalizeInitializeOptions(options.initialize);

  try {
    await MGLFleetSdk.initialize(init);
    const result = await MGLFleetSdk.presentFleetFlow(options.present ?? {});
    return result;
  } catch (err) {
    console.error('[@mgl/capacitor-fleet-sdk] Fleet flow failed:', err);
    throw err;
  }
}

/** Host apps often pass `environment.base_url` which may be unset — native requires a non-empty string. */
function normalizeInitializeOptions(
  opts: FleetSdkInitializeOptions,
): FleetSdkInitializeOptions {
  let apiBaseUrl =
    typeof opts.apiBaseUrl === 'string' ? opts.apiBaseUrl.trim() : '';
  const useMock = opts.useMock !== false;
  if (!apiBaseUrl) {
    if (useMock) {
      apiBaseUrl = 'https://mock.fleet.local';
      console.warn(
        '[@mgl/capacitor-fleet-sdk] initialize.apiBaseUrl was empty — using placeholder for mock mode. Set apiBaseUrl in environment.',
      );
    } else {
      throw new Error(
        '[@mgl/capacitor-fleet-sdk] initialize.apiBaseUrl is required when useMock is false.',
      );
    }
  }
  return { ...opts, apiBaseUrl };
}

export type {
  FleetSdkInitializeOptions,
  FleetSdkPresentOptions,
  FleetSdkSuccessPayload,
  MGLFleetSdkPlugin,
} from './definitions';
