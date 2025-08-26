android {
    namespace "com.cabshare.app"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.cabshare.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "0.1.0"
    }

    buildTypes { release { minifyEnabled false } }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.24"
    implementation "androidx.core:core-ktx:1.12.0"
    implementation "androidx.appcompat:1.6.1"
    implementation "com.google.android.material:material:1.10.0"
    // remove any com.android.support:* lines if present
}
