import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sonic_vault_flutter.dev"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.sonic_vault_flutter.dev"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0-dev"
    }

    signingConfigs {
        create("release") {
            val keyProps = Properties()
            val keyPropsFile = file(rootProject.projectDir.resolve("key.properties"))
            if (keyPropsFile.exists()) {
                keyProps.load(keyPropsFile.inputStream())
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
                
                if (storePassword == null || keyPassword == null || keyAlias == null) {
                    throw GradleException("key.properties found but some properties are missing (storePassword, keyPassword, or keyAlias)")
                }
            } else {
                println("WARNING: key.properties not found at ${keyPropsFile.absolutePath}. Build will fail at signing stage.")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
