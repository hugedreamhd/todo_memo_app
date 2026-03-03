pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Android Gradle Plugin 8.9.1 이상 필요 (androidx.activity 1.11.0 요구사항)
    id("com.android.application") version "8.9.1" apply false
    // Flutter가 곧 지원 중단할 예정인 2.0.21 대신 2.1.0 이상 사용
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}





include(":app")
