plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "app.recall.recall"
    // sentry_flutter compiles against SDK 36. NDK stays on Flutter's default
    // (26.3) — plugins may warn about 27 but build cleanly; a partial NDK 27
    // install breaks the build (CXX1101 missing source.properties).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // supabase_flutter transitive deps require minSdk 23
        // (ua_client_hints ≥22, passkeys_android ≥23).
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // google-services.json is per-flavor under src/<flavor>/ — no manual swap.
    // Run with: flutter run --flavor staging|prod --dart-define-from-file=config/<flavor>.json
    flavorDimensions += "env"
    productFlavors {
        create("staging") {
            dimension = "env"
            applicationId = "app.recall.staging"
            resValue("string", "app_name", "Recall Stage")
        }
        create("prod") {
            dimension = "env"
            applicationId = "app.recall"
            resValue("string", "app_name", "Recall")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
