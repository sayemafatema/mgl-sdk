import { fleetEnv as localFleetEnv } from './environment';
import { fleetEnv as uatFleetEnv } from './environment.uat';
import { fleetEnv as prodFleetEnv } from './environment.prod';

export type FleetEnvName = 'local' | 'uat' | 'prod';

/** Maps build/runtime: `NEXT_PUBLIC_FLEET_ENV` = unset | `local` | `dev` → local file; `uat` → UAT; `prod` | `production` → prod */
function resolveFleetEnvName(): FleetEnvName {
  const v = process.env.NEXT_PUBLIC_FLEET_ENV?.trim().toLowerCase();
  if (v === 'prod' || v === 'production') return 'prod';
  if (v === 'uat') return 'uat';
  return 'local';
}

export function getFleetEnvironment(): typeof localFleetEnv {
  switch (resolveFleetEnvName()) {
    case 'prod':
      return prodFleetEnv;
    case 'uat':
      return uatFleetEnv;
    default:
      return localFleetEnv;
  }
}

export function getFleetApiBase(): string {
  return getFleetEnvironment().apiUrl.replace(/\/$/, '');
}

export function getFleetAuthBase(): string {
  return getFleetEnvironment().authUrl.replace(/\/$/, '');
}
