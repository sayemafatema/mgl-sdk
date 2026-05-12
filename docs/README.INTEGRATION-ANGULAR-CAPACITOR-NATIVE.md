# Angular + Capacitor: MGL Fleet native SDK

Integrate **`@mgl/capacitor-fleet-sdk`** into an Angular app with Capacitor on **Android** and **iOS**. The fullscreen Fleet UI is **native** (Compose on Android, SwiftUI on iOS). **Minimum iOS: 16.**

Deeper background: [`README.NATIVE-SDK.md`](README.NATIVE-SDK.md).

---

## How opening the flow works

Use **`openMglFleetNativeFlow()`** from `@mgl/capacitor-fleet-sdk`. It calls the native method **`openFleetNativeFlow`**, which runs **`initialize` + `presentFleetFlow` in a single Capacitor invoke** (reliable on device; avoids split-bridge ordering issues).

- **`initialize`** / **`presentFleetFlow`** on the plugin remain available; **`presentFleetFlow`** alone returns **`NOT_INITIALIZED`** if **`initialize`** was never run in this process.
- **`ng serve` / browser**: not supported for native UI — the helper exits early (or web throws). Test with **`npx cap run android`** / **`npx cap run ios`**.

---

## Prerequisites

- **Node** aligned with your Capacitor major (**Capacitor CLI 6+ expects Node 18+**).
- **Angular** app with **Capacitor 6.x** (match **`@capacitor/core`** / **`@capacitor/android`** / **`@capacitor/ios`** to the plugin peer).
- **Android:** JDK **17**, Android SDK.
- **iOS:** Xcode; link **`MGLFleetSDK`** (below).

---

## 1. Install the npm package

**Published:**

```bash
npm install @mgl/capacitor-fleet-sdk
```

**From this repo (path):** the `file:` path is **relative to your host app’s `package.json`** (not to `src/`). Example: if the app is `…/bolt-pwa` and `mgl-sdk` is **`…/bolt-pwa/../mgl-sdk`** → use `file:../mgl-sdk/plugins/capacitor-fleet`. If `mgl-sdk` lives elsewhere, use the correct number of `../` segments or an **absolute** `file:/Users/…/mgl-sdk/plugins/capacitor-fleet`.

```bash
npm install file:/absolute/path/to/mgl-sdk/plugins/capacitor-fleet
```

After editing `package.json`, run **`npm install`** from the **host app root** and confirm:

```bash
node -p "require.resolve('@mgl/capacitor-fleet-sdk/package.json')"
```

If that throws, the path is wrong or install did not run — Angular will report **Cannot find module '@mgl/capacitor-fleet-sdk'**.

**Build the plugin’s `dist/`** (required for imports):

```bash
cd /path/to/mgl-sdk/plugins/capacitor-fleet
npm install && npm run build
```

If Angular still fails to resolve a **`file:`** dependency (symlink / hoisting), in **`angular.json`** under **`architect.build.options`** add **`"preserveSymlinks": true`** for the browser builder, then **`ng cache clean`** and rebuild.

If you depend on **source without a prebuilt `dist/`**:

```bash
cd node_modules/@mgl/capacitor-fleet-sdk
npm install && npm run build
```

---

## 2. Android — `fleet-android` on Maven

The plugin depends on **`com.mgl.sdk:fleet-android`** (version in the plugin’s **`android/build.gradle`**, typically **`0.3.0`**).

**After the library is on Maven Central:** root **`settings.gradle` / `dependencyResolutionManagement`** needs **`google()`** and **`mavenCentral()`** (usual Capacitor setup).

**Until then, or while developing against a local clone:**

```bash
cd native-android    # mgl-sdk checkout
./gradlew :fleet-sdk:publishToMavenLocal
```

Add **`mavenLocal()`** to the **same repository list the app uses** for dependency resolution (often the **root** `dependencyResolutionManagement.repositories` block). If **`fleet-android`** does not resolve, the root block is missing **`mavenLocal()`** — mirror it there, not only inside a submodule.

Keep **Java / Kotlin 17** (compileOptions / **jvmTarget 17**).

**When you update the SDK from Git:** republish **`fleet-android`** and refresh Gradle so the Kotlin API matches the Capacitor plugin (e.g. **`FleetSdk.isInitialized()`**).

**AGP 8.7.x / `androidx.core` 1.17 metadata:** use a **`fleet-android`** build that pins core **1.15.x** (this repo). If another dependency still pulls **1.17+**, add a host-level constraint or upgrade AGP — see troubleshooting in [`README.NATIVE-SDK.md`](README.NATIVE-SDK.md).

**Note:** The plugin resolves **`capacitor-android`** via **`project(':capacitor-android')`** after **`npx cap sync`** — not from Maven **`com.capacitorjs:capacitor-android`**.

---

## 3. Capacitor native projects

```bash
npx cap add android    # if missing
npx cap add ios       # if missing
npx cap sync
```

Repeat **`npx cap sync`** whenever you change the plugin version or its native code.

---

## 4. iOS — Swift package `MGLFleetSDK`

Plugin code is behind **`#if canImport(MGLFleetSDK)`**. Without the package, native calls **reject** with an add-package message.

1. Open **`ios/App/App.xcworkspace`** (or your app workspace) in Xcode.
2. **File → Add Package Dependencies… → Add Local…**
3. Select **`native-ios/MGLFleetSDK`** from your **`mgl-sdk`** checkout.
4. Add product **`MGLFleetSDK`** to the **App** target.

If you use **CocoaPods** for `ios/App`:

```bash
cd ios/App && pod install
npx cap sync ios
```

---

## 5. Angular — recommended usage

Use **`openMglFleetNativeFlow`**. Pass a non-empty **`apiBaseUrl`** (or rely on mock placeholder + warning when **`useMock: true`** and URL is empty — see package implementation). Use **`async` / `await`** on the button path.

**Service:**

```typescript
import { Injectable } from '@angular/core';
import { openMglFleetNativeFlow } from '@mgl/capacitor-fleet-sdk';

@Injectable({ providedIn: 'root' })
export class FleetNativeService {
  async openFleet(correlationId?: string): Promise<void> {
    try {
      const result = await openMglFleetNativeFlow({
        initialize: {
          apiBaseUrl: 'https://your-api.example.com',
          authToken: undefined,
          useMock: true,
        },
        present: correlationId ? { correlationId } : {},
      });
      console.log('[MGL Fleet] done:', result?.event, result?.payload);
    } catch (e) {
      console.error('[MGL Fleet] failed:', e);
    }
  }
}
```

**Template + component:**

```html
<button type="button" (click)="onFleetClick()">Fleet</button>
```

```typescript
async onFleetClick(): Promise<void> {
  await this.fleetNative.openFleet();
}
```

**Optional — manual two-step** (only if you need fine control): **`await MGLFleetSdk.initialize(...)`** then **`await MGLFleetSdk.presentFleetFlow(...)`**. Do not call **`presentFleetFlow`** without a successful **`initialize`** in the same process.

---

## 6. Run on device or emulator

```bash
npx cap run android
npx cap run ios
```

---

## 7. Troubleshooting (short)

| Issue | Action |
|------|--------|
| **`com.mgl.sdk:fleet-android` not found** | **`publishToMavenLocal`** from **`native-android`**; **`mavenLocal()`** in root repos. |
| **`NOT_INITIALIZED`** on present | Use **`openMglFleetNativeFlow`**, or **`initialize`** before **`presentFleetFlow`**. |
| **Plugin not implemented / old native** | **`npm install`**, **`npx cap sync`**, full rebuild and reinstall the app. |
| **iOS reject: add MGLFleetSDK** | Complete step 4; product on **App** target. |
| **Stub / no-op in console** | Remove host **path aliases** or stub modules shadowing **`@mgl/capacitor-fleet-sdk`**. |
| **Nothing happens / no snackbar** | If you only use **`ng serve`** or open the app URL in desktop Chrome, **`openMglFleetNativeFlow` throws** (so **`catch`** can show a message). You must run **`npx cap run android`** / **`ios`** (or install from Android Studio / Xcode). |
| **Nothing opens on device** | **`npx cap sync`**, rebuild + reinstall; republish **`fleet-android`** if using Maven Local; WebView console **`[MGL Fleet]`**; Logcat filter **`MGLFleetSdk`** (init + present lines). Stale native: JS may log a **fallback** to **`initialize` + `presentFleetFlow`** until you sync. |

---

## Legacy: in-app Angular Fleet routes

For **`initFleetNativeSdk`** and Angular-routed Fleet UI, see [`README.ANGULAR-CAPACITOR.md`](README.ANGULAR-CAPACITOR.md). Prefer this document’s **native fullscreen** flow for new work.
