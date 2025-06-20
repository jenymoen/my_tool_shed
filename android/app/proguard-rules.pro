# Flutter-specific ProGuard rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.lumin.my_tool_shed.** { *; }

# Keep Play Core classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; } 