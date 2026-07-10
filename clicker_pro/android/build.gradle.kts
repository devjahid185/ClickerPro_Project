allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Some plugins (e.g. flutter_timezone, device_calendar) don't pin their JVM
// target, so they default to Java 8/11 + Kotlin 1.8 and clash with the app's
// Java 17 build, failing with "Inconsistent JVM-target compatibility". Force
// every subproject's Java + Kotlin compilation to target 17 to keep them
// aligned. Registered in afterEvaluate (before evaluationDependsOn triggers
// evaluation below) so it overrides whatever the plugin's own android {}
// block set.
subprojects {
    afterEvaluate {
        // Pin Java compatibility on the Android extension itself (not just the
        // compile tasks) so it wins over a plugin's own compileOptions.
        extensions.findByName("android")?.let { ext ->
            if (ext is com.android.build.gradle.BaseExtension) {
                ext.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
