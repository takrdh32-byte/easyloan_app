# Add project specific ProGuard rules here.
# Keep WebView JavaScript Interface
-keepclassmembers class com.quickloan.app.AndroidBridge {
    public *;
}
-keepattributes JavascriptInterface

# Keep WebView related classes
-keep class android.webkit.** { *; }

# Keep Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# AndroidX
-keep class androidx.** { *; }
