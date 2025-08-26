# --- Keep Mediapipe protos ---
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# --- Keep Protobuf generated classes ---
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# --- Keep AutoValue (used by protobuf, mediapipe, etc.) ---
-keep class com.google.auto.value.** { *; }
-dontwarn com.google.auto.value.**

# --- Keep BouncyCastle (for OkHttp / TLS) ---
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# --- Keep Conscrypt (another TLS provider) ---
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**

# --- Keep OpenJSSE (TLS) ---
-keep class org.openjsse.** { *; }
-dontwarn org.openjsse.**

# --- Keep javax.lang.model (Java annotation APIs) ---
-keep class javax.lang.model.** { *; }
-dontwarn javax.lang.model.**
