plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "com.example.empresas_radiofonicas"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.empresas_radiofonicas"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 🛡️ [AGREGA ESTE BLOQUE AQUÍ] para que Java compile en la versión 17:
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

   buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false  // <--- Nota el "is" al principio
            isShrinkResources = false // <--- Nota el "is" al principio
        }
    }
}

// Esto asegura que Kotlin también use la versión 17 (ya lo tenías así abajo):
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}