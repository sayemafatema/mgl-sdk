plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    `maven-publish`
}

val fleetAndroidVersion = providers.gradleProperty("fleetAndroid.version").getOrElse("0.1.0")

android {
    namespace = "com.mgl.fleet.sdk"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = false
    }
}

dependencies {
    implementation(libs.appcompat)
    implementation(libs.material)
    implementation(libs.fragment.ktx)
    implementation(libs.okhttp)
}

afterEvaluate {
    publishing {
        publications {
            register<MavenPublication>("release") {
                groupId = "com.mgl.sdk"
                artifactId = "fleet-android"
                version = fleetAndroidVersion
                from(components["release"])

                pom {
                    name.set("MGL Fleet Android SDK")
                    description.set("Native Android Fleet SDK (Kotlin)")
                    url.set(providers.gradleProperty("fleetAndroid.pom.url").getOrElse("https://github.com/YOUR_ORG/mgl-sdk"))

                    licenses {
                        license {
                            name.set("Apache License 2.0")
                            url.set("https://www.apache.org/licenses/LICENSE-2.0.txt")
                        }
                    }
                    developers {
                        developer {
                            id.set(providers.gradleProperty("fleetAndroid.pom.developerId").getOrElse("mgl"))
                            name.set(providers.gradleProperty("fleetAndroid.pom.developerName").getOrElse("MGL"))
                        }
                    }
                    scm {
                        connection.set("scm:git:git://github.com/YOUR_ORG/mgl-sdk.git")
                        developerConnection.set("scm:git:ssh://git@github.com/YOUR_ORG/mgl-sdk.git")
                        url.set("https://github.com/YOUR_ORG/mgl-sdk")
                    }
                }
            }
        }

        repositories {
            mavenLocal()

            maven {
                name = "stagingDeploy"
                url = uri(layout.buildDirectory.dir("staging-deploy"))
            }

            val ossrhUser = System.getenv("OSSRH_USERNAME").orEmpty()
            val ossrhPass = System.getenv("OSSRH_PASSWORD").orEmpty()
            if (ossrhUser.isNotEmpty() && ossrhPass.isNotEmpty()) {
                maven {
                    name = "OSSRH"
                    url =
                        uri(
                            providers.gradleProperty("fleetAndroid.publish.repository.url").getOrElse(
                                "https://ossrh-staging-api.central.sonatype.com/service/local/staging/deploy/maven2/",
                            ),
                        )
                    credentials {
                        username = ossrhUser
                        password = ossrhPass
                    }
                }
            }
        }
    }
}
