import { EnvironmentProviders, makeEnvironmentProviders } from '@angular/core';
import { Routes } from '@angular/router';
import type { FleetSDKConfig } from '@mgl/fleet-core-sdk';
import { FleetService } from './fleet.service';
import { FLEET_SDK_CONFIG } from './fleet.tokens';

/** Registers SDK config + `FleetService` at the app root (standalone `providers`). */
export function provideFleetNativeSdk(config: FleetSDKConfig): EnvironmentProviders {
  return makeEnvironmentProviders([
    { provide: FLEET_SDK_CONFIG, useValue: config },
    FleetService,
  ]);
}

export interface FleetNativeSdkRouteOptions {
  /** URL segment under app root; default `fleet`. Navigate to `/${path}`. */
  path?: string;
}

/** Routes to merge into `provideRouter([...])` — lazy-loads the full native shell once. */
export function fleetNativeSdkRoutes(options?: FleetNativeSdkRouteOptions): Routes {
  const path = options?.path ?? 'fleet';
  return [
    {
      path,
      loadChildren: () =>
        import('./fleet-shell.module').then((m) => m.FleetShellModule),
    },
  ];
}

export interface FleetNativeSdkInit {
  providers: EnvironmentProviders;
  routes: Routes;
}

/**
 * Native SDK bootstrap — **one call** returns everything your host needs:
 * spread `routes` into `provideRouter`, add `providers` to `bootstrapApplication` / `ApplicationConfig`.
 */
export function initFleetNativeSdk(
  config: FleetSDKConfig,
  routeOptions?: FleetNativeSdkRouteOptions,
): FleetNativeSdkInit {
  return {
    providers: provideFleetNativeSdk(config),
    routes: fleetNativeSdkRoutes(routeOptions),
  };
}
