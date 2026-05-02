# v0-mgl-fleet-app

This is a [Next.js](https://nextjs.org) project bootstrapped with [v0](https://v0.app).

## Built with v0

This repository is linked to a [v0](https://v0.app) project. You can continue developing by visiting the link below -- start new chats to make changes, and v0 will push commits directly to this repo. Every merge to `main` will automatically deploy.

[Continue working on v0 →](https://v0.app/chat/projects/prj_ZHadHQaOlYP3iZbvqwW5Fx58mg5R)

## Getting Started

This app uses **Next.js 16**. Use **Node.js 20 LTS** (or newer). Check with `node -v`. If you use [nvm](https://github.com/nvm-sh/nvm):

```bash
nvm install
nvm use
```

Older Node versions cause errors like **`SyntaxError: Unexpected token ?`** when running `next dev`.

First, install dependencies and run the development server (**npm** is what this repo’s lockfile targets):

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

### Common errors

| Message | Fix |
|---------|-----|
| **`SyntaxError: Unexpected token ?`** when running **`next dev`** | Upgrade to **Node 20+** (`node -v`). See **Getting Started** above. |
| **`Failed to get registry from "pnpm"`** / **`pnpm: command not found`** | Next assumes **pnpm** if **`pnpm-lock.yaml`** is present. Use **npm** only: delete **`pnpm-lock.yaml`** (keep **`package-lock.json`**) or install **`pnpm`** globally. |
| **`EPERM` / permission errors** during **`npm install`** | Run the command in your normal system terminal (not a restricted sandbox), or fix folder ownership. |

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

## Learn More

To learn more, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.
- [v0 Documentation](https://v0.app/docs) - learn about v0 and how to use it.

<a href="https://v0.app/chat/api/kiro/clone/priyasharma23-spec/v0-mgl-fleet-app" alt="Open in Kiro"><img src="https://pdgvvgmkdvyeydso.public.blob.vercel-storage.com/open%20in%20kiro.svg?sanitize=true" /></a>

## Cross-platform SDK (Angular / Flutter / React Native)

**Native-first (recommended):** [`docs/README.NATIVE-SDK.md`](docs/README.NATIVE-SDK.md) — Kotlin + Swift cores; Capacitor (`@mgl/capacitor-fleet-sdk`), Flutter (`mgl_fleet_native_sdk`), and React Native (`@mgl/react-native-fleet-sdk`) bridges share **`initialize` / `presentFleetFlow`**.

OpenAPI contract: [`docs/openapi/fleet-api.yaml`](docs/openapi/fleet-api.yaml).

| Host | Legacy / transitional |
|------|------------------------|
| Angular + Capacitor | **`initFleetNativeSdk`** — [`docs/README.ANGULAR-CAPACITOR.md`](docs/README.ANGULAR-CAPACITOR.md) |
| Flutter | **`FleetNativeSdk`** — [`docs/README.FLUTTER.md`](docs/README.FLUTTER.md), [`flutter-sdk/`](flutter-sdk/) |

Headless TS core: [`core-sdk/`](core-sdk/).
