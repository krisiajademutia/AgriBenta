plugins {
    // AGP for Android
    id("com.android.application") version "8.7.3" apply false
    
    // Let Flutter handle Kotlin version automatically (resolves conflict)
    id("org.jetbrains.kotlin.android") apply false

    // Firebase plugin
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
// Fix APK path for Flutter CLI (AGP 8.7+ + Gradle 8.9)
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
project.evaluationDependsOn(":app")