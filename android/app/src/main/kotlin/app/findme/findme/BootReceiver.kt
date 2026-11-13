package app.findme.findme

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngineCache

/**
 * After a reboot, if tracking was on, start Dart without a screen (`trackerBoot` in lib/main.dart): it resumes the
 * tracker, whose GPS runs in geolocator's foreground service with the "Find Me đang ghi hành trình" notification.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        // The tracker's on/off flag: a SharedPreferences bool written by Dart (key "findme.tracking").
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.findme.tracking", false)) return
        if (FlutterEngineCache.getInstance().contains(ENGINE)) return
        TripBridge.startHeadless(context, "trackerBoot")
    }

    companion object {
        const val ENGINE = "findme.tracker"
    }
}
