package app.findme.findme

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The home-screen widget. Dart draws the picture (lib/features/widget); this only shows it and works out the age,
 * which has to keep moving when Dart is not running.
 */
class TrailWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val bitmap = widgetData.getString(KEY_PNG, null)?.let { BitmapFactory.decodeFile(it) }
        val lastFix = widgetData.getLong(KEY_LAST_FIX, 0L)
        val shown = bitmap != null && lastFix > 0L

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.trail_widget)
            views.setOnClickPendingIntent(
                R.id.trail_widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            views.setViewVisibility(R.id.trail_widget_map, if (shown) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.trail_widget_age, if (shown) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.trail_widget_credit, if (shown) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.trail_widget_empty, if (shown) View.GONE else View.VISIBLE)
            if (shown) {
                views.setImageViewBitmap(R.id.trail_widget_map, bitmap)
                views.setTextViewText(
                    R.id.trail_widget_age,
                    agoLabel(System.currentTimeMillis(), lastFix),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        private const val KEY_PNG = "findme.widget.png"
        private const val KEY_LAST_FIX = "findme.widget.lastFix"

        /** Same words and rounding as `ago()` in lib/core/time/format.dart. */
        fun agoLabel(nowMs: Long, thenMs: Long): String {
            val min = Math.round((nowMs - thenMs) / 60000.0)
            if (min < 1) return "vừa xong"
            if (min < 60) return "$min phút trước"
            val h = Math.round(min / 60.0)
            if (h < 24) return "$h giờ trước"
            return "${Math.round(h / 24.0)} ngày trước"
        }
    }
}
