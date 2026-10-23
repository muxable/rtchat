group = "com.muxable.ondevicetts"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.4.21"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.4.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

// The official ONNX Runtime (MIT). Pinned: bump it deliberately, and rerun the
// parity and emulator tests when you do.
val onnxRuntimeVersion = "1.31.0"

android {
    namespace = "com.muxable.ondevicetts"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            all {
                it.useJUnitPlatform()
                it.outputs.upToDateWhen { false }
                // The parity test compares against reference tensors made by
                // the Python package; it's skipped unless this points at them.
                System.getenv("SUPERTONIC_PARITY_DIR")?.let { dir ->
                    it.environment("SUPERTONIC_PARITY_DIR", dir)
                }
                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                    exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// JVM unit tests can't load the Android build's native library, so they run
// against the desktop build of the same ONNX Runtime version instead.
configurations.matching { it.name.endsWith("UnitTestRuntimeClasspath") }.configureEach {
    exclude(group = "com.microsoft.onnxruntime", module = "onnxruntime-android")
}

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android:$onnxRuntimeVersion")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.junit.jupiter:junit-jupiter:6.1.3")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher:6.1.3")
    if (System.getenv("SUPERTONIC_PARITY_DIR") != null) {
        testRuntimeOnly("com.microsoft.onnxruntime:onnxruntime:$onnxRuntimeVersion")
    }
}
