plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "vn.dayhoc.app"
    compileSdk {
        version = release(37)
    }

    defaultConfig {
        applicationId = "vn.dayhoc.app"
        minSdk {
            version = release(28)
        }
        targetSdk {
            version = release(37)
        }
        versionCode = 1
        versionName = "0.1.0"
    }

    flavorDimensions += "env"
    productFlavors {
        create("development") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            // 10.0.2.2 = máy chạy backend, nhìn từ emulator Android.
            buildConfigField("String", "API_URL", "\"http://10.0.2.2:3000/v1\"")
            buildConfigField("boolean", "HTTP_LOGGING", "true")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            buildConfigField("String", "API_URL", "\"https://api-staging.dayhoc.app/v1\"")
            buildConfigField("boolean", "HTTP_LOGGING", "false")
        }
        create("production") {
            dimension = "env"
            buildConfigField("String", "API_URL", "\"https://api.dayhoc.app/v1\"")
            buildConfigField("boolean", "HTTP_LOGGING", "false")
        }
    }

    buildTypes {
        release {
            // Chưa cấu hình ký: Owner giữ keystore và tự thêm signingConfig khi phát hành.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.datastore.preferences)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.material3)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.retrofit)
    implementation(libs.retrofit.kotlinx.serialization)
    debugImplementation(libs.compose.ui.tooling)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.turbine)
    testImplementation(libs.okhttp.mockwebserver)
}
