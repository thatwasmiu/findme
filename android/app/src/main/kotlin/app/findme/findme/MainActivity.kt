package app.findme.findme

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.quicksettings.TileService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    /**
     * One engine for the life of the process, not one per screen. An engine the activity made itself dies with it,
     * so swiping the app away from Recents would stop Dart, and with it geolocator's service: no more recording, and
     * no more home-screen widget updates. An engine handed over here survives, and the next screen reattaches to it.
     *
     * If [BootReceiver] started a screenless engine after a reboot, stop it first: two engines would both write the
     * tracker's queue file. This screen's engine resumes tracking itself.
     * ponytail: a fix the boot engine was writing at this moment can be lost; run `main` in that engine if gaps show up.
     */
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        cache.get(BootReceiver.ENGINE)?.destroy()
        cache.remove(BootReceiver.ENGINE)
        return cache.get(ENGINE)
            ?: FlutterEngine(context.applicationContext).also {
                TripBridge.attach(context, it)
                cache.put(ENGINE, it)
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        askPicker(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        askPicker(intent)
    }

    /** The tile's long-press (or a tap that needs a screen): open the trip presets. */
    private fun askPicker(intent: Intent?) {
        if (intent?.action != TileService.ACTION_QS_TILE_PREFERENCES &&
            intent?.getBooleanExtra(TripBridge.EXTRA_PICKER, false) != true
        ) {
            return
        }
        val running = FlutterEngineCache.getInstance().get(ENGINE)
        if (running != null) TripBridge.command(running, "picker") else TripBridge.pickerAsked = true
    }

    companion object {
        const val ENGINE = "findme.app"
    }
}
