import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lee las credenciales de firma desde android/key.properties, que NO
// se sube a git (ver .gitignore). Si el archivo no existe (ej. en la
// máquina de un colaborador que no compila releases), simplemente no
// se firma con una key de producción y se usa la de debug, para que
// `flutter run` y los builds de debug sigan funcionando sin fallar.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // Cambia esto por tu propio dominio invertido antes de publicar o
    // instalar en tu teléfono de forma definitiva. No puede ser
    // com.example.* para subir a Play Store, y tenerlo único evita
    // pisar otra app instalada con el mismo id.
    namespace = "com.venexpress.driver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.venexpress.driver"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Usa tu keystore real si key.properties existe (ver
            // android/key.properties.example para crearlo). Sin él, un
            // APK/AAB de release ya NO se genera (ver el chequeo de
            // taskGraph abajo): firmarlo con la clave de debug —que es
            // pública— permitiría que cualquiera distribuyera una
            // "actualización" falsa que Android aceptaría.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// SEGURIDAD: falla cualquier build de release (assembleRelease,
// bundleRelease, `flutter build apk/appbundle`) si no hay keystore real.
// Para una prueba local puntual: ALLOW_DEBUG_SIGNED_RELEASE=true.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { task ->
        task.project == project &&
            task.name.contains("Release") &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle") || task.name.startsWith("package"))
    }

    if (buildsRelease && !hasReleaseSigning && System.getenv("ALLOW_DEBUG_SIGNED_RELEASE") != "true") {
        throw GradleException(
            "Falta android/key.properties: el APK de producción no puede firmarse con la clave " +
                "de debug (es pública). Crea el keystore siguiendo android/key.properties.example."
        )
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
