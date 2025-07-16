# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep iText PDF classes
-keep class com.itextpdf.** { *; }
-dontwarn com.itextpdf.**

# Keep BouncyCastle classes
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Keep Apache Commons classes
-keep class org.apache.commons.** { *; }
-dontwarn org.apache.commons.**

# Keep OkHttp classes
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep JSON classes
-keep class org.json.** { *; }
-dontwarn org.json.**

# Keep certificate and crypto related classes
-keep class java.security.** { *; }
-keep class javax.crypto.** { *; }
-keep class java.security.cert.** { *; }

# Keep native method signatures
-keepclassmembers class * {
    native <methods>;
}

# Keep Flutter related classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep signature related classes
-keep class com.example.firmador.crypto.** { *; }
-keep class com.example.firmador.signature.** { *; }

# Keep attributes needed for PDF signing
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod 