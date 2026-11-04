package app.findme.findme

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    /**
     * Runs before this screen's Dart starts. If [BootReceiver] started a screenless engine after a reboot, stop it:
     * two engines would both write the tracker's queue file. This screen's engine resumes tracking itself.
     * ponytail: a fix the boot engine was writing at this moment can be lost; hand that engine to this activity
     * (provideFlutterEngine) if gaps show up.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val cache = FlutterEngineCache.getInstance()
        cache.get(BootReceiver.ENGINE)?.destroy()
        cache.remove(BootReceiver.ENGINE)
        super.configureFlutterEngine(flutterEngine)
    }
}
