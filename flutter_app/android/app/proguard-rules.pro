# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase / Crashlytics
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# JSON serialization (Dart → Java bridge)
-keep class _InternalLinkedHashMap<*, *> { *; }
-keep class com.fasterxml.jackson.** { *; }

# Network
-keep class com.android.volley.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep enum classes
-keepclassmembers enum * { *; }
