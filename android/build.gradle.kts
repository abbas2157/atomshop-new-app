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
subprojects {
    project.evaluationDependsOn(":app")
}

// Pin every Android subproject to the NDK and SDK platform installed on the
// build machine, so AGP never has to download extra ones.
//  - NDK: transitive plugins such as `jni` (pulled in by flutter_secure_storage)
//    declare `ndkVersion flutter.ndkVersion`, Flutter's default (28.x), which
//    is not installed here.
//  - compileSdk: plugins ask for 34, 35 or 36. Compiling every library module
//    against the app's own platform (36) is safe and needs one platform only.
// Keep both values in sync with app/build.gradle.kts (flutter.compileSdkVersion
// is 36 for this Flutter release).
subprojects {
    fun pinAndroidToolchain() {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.ndkVersion = "30.0.16248370"
            if (plugins.hasPlugin("com.android.library")) {
                android.compileSdkVersion(36)
            }
        }
    }
    // `evaluationDependsOn(":app")` above has already evaluated :app by the
    // time this runs, and afterEvaluate() is refused on an evaluated project.
    if (state.executed) pinAndroidToolchain() else afterEvaluate { pinAndroidToolchain() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
