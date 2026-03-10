import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load key.properties if it exists (local builds).
// CI uses environment variables as fallback.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

fun keyProp(name: String): String? =
    keyProperties.getProperty(name) ?: System.getenv(name)

dependencies {
  implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
  implementation("com.google.firebase:firebase-analytics")
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

android {
    namespace = "com.cvc953.avaseto"
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = flutter.ndkVersion
    //ndkVersion = "27.0.12077973"
    ndkVersion = 		"28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        //jvmTarget = JavaVersion.VERSION_11.toString()
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cvc953.avaseto"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        //minSdk = flutter.minSdkVersion
        minSdkVersion(24)
        //targetSdk = flutter.targetSdkVersion
        targetSdkVersion(flutter.targetSdkVersion)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

  signingConfigs {
        create("release") {
            storeFile = file(keyProp("storeFile") ?: "upload-keystore.jks")
            storePassword = keyProp("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            keyAlias = keyProp("keyAlias") ?: System.getenv("KEY_ALIAS")
            keyPassword = keyProp("keyPassword") ?: System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
apply(plugin = "com.google.gms.google-services")
