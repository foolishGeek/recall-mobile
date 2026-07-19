# Flutter / plugin keep rules for release R8.
# Enables minify + resource shrinking without stripping billing/auth.

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# RevenueCat / Purchases
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Supabase / GoTrue / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Sentry
-keep class io.sentry.** { *; }
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
