import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.azkar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.azkar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Stable debug key: CI restores it from GitHub secrets and exposes the
    // path and passwords as environment variables. Without them (local or
    // fork builds) Gradle falls back to the auto-generated debug key.
    val debugStorePath: String? = System.getenv("DEBUG_KEYSTORE_PATH")
    val hasStableDebugKey = debugStorePath != null && File(debugStorePath).exists()

    signingConfigs {
        if (hasStableDebugKey) {
            create("stableDebug") {
                storeFile = File(debugStorePath!!)
                storePassword = System.getenv("DEBUG_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("DEBUG_KEY_ALIAS")
                keyPassword = System.getenv("DEBUG_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            // Lets the debug and release apps sit side by side on the phone.
            applicationIdSuffix = ".debug"
            resValue("string", "app_name", "أذكار (تجريبي)")
            if (hasStableDebugKey) {
                signingConfig = signingConfigs.getByName("stableDebug")
            }
        }
        release {
            resValue("string", "app_name", "أذكار")
            // Release signing is added with the release workflow.
            signingConfig = signingConfigs.getByName("debug")
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
