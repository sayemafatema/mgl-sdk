# Angular + Capacitor: Fleet native SDK integration

Step-by-step guide for wiring **`@mgl/capacitor-fleet-sdk`** into an Angular app that ships with Capacitor on **Android** and **iOS**.

Master overview (errors, distribution): [`README.NATIVE-SDK.md`](README.NATIVE-SDK.md).

---

## Does the whole flow run on `initialize` only?

**No.** They do different jobs:

| Call | Purpose |
|------|--------|
| **`initialize`** | Runs once (typically at app startup). Saves **`apiBaseUrl`**, optional **`authToken`**, **`useMock`**. Does **not** open UI or run the Fleet journey. |
| **`presentFleetFlow`** | Opens the **fullscreen native Fleet UI** (Kotlin Activity / Swift modal). Call this when the user taps “Fleet”, checkout, etc. Resolves when the flow completes or fails. |

So: **initialize = configuration**, **presentFleetFlow = launch the experience**.

The fullscreen UI is the **native** implementation that mirrors the repo web demo **`app/page.tsx`** (onboarding, PIN, forgot-PIN/OTP, pairing, assignment overlays, tabs)—implemented in **Android** Compose (`native-android/fleet-sdk/.../FleetDriverComposeApp.kt`) and **iOS** SwiftUI (`native-ios/MGLFleetSDK/.../FleetDriverNativeView.swift`). **Minimum iOS:** **16** (sheet detents used in the pairing help sheet).

---

## Prerequisites

- **Node / npm** (match your Capacitor major version).
- **Android:** JDK 17+, Android SDK (same as your Capacitor app).
- **iOS:** Xcode on macOS.
- **This repo** available locally (or your CI publishes **`fleet-android`** to Maven and **`MGLFleetSDK`** via SPM/CocoaPods).

---

## Step 1 — Android: resolve `fleet-android`

**Production:** After publish, integrators use **Maven Central** only:

```gradle
repositories {
    google()
    mavenCentral()
}
```

Coordinate **`com.mgl.sdk:fleet-android`** — version **[`VERSIONS.md`](VERSIONS.md)**.

**Working against an unpublished checkout**, publish locally:

```bash
cd native-android   # inside your clone of mgl-sdk
./gradlew :fleet-sdk:publishToMavenLocal
```

…and add **`mavenLocal()`** to repositories until **`fleet-android`** is on Central.

Maintainers: **[`PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.

---

## Step 2 — Install the Capacitor plugin in your Angular project

**Published:** once **`@mgl/capacitor-fleet-sdk`** is on npm:

```bash
npm install @mgl/capacitor-fleet-sdk
```

**From this monorepo:**

```bash
npm install /absolute/path/to/mgl-sdk/plugins/capacitor-fleet
# or: npm install file:../mgl-sdk/plugins/capacitor-fleet
```

Ensure **`@capacitor/core`** (and **`@capacitor/android`** / **`@capacitor/ios`**) versions align with what the plugin expects (Capacitor **6.x** peer).

Build the plugin’s TypeScript facade if you installed from source without `dist/`:

```bash
cd node_modules/@mgl/capacitor-fleet-sdk   # path may vary
npm install && npm run build
```

Prefer consuming a built tarball or npm release where **`dist/`** is already committed.

---

## Step 3 — Register Capacitor native projects and sync

```bash
npx cap add android   # if not already added
npx cap add ios       # if not already added
npx cap sync
```

---

## Step 4 — Android: Gradle repositories (`fleet-android`)

After **`fleet-android`** is on **Maven Central**, consumer apps typically only need **`google()`** + **`mavenCentral()`** — no **`mavenLocal()`**.

While you depend on an unpublished `.aar`, keep **`mavenLocal()`** in the **project-level** Gradle repositories list.

The Capacitor plugin’s **`android/build.gradle`** lists **`mavenLocal()`**, **`google()`**, and **`mavenCentral()`**, and pulls Capacitor core from **`project(':capacitor-android')`** (not from Maven). If **`fleet-android`** fails to resolve, mirror **`mavenLocal()`** at the root **`settings.gradle`** repositories — Capacitor 8+ templates often resolve dependencies only from the root block.

Keep **Java/Kotlin 17** compatibility consistent with the plugin (`compileOptions` / `jvmTarget` **17**).

**AGP 8.7.x hosts:** The **`fleet-android`** library is built to **pin `androidx.core` / `core-ktx` to 1.15.x** and uses a **Compose BOM / `activity-compose`** line that avoids **`androidx.core` 1.17+** (that 1.17 line’s AAR metadata requires **AGP 8.9.1+**). Rebuild and **`publishToMavenLocal`** / refresh the dependency so your app picks up this version. If the **AAR metadata** warning **still** names **`androidx.core:1.17`**, another dependency in the host app (often **`@capacitor/android`**) is pulling 1.17 — that case cannot be fixed from **`fleet-android`** alone without a small Gradle exclusion/constraint in the app.

The host **`Activity`** must be a **`FragmentActivity`** (Capacitor’s default satisfies this).

---

## Step 5 — iOS: link `MGLFleetSDK` (Swift Package)

The Capacitor plugin’s Swift code uses **`#if canImport(MGLFleetSDK)`**. Until the package is linked, **iOS calls will reject** with instructions to add SPM.

1. Open **`ios/App/App.xcworkspace`** in Xcode.
2. **File → Add Package Dependencies…**
3. Add the local package folder: **`native-ios/MGLFleetSDK`** from your **`mgl-sdk`** checkout (use **Add Local…**).
4. Add the library product **`MGLFleetSDK`** to the **App** target.

**Published monorepo:** instead of a local folder, add **`https://github.com/YOUR_ORG/mgl-sdk.git`** with dependency rule **from `0.1.0`** (uses root **`Package.swift`**).

Then:

```bash
cd ios/App && pod install   # if your workflow uses CocoaPods from `ios/App`
npx cap sync ios
```

---

## Step 6 — Angular: initialize once, present on demand

### 6a. One-time initialization

Call **`initialize`** after the native layer is ready—e.g. **`APP_INITIALIZER`** (with `inject` + `firstValueFrom` if you wrap in an Observable), or **`MainComponent.ngOnInit`**, or a dedicated **`FleetBootstrapService`** invoked from the app module.

Example (simplified service):

```typescript
import { Injectable } from '@angular/core';
import { MGLFleetSdk } from '@mgl/capacitor-fleet-sdk';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class FleetNativeService {
  private ready = false;

  async ensureInitialized(): Promise<void> {
    if (!Capacitor.isNativePlatform()) return;
    if (this.ready) return;
    await MGLFleetSdk.initialize({
      apiBaseUrl: 'https://your-api.example.com',
      authToken: undefined,
      useMock: true,
    });
    this.ready = true;
  }

  async openFleet(correlationId?: string) {
    if (!Capacitor.isNativePlatform()) {
      console.warn('Fleet native UI runs on iOS/Android only');
      return;
    }
    await this.ensureInitialized();
    return MGLFleetSdk.presentFleetFlow(
      correlationId ? { correlationId } : {},
    );
  }
}
```

### 6b. Button (or route guard) opens the flow

```typescript
async onOpenFleet() {
  try {
    const result = await this.fleet.openFleet('order-123');
    console.log(result?.event, result?.payload);
  } catch (e) {
    console.error(e);
  }
}
```

You do **not** need Angular routes for Fleet screens when using this path—the **native SDK** owns the fullscreen stack.

---

## Step 7 — Run on device or emulator

```bash
npx cap run android
npx cap run ios
```

`initialize` / `presentFleetFlow` are **no-ops or errors on the web** unless you add a separate web fallback; guard with **`Capacitor.isNativePlatform()`** as above.

---

## Troubleshooting

| Symptom | What to check |
|--------|----------------|
| Android: could not resolve **`com.mgl.sdk:fleet-android`** | Publish locally (**`./gradlew :fleet-sdk:publishToMavenLocal`** from **`native-android`**) or use Maven Central once published; add **`mavenLocal()`** at the **root** **`dependencyResolutionManagement` / `repositories`** block (not only inside the plugin subproject). |
| Android: could not resolve **`com.capacitorjs:capacitor-android`** from Maven | Expected: the plugin uses **`project(':capacitor-android')`**. Ensure **`npx cap sync android`** ran and **`settings.gradle`** includes **`capacitor-android`** (default Capacitor template). |
| Android: **AAR metadata** — `androidx.core:1.17` requires **AGP 8.9.1+** | Use the latest **`fleet-android`** build (pins core **1.15.x**). Republish **`publishToMavenLocal`** and sync. If it still appears, **Capacitor** or another library is pulling 1.17 — resolve/force an older **`androidx.core`** in the **app** Gradle file (minimal one-line change) or upgrade AGP. |
| iOS: reject about **MGLFleetSDK** / **canImport** | Complete **Step 5** and target the **App** app, not only the Pods project. |
| iOS deployment / compile errors on older iOS | The SwiftUI Fleet shell targets **iOS 16+**; align the host app and SPM minimum. |
| **`FragmentActivity`** error | Ensure the main Capacitor activity extends **`FragmentActivity`**. |
| TypeScript / build errors for the plugin | Run **`npm run build`** inside the plugin package so **`dist/`** exists. |

---

## Legacy path (embedded Angular Fleet UI)

If you still use **`initFleetNativeSdk`** and in-app Angular routes for Fleet, see [`README.ANGULAR-CAPACITOR.md`](README.ANGULAR-CAPACITOR.md). Native-first integration **prefers** this Capacitor plugin + **`presentFleetFlow`**, not merchant-app routing into Fleet screens.
