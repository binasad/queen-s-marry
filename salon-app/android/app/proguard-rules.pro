# Stripe SDK
-keep class com.stripe.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Kotlin reflection / parcelize used by Stripe
-dontwarn kotlinx.parcelize.Parceler$DefaultImpls
-dontwarn kotlinx.parcelize.Parceler
-dontwarn kotlinx.parcelize.Parcelize
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*, InnerClasses, Signature, EnclosingMethod
-keepclassmembers class * {
    @kotlinx.parcelize.Parcelize <fields>;
}

# Flutter Stripe plugin classes (reflection bridge)
-keep class io.flutter.plugins.** { *; }

# Keep Gson/Moshi/Jackson model classes used by Stripe
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Generic: keep enums (Stripe uses many)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Firebase / Google Play services (used by FCM push)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
