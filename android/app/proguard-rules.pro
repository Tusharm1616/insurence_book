# Keep OkHttp (used by Dio under the hood)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Dio
-keep class io.flutter.** { *; }
-keep class com.example.** { *; }

# Keep Flutter secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Prevent stripping of classes used via reflection
-keep class * implements java.io.Serializable { *; }
