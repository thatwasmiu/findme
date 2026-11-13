package app.findme.findme

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * The "Chuyến đi" Quick Settings tile: a record button. Off: a tap starts a trip with the last preset ("1 giờ" the
 * first time). On: shows the time left; a tap ends the trip. A long-press opens the app on the presets (the
 * QS_TILE_PREFERENCES intent on MainActivity). Always-on accounts: unavailable.
 */
class TripTileService : TileService() {
    override fun onStartListening() {
        live = this
        render()
    }

    override fun onStopListening() {
        if (live === this) live = null
    }

    override fun onClick() {
        val c = applicationContext
        if (TripBridge.tripMode(c) && (TripBridge.recording(c) || TripBridge.ready(c))) {
            TripBridge.send(c, "toggle")
        } else {
            open()
        }
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun open() {
        val i = TripBridge.pickerIntent(this)
        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(PendingIntent.getActivity(this, 0, i, PendingIntent.FLAG_IMMUTABLE))
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(i)
        }
    }

    fun render() {
        val t = qsTile ?: return
        val c = applicationContext
        val (state, sub) = when {
            !TripBridge.tripMode(c) -> Tile.STATE_UNAVAILABLE to "Luôn bật"
            TripBridge.recording(c) -> Tile.STATE_ACTIVE to TripBridge.left(c)
            else -> Tile.STATE_INACTIVE to "Bắt đầu"
        }
        t.label = "Chuyến đi"
        t.state = state
        if (Build.VERSION.SDK_INT >= 29) t.subtitle = sub
        t.updateTile()
    }

    companion object {
        /** The tile while its panel is open, so a trip that starts or ends redraws it at once. */
        @Volatile
        var live: TripTileService? = null
    }
}
