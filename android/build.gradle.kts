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
    // Register afterEvaluate FIRST. evaluationDependsOn below triggers
    // subproject evaluation immediately, so anything registered after that
    // would throw "Cannot run Project.afterEvaluate when already evaluated".
    //
    // Force every Android library plugin (file_picker, etc.) to compile
    // against SDK 36. Without this, plugins that hard-code an older
    // compileSdk fail the AAR metadata check once any one transitive dep
    // requires 36+. Safe because compileSdk only enables newer APIs; it
    // does not raise minSdk or targetSdk.
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") ||
            project.plugins.hasPlugin("com.android.application")) {
            extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                compileSdkVersion(36)
            }
        }
    }
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
