package app.findme.findme

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.service.quicksettings.TileService
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Trip mode on Android (lib/features/tracker/data/trip_channel.dart is the other end, channel "findme/trip").
 * Dart owns the trip; this file only:
 * - sets the alarm that stops GPS at the trip's end ("sync"), and redraws the tile and the widget button;
 * - hands taps on the tile / widget and the alarm to Dart ("toggle", "expire"), in the engine that already runs,
 *   or in a new screenless one (never two engines: both would write the tracker's queue file).
 * State is read from Dart's own prefs (FlutterSharedPreferences, keys "flutter.findme.*").
 */
object TripBridge {
    const val CHANNEL = "findme/trip"
    const val ACTION_TOGGLE = "app.findme.trip.TOGGLE"
    const val ACTION_EXPIRE = "app.findme.trip.EXPIRE"
    const val EXTRA_PICKER = "findme.tripPicker"

    /** The app was opened by the tile's long-press before Dart ran: Dart asks once ("takePicker"). */
    @Volatile
    var pickerAsked = false

    private fun prefs(c: Context): SharedPreferences =
        c.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    fun tripMode(c: Context) = prefs(c).getString("flutter.findme.sharing", null) == "trip"

    fun recording(c: Context) = prefs(c).getBoolean("flutter.findme.tracking", false)

    /**
     * A trip can start without a screen: location "all the time" is granted and the disclosure was accepted.
     * Otherwise the tap opens the app on the presets, which asks.
     */
    fun ready(c: Context): Boolean {
        val perm = if (Build.VERSION.SDK_INT >= 29) {
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        } else {
            Manifest.permission.ACCESS_FINE_LOCATION
        }
        return c.checkSelfPermission(perm) == PackageManager.PERMISSION_GRANTED &&
            prefs(c).getBoolean("flutter.findme.trackerDisclosure", false)
    }

    /** "còn 42 phút" / "đến khi tắt": same words as `tripLeft` in lib/features/tracker/domain/trip.dart. */
    fun left(c: Context, nowMs: Long = System.currentTimeMillis()): String {
        val until = prefs(c).getLong("flutter.findme.tripUntil", 0L)
        if (until == 0L) return "đến khi tắt"
        val s = (until - nowMs) / 1000
        val m = if (s <= 0) 0 else (s + 59) / 60
        if (m < 60) return "còn $m phút"
        val rest = m % 60
        return if (rest == 0L) "còn ${m / 60} giờ" else "còn ${m / 60} giờ $rest phút"
    }

    fun pickerIntent(c: Context): Intent =
        Intent(c, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .putExtra(EXTRA_PICKER, true)

    /** Listens for Dart's calls on [engine]. Every engine this app makes gets it. */
    fun attach(context: Context, engine: FlutterEngine) {
        val app = context.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sync" -> {
                    schedule(app, (call.arguments as? Number)?.toLong())
                    refresh(app)
                    result.success(null)
                }
                "takePicker" -> {
                    result.success(pickerAsked)
                    pickerAsked = false
                }
                else -> result.notImplemented()
            }
        }
    }

    fun command(engine: FlutterEngine, cmd: String) =
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod(cmd, null)

    /** [cmd] to Dart: the engine that runs (the app's, else the screenless one), else a new screenless one. */
    fun send(context: Context, cmd: String) {
        val cache = FlutterEngineCache.getInstance()
        val engine = cache.get(MainActivity.ENGINE) ?: cache.get(BootReceiver.ENGINE)
        if (engine != null) {
            command(engine, cmd)
            return
        }
        if (cmd == "expire") {
            // Nothing runs, so GPS is already off; only make sure a reboot does not start it again.
            prefs(context).edit()
                .putBoolean("flutter.findme.tracking", false)
                .remove("flutter.findme.tripUntil")
                .apply()
            refresh(context)
            return
        }
        startHeadless(context, "tripCommand", listOf(cmd))
    }

    /** Dart without a screen, on [entrypoint] in lib/main.dart; lives until the process ends or the app opens. */
    fun startHeadless(context: Context, entrypoint: String, args: List<String>? = null) {
        val app = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(app)
        loader.ensureInitializationComplete(app, null)
        val engine = FlutterEngine(app) // registers the plugins (geolocator binds its service here)
        attach(app, engine)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), entrypoint),
            args,
        )
        // Kept here so it is not garbage-collected; MainActivity replaces it with its own when the app opens.
        FlutterEngineCache.getInstance().put(BootReceiver.ENGINE, engine)
    }

    // ponytail: inexact (setAndAllowWhileIdle, no exact-alarm permission): in doze it can ring ~10 min late. The server
    // window is exact anyway; ask for SCHEDULE_EXACT_ALARM if GPS staying on matters.
    private fun schedule(c: Context, atMs: Long?) {
        val am = c.getSystemService(AlarmManager::class.java) ?: return
        val pi = PendingIntent.getBroadcast(
            c,
            1,
            Intent(c, TripReceiver::class.java).setAction(ACTION_EXPIRE),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        if (atMs == null) am.cancel(pi) else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, pi)
    }

    /** Redraws the tile (if its panel is open) and every widget from the prefs. */
    fun refresh(c: Context) {
        TripTileService.live?.render()
        if (Build.VERSION.SDK_INT >= 24) {
            TileService.requestListeningState(c, ComponentName(c, TripTileService::class.java))
        }
        val ids = AppWidgetManager.getInstance(c)
            .getAppWidgetIds(ComponentName(c, TrailWidgetProvider::class.java))
        if (ids.isEmpty()) return
        c.sendBroadcast(
            Intent(c, TrailWidgetProvider::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
        )
    }
}
