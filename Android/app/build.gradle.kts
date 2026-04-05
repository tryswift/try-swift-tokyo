plugins {
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.android.application)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(libs.versions.jvm.get().toString())
    }
}

android {
    namespace = "tokyo.tryswift.android"
    compileSdk = libs.versions.android.sdk.compile.get().toInt()
    compileOptions {
        sourceCompatibility = JavaVersion.toVersion(libs.versions.jvm.get())
        targetCompatibility = JavaVersion.toVersion(libs.versions.jvm.get())
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "tokyo.tryswift.android"
        minSdk = libs.versions.android.sdk.min.get().toInt()
        targetSdk = libs.versions.android.sdk.compile.get().toInt()
        versionCode = 1
        versionName = "1.0.0"
    }

    buildFeatures {
        buildConfig = true
    }

    lint {
        disable.add("Instantiatable")
    }

    sourceSets.getByName("main").assets.srcDir(file("../Sources/ScheduleFeature/AndroidAssets"))
    sourceSets.getByName("main").assets.srcDir(file("../Sources/SponsorFeature/AndroidAssets"))
}

repositories {
    flatDir { dirs(rootProject.file("LiveTranslationFeature/src/main/kotlin/libs")) }
    mavenCentral()
    google()
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(project(":AndroidApp"))
}
