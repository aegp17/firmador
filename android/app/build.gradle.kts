plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.firmador"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.firmador"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Configure ProGuard to keep PDF signing related classes
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // PDF manipulation and digital signing
    implementation 'com.itextpdf:itext7-core:7.2.5'
    implementation 'com.itextpdf:sign:7.2.5'
    implementation 'com.itextpdf:bouncy-castle-adapter:7.2.5'
    
    // BouncyCastle cryptography provider
    implementation 'org.bouncycastle:bcprov-jdk15to18:1.76'
    implementation 'org.bouncycastle:bcpkix-jdk15to18:1.76'
    implementation 'org.bouncycastle:bcutil-jdk15to18:1.76'
    
    // Apache Commons for utilities
    implementation 'org.apache.commons:commons-lang3:3.12.0'
    implementation 'commons-io:commons-io:2.11.0'
    
    // HTTP client for TSA requests
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.12.0'
    
    // JSON parsing for TSA responses
    implementation 'org.json:json:20240303'
    
    // Kotlin coroutines for async operations
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3'
    
    // Multidex support
    implementation 'androidx.multidex:multidex:2.0.1'
    
    // Logging
    implementation 'org.slf4j:slf4j-android:1.7.36'
}
