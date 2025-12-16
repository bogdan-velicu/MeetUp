plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.meetup.meetup_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.meetup.meetup_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing configurations
    signingConfigs {
        // Release signing - uncomment and configure if you have a keystore
        // create("release") {
        //     val keystorePropertiesFile = rootProject.file("key.properties")
        //     val keystoreProperties = java.util.Properties()
        //     if (keystorePropertiesFile.exists()) {
        //         keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
        //         keyAlias = keystoreProperties["keyAlias"] as String
        //         keyPassword = keystoreProperties["keyPassword"] as String
        //         storeFile = file(keystoreProperties["storeFile"] as String)
        //         storePassword = keystoreProperties["storePassword"] as String
        //     }
        // }
    }

    buildTypes {
        release {
            // For testing: using debug keys (not secure for production)
            // For production: uncomment the signing config above and use it here
            signingConfig = signingConfigs.getByName("debug")
            // signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
