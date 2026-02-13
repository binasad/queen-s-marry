plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // already correct
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    
}

android {
    namespace = "com.example.salon"
    compileSdk = 36

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.salon"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
     // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.9.0"))


  implementation("com.google.firebase:firebase-analytics")
  implementation("com.google.firebase:firebase-messaging")
  // https://firebase.google.com/docs/android/setup#available-libraries
}
