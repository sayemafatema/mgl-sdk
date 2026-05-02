# Publish checklist — external consumers

Complete these steps **once per release train** before external apps use published artifacts instead of cloning this repo.

Coordinates must stay aligned — see **[VERSIONS.md](VERSIONS.md)**.

Replace placeholders **`YOUR_ORG`**, **`YOUR_NPM_SCOPE`**, emails, and Sonatype coordinates everywhere below.

---

## 0. Replace placeholders in-repo

| Location | What to set |
|----------|--------------|
| `native-android/gradle.properties` | `fleetAndroid.pom.*`, signing props when releasing Android |
| `native-ios/MGLFleetSDK/MGLFleetSDK.podspec` | `homepage`, `source.git`, `tag`, `author`, license paths |
| `plugins/*/package.json` | `repository.url`, `homepage`, `bugs.url` |
| `plugins/flutter-fleet/mgl_fleet_native_sdk/pubspec.yaml` | `homepage`, `repository`, `issue_tracker` |

Commit those edits before tagging.

---

## 1. Android — `fleet-android` → Maven Central (or private Maven)

### Validate locally

```bash
cd native-android
./gradlew :fleet-sdk:assembleRelease :fleet-sdk:publishReleasePublicationToMavenLocalRepository
```

If `./gradlew` is missing, generate it once:

```bash
curl -fsSL https://services.gradle.org/distributions/gradle-8.9-bin.zip -o /tmp/g.zip && unzip -q /tmp/g.zip -d /tmp
/tmp/gradle-8.9/bin/gradle -p native-android wrapper --gradle-version 8.9 --distribution-type bin
```

### Unsigned staging folder (portal upload)

Artifacts + POM land under **`native-android/fleet-sdk/build/staging-deploy/`** when you run:

```bash
./gradlew :fleet-sdk:publishReleasePublicationToStagingDeployRepository
```

Zip that layout if your Sonatype **Central Portal** flow expects a bundle upload.

### OSSRH Gradle publish (credentials)

1. Register namespace **`com.mgl.sdk`** with Sonatype / Central Portal (one-time).
2. Export **`OSSRH_USERNAME`** and **`OSSRH_PASSWORD`** (token).
3. **GPG**: Maven Central requires signed artifacts. Add Gradle **`signing`** (see [Gradle signing plugin](https://docs.gradle.org/current/userguide/signing_plugin.html)) or sign externally per portal docs.
4. Run:

```bash
./gradlew :fleet-sdk:publishReleasePublicationToOSSRHRepository
```

(Repository block registers **only when** env vars are non-empty.)

### Release version bump

Edit **`fleetAndroid.version`** in **`native-android/gradle.properties`** and **[VERSIONS.md](VERSIONS.md)** together with npm/pub semver.

---

## 2. iOS — `MGLFleetSDK`

### Swift Package Manager

Consumers depend on **your Git URL + semver tag**:

```swift
.package(url: "https://github.com/YOUR_ORG/mgl-sdk.git", from: "0.1.0")
```

Monorepo layout options:

- **This repository:** root **[`Package.swift`](../Package.swift)** wraps **`native-ios/MGLFleetSDK`** so hosts can use **`.package(url: …, from:)`** against the **whole repo** tag **`X.Y.Z`**.
- **Alternative:** publish **`native-ios/MGLFleetSDK`** as its **own Git mirror** if you want a tiny SPM-only repo.

Align Git tags with **`fleetAndroid.version`**, **`MGLFleetSDK.podspec`** **`s.version`**, and npm/pub semver (**e.g.** **`0.1.0`**). CocoaPods **`:tag`** must point at the commit you intend to ship.

### CocoaPods

```bash
cd native-ios/MGLFleetSDK
pod lib lint MGLFleetSDK.podspec --allow-warnings   # optional
pod trunk push MGLFleetSDK.podspec                  # requires CocoaPods account
```

Ensure **`tag`** and **`source_files`** paths match how **`podspec`** is evaluated from Git.

---

## 3. npm — Capacitor & React Native

From each package directory:

```bash
npm ci
npm run build
npm publish --access public   # or publishConfig.registry for GitHub Packages
```

Packages:

| Folder | Published name |
|--------|----------------|
| `plugins/capacitor-fleet` | `@mgl/capacitor-fleet-sdk` |
| `plugins/react-native-fleet` | `@mgl/react-native-fleet-sdk` |

Requires **`npm login`** and scope **`@mgl`** ownership on npm (or rename scope in **`package.json`**).

---

## 4. Flutter — `mgl_fleet_native_sdk`

1. Remove **`publish_to: none`** from **`pubspec.yaml`** when ready for pub.dev (or publish as Git dependency).
2. Document pinned **`fleet-android`** and **`MGLFleetSDK`** versions in **`README.md`**.
3. Run **`dart pub publish`** from **`plugins/flutter-fleet/mgl_fleet_native_sdk/`** after **`flutter analyze`** passes.

---

## 5. Docs & QA gates

- Update **[CHANGELOG.md](../CHANGELOG.md)** (root or per-module).
- Smoke **`initialize` → `presentFleetFlow`** on Android + iOS per **[RELEASE_NATIVE_SDK.md](RELEASE_NATIVE_SDK.md)**.
- **[README.NATIVE-SDK.md](README.NATIVE-SDK.md)** should describe **published** coordinates first; Maven Local second.

---

## What you cannot automate without secrets

Signing keys, Sonatype tokens, npm OTP, CocoaPods trunk login, and pub.dev OAuth — **you** perform those actions locally or in a secure CI vault after configuring this repo.
