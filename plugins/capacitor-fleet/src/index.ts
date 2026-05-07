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
 * Opens the native Fleet fullscreen flow.
 * Throws on web / plain `ng serve` so hosts can catch and show UI (silent null made bugs hard to spot).
 */
export async function openMglFleetNativeFlow(
  options: OpenMglFleetNativeFlowOptions,
): Promise<FleetSdkSuccessPayload> {
  const platform = Capacitor.getPlatform();

  if (!Capacitor.isNativePlatform()) {
    const msg = `[@mgl/capacitor-fleet-sdk] Fleet runs only inside the native app shell (Android/iOS), not when opening the SPA in Chrome or ng serve-only. Platform: "${platform}". Use: npx cap run android — or npx cap run ios`;
    console.error(msg);
    throw new Error(msg);
  }

  const init = normalizeInitializeOptions(options.initialize);

  console.info('[MGL Fleet] Opening native flow, platform=', platform);

  try {
    console.info('[MGL Fleet] Calling native openFleetNativeFlow (init + present in one bridge)…');
    const result = await MGLFleetSdk.openFleetNativeFlow({
      initialize: init,
      present: options.present ?? {},
    });
    return result;
  } catch (err: unknown) {
    console.error('[@mgl/capacitor-fleet-sdk] Fleet flow failed:', err);
    const o = err as { code?: string; message?: string };
    const code = o.code;
    const message = typeof o.message === 'string' ? o.message : '';
    if (
      code === 'UNIMPLEMENTED' ||
      /not implemented/i.test(message) ||
      /plugin.*not.*found/i.test(message)
    ) {
      console.error(
        '[MGL Fleet] Native plugin is missing or out of date. Run: npx cap sync — then rebuild/reinstall the app from Android Studio or Xcode. Use the same @mgl/capacitor-fleet-sdk version as your mgl-sdk checkout and republish fleet-android if you use Maven Local.',
      );
    }
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
  FleetSdkOpenNativeUnifiedOptions,
  FleetSdkPresentOptions,
  FleetSdkSuccessPayload,
  MGLFleetSdkPlugin,
} from './definitions';
