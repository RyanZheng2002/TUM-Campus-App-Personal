import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.gms.google-services") apply false
    id("com.google.firebase.crashlytics") apply false
}

val personalBuild = providers.gradleProperty("personalBuild")
    .orElse(providers.environmentVariable("CAMPUS_PERSONAL_BUILD"))
    .orElse(providers.gradleProperty("PERSONALBUILD")).orNull == "true"
if (!personalBuild) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

android {
    namespace = "de.tum.in.tumcampus"
    compileSdk = if (personalBuild) flutter.compileSdkVersion else 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_21)
        }
    }

    defaultConfig {
        applicationId = if (personalBuild) "de.tum.in.tumcampus.personal" else "de.tum.in.tumcampus"
        manifestPlaceholders["appLabel"] = if (personalBuild) "Campus Personal" else "Campus"
        minSdk = 29
        targetSdk = if (personalBuild) flutter.targetSdkVersion else 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        val keystoreFile = System.getenv("ANDROID_KEYSTORE_FILE")
        if (keystoreFile != null) {
            create("release") {
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                storeFile = file(keystoreFile)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            if (System.getenv("ANDROID_KEYSTORE_FILE") != null) {
                signingConfig = signingConfigs.getByName("release")
                isMinifyEnabled = true
                isShrinkResources = true
                proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0")
}
