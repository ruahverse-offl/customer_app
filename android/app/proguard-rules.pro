# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepclassmembers class * { @androidx.annotation.Keep <fields>; }
-keepclassmembers class * { @androidx.annotation.Keep <methods>; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Razorpay
-keepclasseswithmembers class * { public <init>(android.content.Context, android.util.AttributeSet); }
-keepclasseswithmembers class * { public <init>(android.content.Context, android.util.AttributeSet, int); }
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-optimizations !method/inlining/*
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.google.android.gms.**
-keepclassmembers class * { @android.webkit.JavascriptInterface <methods>; }
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers
-keep @proguard.annotation.Keep class * {*;}
-keep @proguard.annotation.KeepClassMembers class * { <fields>; <methods>; }

# PDF / Printing
-keep class com.shockwave.** { *; }

# Suppress R8 warnings for missing optional classes
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
