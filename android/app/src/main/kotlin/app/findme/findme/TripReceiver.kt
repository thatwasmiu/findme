package app.findme.findme

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** The widget's ⏺/⏹ button and the end-of-trip alarm, both handed to Dart by [TripBridge]. */
class TripReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            TripBridge.ACTION_EXPIRE -> TripBridge.send(context, "expire")
            TripBridge.ACTION_TOGGLE ->
                if (TripBridge.recording(context) || TripBridge.ready(context)) {
                    TripBridge.send(context, "toggle")
                } else {
                    // ponytail: Android may block an activity started from a receiver; the button already opens the
                    // app itself when it was drawn without permission, so this only covers a permission lost since.
                    context.startActivity(TripBridge.pickerIntent(context))
                }
        }
    }
}
