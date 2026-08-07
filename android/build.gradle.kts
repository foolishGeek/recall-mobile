allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Plugin modules compile against flutter.compileSdkVersion, which Flutter 3.32.7 pins
// to 35. androidx.core 1.18.0 (via connectivity_plus) declares minCompileSdk=36, so
// those modules fail checkAarMetadata until they match the app's compileSdk. Registered
// before the evaluationDependsOn block below, which evaluates :app eagerly.
subprojects {
    afterEvaluate {
        val library = extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
        if (library != null && (library.compileSdk ?: 0) < 36) {
            library.compileSdk = 36
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
