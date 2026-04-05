pluginManagement {
    includeBuild("../.build/Android/skip-gradle")
    repositories {
        mavenCentral()
        gradlePluginPortal()
        google()
    }
}

plugins {
    id("skip-plugin")
}
