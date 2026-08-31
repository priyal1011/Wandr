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
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" && (requested.name == "core" || requested.name == "core-ktx")) {
                useVersion("1.15.0")
            }
        }
    }
}

subprojects {
    project.plugins.withId("com.android.library") {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            android.namespace = "com.example.${project.name.replace("-", "_")}"
        }
    }
}

// Nuclear Fix: Remove package attribute from library manifests to please AGP 8.0+
subprojects {
    tasks.withType<org.gradle.api.Task>().configureEach {
        if (name.contains("process") && name.contains("Manifest")) {
            doFirst {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        manifestFile.writeText(content.replace("package=\"[^\"]*\"".toRegex(), ""))
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
