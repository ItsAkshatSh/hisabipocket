package com.example.hisabi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class HisabiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hisabi_widget)

            val widgetData = HomeWidgetPlugin.getData(context)
            val summaryJson = widgetData.getString("widget_summary", "{}")
            val obj = JSONObject(summaryJson ?: "{}")
            val total = obj.optDouble("totalThisMonth", 0.0)
            val topStore = obj.optString("topStore", "—")

            views.setTextViewText(R.id.tvTotal, formatCurrency(total))
            views.setTextViewText(R.id.tvTopStore, "Top: $topStore")

            val openDashboardIntent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://open_dashboard")
            )
            views.setOnClickPendingIntent(R.id.root, openDashboardIntent)

            val openVoiceIntent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://quick_voice_add")
            )
            views.setOnClickPendingIntent(R.id.btnMic, openVoiceIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun formatCurrency(value: Double): String {
        // Adjust currency formatting as needed
        return "USD " + String.format("%,.0f", value)
    }
}






