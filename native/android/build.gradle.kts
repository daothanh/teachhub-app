buildscript {
    dependencies {
        // AGP 9 có Kotlin tích hợp, mặc định kéo KGP cũ hơn; khai báo để dùng đúng bản trong catalog.
        classpath(libs.kotlin.gradle.plugin)
    }
}

plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}
