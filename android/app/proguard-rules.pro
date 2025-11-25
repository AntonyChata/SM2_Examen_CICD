# --- TensorFlow Lite GPU (mantener clases necesarias) ---
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# --- TFLite Flutter plugin ---
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class * {
    @org.tensorflow.lite.** <fields>;
}

# --- Evitar remover clases usadas por reflexión ---
-keepattributes Signature
-keepattributes *Annotation*
