plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    afterEvaluate {
        // Disabling lintVital for release builds to speed up the process and avoid build-time lint crashes
        tasks.findByName("lintVitalAnalyzeRelease")?.enabled = false
    }
}

// Custom build directory configuration for your project structure
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    afterEvaluate {
        // Safely access the android extension and use Kotlin-friendly lint configuration
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            lintOptions {
                // Fixed: Use the 'disable' function instead of '+=' operator for Kotlin DSL
                disable("NullSafeMutableLiveData")
            }
        }
    }
}

apply(from = "lint.gradle")

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}