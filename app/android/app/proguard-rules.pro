# Firebase discovers registrars by name from AndroidManifest metadata and invokes
# their no-argument constructors reflectively. Preserve both in release builds.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
