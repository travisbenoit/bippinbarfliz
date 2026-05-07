# Radar SDK ships with a Huawei HMS location client that is never used on
# Google Play builds. Suppress the missing-class errors from R8.
-dontwarn com.huawei.**
-keep class com.huawei.** { *; }
