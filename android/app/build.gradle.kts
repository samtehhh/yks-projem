plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services Plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_application_1" // Paket ismini kontrol et
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Kendi Application ID'ni buraya yaz
        applicationId = "com.example.flutter_application_1"
        // Flutter versiyonlarını kullan
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // İmzalama ayarları
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:deprecation")
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    
    // Firebase Authentication Kütüphanesi (BoM kullandığımız için versiyon belirtmeye gerek yok)
    implementation("com.google.firebase:firebase-auth")
    
    // Diğer gerekli kütüphaneler (örneğin Cloud Firestore veya Realtime Database kullanacaksan ekle)
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-database")
}