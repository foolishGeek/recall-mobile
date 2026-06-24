plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
        // S02: single staging bundle (full staging/prod flavors deferred to S27).
        applicationId = "app.recall.staging"
        // supabase_flutter transitive deps require minSdk 23
        // (ua_client_hints ≥22, passkeys_android ≥23).
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
