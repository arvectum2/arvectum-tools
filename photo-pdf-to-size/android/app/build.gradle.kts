import java.io.FileInputStream
import java.util.Properties

plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.kotlinCompose)
}

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use(::load)
    }
}

android {
    namespace = "ru.arvectum.tools.tosize"
    compileSdk = 37

    defaultConfig {
        applicationId = "ru.arvectum.tools.tosize"
        minSdk = 26
        targetSdk = 37
        versionCode = 7
        versionName = "0.4.2"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(requireNotNull(keystoreProperties.getProperty("storeFile")))
                storePassword = requireNotNull(keystoreProperties.getProperty("storePassword"))
                keyAlias = requireNotNull(keystoreProperties.getProperty("keyAlias"))
                keyPassword = requireNotNull(keystoreProperties.getProperty("keyPassword"))
            }
        }
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        checkReleaseBuilds = false
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

dependencies {
    val composeBom = platform(libs.composeBom)
    implementation(composeBom)

    implementation(libs.coreKtx)
    implementation(libs.activityCompose)
    implementation(libs.material3)
    implementation(libs.composeUi)
    implementation(libs.composeUiToolingPreview)
    implementation(libs.lifecycleRuntimeKtx)
    implementation(libs.lifecycleRuntimeCompose)
    implementation(libs.lifecycleViewmodelCompose)
    implementation(libs.lifecycleViewmodelKtx)
    implementation(libs.exifinterface)

    debugImplementation(libs.composeUiTooling)

    testImplementation(libs.junit4)
}
