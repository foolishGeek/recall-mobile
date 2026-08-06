# Flutter / plugin keep rules for release R8.
# Enables minify + resource shrinking without stripping billing/auth.

# FlutterEngine resolves this by name via Class.forName in GeneratedPluginRegister,
# and swallows a miss — losing it silently unregisters every plugin. The rest of the
# embedding protects its JNI surface with @androidx.annotation.Keep.
-keep class io.flutter.plugins.GeneratedPluginRegistrant {
    public static void registerWith(io.flutter.embedding.engine.FlutterEngine);
}

# RevenueCat / Purchases (the SDK's own consumer rules keep com.revenuecat.**)
-dontwarn com.revenuecat.purchases.**

# Supabase / GoTrue / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Sentry (sentry_flutter ships an identical keep in its consumer rules)
-dontwarn io.sentry.**

# Gson / serialization used by plugins
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Play Core in-app updates
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Repackage (Play App optimisation → "Repackage classes")
-repackageclasses 'app.recall.r8'
-allowaccessmodification
