import com.android.build.gradle.BaseExtension

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
subprojects {
    project.evaluationDependsOn(":app")
}

// AGP 9.0.1 rejects androidx.core 1.19.0 (needs AGP 9.1.0+).
// 1.16.0 is AGP-9.0.1-compatible but requires compileSdk >= 35.
subprojects {
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.core:core:1.16.0")
            force("androidx.core:core-ktx:1.16.0")
        }
    }

    val bumpCompileSdk = {
        extensions.findByType(BaseExtension::class.java)?.compileSdkVersion(37)
    }
    // evaluationDependsOn(":app") may already have evaluated some projects.
    if (state.executed) {
        bumpCompileSdk()
    } else {
        afterEvaluate { bumpCompileSdk() }
    }
}

tasks.register("clean") {
    delete(rootProject.layout.buildDirectory)
}
