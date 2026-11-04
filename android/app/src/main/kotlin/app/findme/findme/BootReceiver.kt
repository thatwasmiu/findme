package app.findme.findme

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

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

        val app = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(app)
        loader.ensureInitializationComplete(app, null)
        val engine = FlutterEngine(app) // registers the plugins (geolocator binds its service here)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "trackerBoot"),
        )
        // Kept here so it is not garbage-collected; it lives until the process ends.
        FlutterEngineCache.getInstance().put(ENGINE, engine)
    }

    companion object {
        const val ENGINE = "findme.tracker"
    }
}
