plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}

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
rootProject.layout.buildDirectory = newBuildDir

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory = newSubprojectBuildDir
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}