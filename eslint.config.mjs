import nextCore from 'eslint-config-next/core-web-vitals';

const ignores = [
  '**/node_modules/**',
  '**/.next/**',
  '**/out/**',
  'mobile/**',
  'v0-mgl-fleet-app/**',
  'angular-sdk/**',
  'core-sdk/**',
  'flutter-sdk/**',
  'plugins/**',
];

/** @type {import('eslint').Linter.Config[]} */
const config = [
  { ignores },
  ...(Array.isArray(nextCore) ? nextCore : [nextCore]),
  {
    rules: {
      'import/no-anonymous-default-export': 'warn',
      'react-hooks/set-state-in-effect': 'off',
      'react-hooks/exhaustive-deps': 'warn',
      'react-hooks/static-components': 'off',
      'react-hooks/refs': 'off',
      'react-hooks/purity': 'off',
    },
  },
];

export default config;
