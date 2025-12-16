// android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }

    dependencies {
        classpath("com.google.gms:google-services:4.4.1") // 
        // También deberías tener el classpath del plugin de Android si falta:
       // classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.android.tools.build:gradle:8.9.1")

           }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


  //
