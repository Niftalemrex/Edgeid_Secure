plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.example.edgeid_secure"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    // Flutter’s embedding dependencies are automatically resolved.
}