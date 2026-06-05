// android/app/build.gradle.kts
//
// Release signing strategy:
//   • Reads `key.properties` at the android/ folder if present (local
//     dev / CI machines that have a real keystore configured)।  See
//     `android/key.properties.example` for the expected shape।
//   • Falls back to the debug keystore when `key.properties` is missing
//     so contributors who haven't set up signing can still
//     `flutter run --release` without a keystore on their laptop।
//
// To wire up real signing:
//   1. Generate keystore:
//        keytool -genkey -v -keystore ~/keystores/clicker_pro.jks \
//          -keyalg RSA -keysize 2048 -validity 10000 -alias clickerpro
//   2. Copy `android/key.properties.example` to `android/key.properties`
//      and fill in the values (NEVER commit the real file)।
//   3. `key.properties` is already in `android/.gitignore` so secrets
//      stay local।

import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin
    // Gradle plugins।
    id("dev.flutter.flutter-gradle-plugin")
}

// ─── Load signing properties (optional) ───────────────────────────────
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.clickerpro.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.clickerpro.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
