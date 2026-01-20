import org.gradle.api.JavaVersion
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ key.properties (android/key.properties) okuyalım
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ✅ Paket adı (namespace = applicationId ile aynı tutmak iyi pratik)
    namespace = "com.volkysoftware.odakplan"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // ✅ Play Store paket adı (ilk yayın sonrası değişmez)
        applicationId = "com.volkysoftware.odakplan"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // ✅ Release imza: key.properties varsa onu kullanır
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // ✅ Artık debug değil, release signing
            signingConfig = signingConfigs.getByName("release")

            // Şimdilik kapalı kalsın (istersen sonra açarız)
            isMinifyEnabled = false
            isShrinkResources = false

            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }

        debug {
            // debug default
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
