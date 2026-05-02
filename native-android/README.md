# Native Android Fleet SDK (`fleet-android`)

## Modules

| Module | Purpose |
|--------|---------|
| `:fleet-sdk` | Kotlin library (`com.mgl.fleet.sdk`) — `FleetSdk.initialize`, `FleetSdk.presentFleetFlow`, REST helper [`FleetApiClient`](../fleet-sdk/src/main/java/com/mgl/fleet/sdk/api/FleetApiClient.kt) |
| `:sample-host` | Demonstrates initialization + launching flow |

## Build / publish

```bash
./gradlew :fleet-sdk:assembleRelease
./gradlew :fleet-sdk:publishToMavenLocal    # installs com.mgl.sdk:fleet-android matching fleetAndroid.version (gradle.properties)
./gradlew :sample-host:installDebug
```

Gradle wrapper (`gradlew`): generate via **`gradle wrapper`** or Android Studio after cloning — CI regenerates via **`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`** bootstrap snippet.

Staging folder for Sonatype portal bundle upload:

```bash
./gradlew :fleet-sdk:publishReleasePublicationToStagingDeployRepository
# artifacts → fleet-sdk/build/staging-deploy/
```

Published builds flow to **Maven Central** — operator checklist **[`docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md`](../docs/PUBLISH_FOR_EXTERNAL_CONSUMERS.md)**.

Until **`fleet-android`** is public on Central, bridges rely on **Maven Local** — publish before **`cap sync`** / Gradle resolves **`com.mgl.sdk:fleet-android`** from **`plugins/*/android/build.gradle`**.