import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val flavorNames = listOf("development", "staging", "production")

// Firebase plugins only once a src/<flavor>/google-services.json exists, so the
// project still builds before Firebase is set up. See docs/native-setup.md.
if (flavorNames.any { file("src/$it/google-services.json").exists() }) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// Release signing: android/key.properties (never committed).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) keystorePropertiesFile.inputStream().use { load(it) }
}

android {
    namespace = "vn.com.tasco.teachhub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "vn.com.tasco.teachhub"
        minSdk = 28 // Android 9+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("development") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "TeachHub Dev")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            resValue("string", "app_name", "TeachHub Stg")
        }
        create("production") {
            dimension = "env"
            resValue("string", "app_name", "TeachHub")
        }
    }

    signingConfigs {
        create("release") {
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Fail release builds early with a clear message instead of an unsigned/debug-signed artifact.
gradle.taskGraph.whenReady {
    if (!keystorePropertiesFile.exists() &&
        allTasks.any { it.project == project && it.name.contains("Release") }
    ) {
        throw GradleException(
            "Release build requires android/key.properties (storeFile, storePassword, keyAlias, keyPassword). " +
                "See docs/native-setup.md.",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
