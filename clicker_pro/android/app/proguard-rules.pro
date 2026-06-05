# ProGuard/R8 rules for Clicker Pro release builds.
#
# Flutter + Drift + flutter_secure_storage + connectivity_plus require
# these keep rules to avoid runtime ClassDefNotFoundError / NoSuchMethod.

# ── Flutter engine ──────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# ── Drift (SQLite code generation) ─────────────────────────────────
-keep class drift.** { *; }
-keep class clicker_pro.core.db.** { *; }
-keep class * extends drift.Database { *; }
-keepclassmembers class * extends drift.Database {
    drift.database.** getTableInfo(...);
}

# ── flutter_secure_storage ─────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── connectivity_plus ──────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ── General serialization safety ───────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
