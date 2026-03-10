# Keep Flutter engine
-keep class io.flutter.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }

# Keep Google Play services
-keep class com.google.android.gms.** { *; }

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Don't warn about Flutter
-dontwarn io.flutter.embedding.**