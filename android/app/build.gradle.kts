import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ezerfresh.app"
    // Pinned to API 36 (Android 16) so the app keeps building/publishing
    // against Google Play's Aug 31, 2026 target API requirement even if the
    // local Flutter SDK's bundled default lags behind. Requires Android
    // SDK Platform 36 to be installed (run `flutter doctor` / `sdkmanager
    // "platforms;android-36"` if the build fails to find it).
    compileSdk = 36
    // NDK r27+ is required for 16 KB memory page size support (Google Play
    // requirement, deadline Feb 1, 2027). flutter.ndkVersion tracks
    // whatever the installed Flutter SDK bundles; upgrade Flutter
    // (`flutter upgrade`) if this resolves to something older than r27.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications: it relies on java.time
        // APIs that don't exist on older Android versions, so they have to
        // be "desugared" (back-ported at build time). Without this the
        // build fails with "Dependency ':flutter_local_notifications'
        // requires core library desugaring to be enabled for :app."
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ezerfresh.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 7.0/API 24 is the lowest supported version for the
        // currently locked native Flutter plugins, including Google Maps.
        // This keeps the app installable on virtually every Android device
        // in active use, including all current Samsung Galaxy phones/tablets/
        // foldables, while targetSdk below tracks the newest Play Store
        // requirement so it also fully supports the latest Android versions.
        minSdk = 24
        // Target Android 16 (API 36) — Google Play requires this for all
        // new app submissions and updates starting Aug 31, 2026.
        targetSdk = 36
        // Recommended by flutter_local_notifications. Already the default
        // behaviour at minSdk 24 (Android handles multidex natively from
        // API 21 up), but stated explicitly so the large Firebase + Maps
        // dependency set can't trip the 64K method limit.
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Google Play requires 16 KB memory-page-size support for apps
    // targeting API 35+ on 64-bit devices (deadline Feb 1, 2027). Packaging
    // native libraries uncompressed lets the OS map them directly instead
    // of requiring 4 KB-aligned extraction, which is what 16 KB compliance
    // needs. Safe to keep on even before the deadline.
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

dependencies {
    // Back-ports the newer Java APIs that flutter_local_notifications uses
    // so they work on older Android versions. Pairs with
    // `isCoreLibraryDesugaringEnabled = true` in compileOptions above —
    // both are required together, neither works alone.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
