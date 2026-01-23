package com.example.hisabipocket

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import com.example.hisabipocket.R

class HisabiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hisabi_widget)

            val widgetData = HomeWidgetPlugin.getData(context)
            val summaryJson = widgetData.getString("widget_summary", "{}")
            val obj = JSONObject(summaryJson ?: "{}")
            
            // Get currency code
            val currencyCode: String = widgetData.getString("currency_code", "USD") ?: "USD"
            
            // Get widget settings
            val settingsJson = widgetData.getString("widget_settings", "{}")
            val settingsObj = JSONObject(settingsJson ?: "{}")
            val enabledStatsArray = settingsObj.optJSONArray("enabledStats")
            val enabledStats = if (enabledStatsArray != null) {
                (0 until enabledStatsArray.length()).map { enabledStatsArray.getString(it) }.toSet()
            } else {
                // Default to totalThisMonth and topStore if no settings
                setOf("totalThisMonth", "topStore")
            }

            // Extract all stats from summary
            val total = obj.optDouble("totalThisMonth", 0.0)
            val topStore = obj.optString("topStore", "—")
            val receiptsCount = obj.optInt("receiptsCount", 0)
            val averagePerReceipt = obj.optDouble("averagePerReceipt", 0.0)
            val daysWithExpenses = obj.optInt("daysWithExpenses", 0)
            val totalItems = obj.optInt("totalItems", 0)

            // Show/hide and set text for each stat based on settings
            if (enabledStats.contains("totalThisMonth")) {
                views.setViewVisibility(R.id.tvTotal, View.VISIBLE)
                views.setTextViewText(R.id.tvTotal, formatCurrency(total, currencyCode))
            } else {
                views.setViewVisibility(R.id.tvTotal, View.GONE)
            }

            if (enabledStats.contains("topStore")) {
                views.setViewVisibility(R.id.tvTopStore, View.VISIBLE)
                views.setTextViewText(R.id.tvTopStore, "Top: $topStore")
            } else {
                views.setViewVisibility(R.id.tvTopStore, View.GONE)
            }

            if (enabledStats.contains("receiptsCount")) {
                views.setViewVisibility(R.id.tvReceiptsCount, View.VISIBLE)
                views.setTextViewText(R.id.tvReceiptsCount, "Receipts: $receiptsCount")
            } else {
                views.setViewVisibility(R.id.tvReceiptsCount, View.GONE)
            }

            if (enabledStats.contains("averagePerReceipt")) {
                views.setViewVisibility(R.id.tvAverage, View.VISIBLE)
                views.setTextViewText(R.id.tvAverage, "Avg: ${formatCurrency(averagePerReceipt, currencyCode)}")
            } else {
                views.setViewVisibility(R.id.tvAverage, View.GONE)
            }

            if (enabledStats.contains("daysWithExpenses")) {
                views.setViewVisibility(R.id.tvDays, View.VISIBLE)
                views.setTextViewText(R.id.tvDays, "Days: $daysWithExpenses")
            } else {
                views.setViewVisibility(R.id.tvDays, View.GONE)
            }

            if (enabledStats.contains("totalItems")) {
                views.setViewVisibility(R.id.tvItems, View.VISIBLE)
                views.setTextViewText(R.id.tvItems, "Items: $totalItems")
            } else {
                views.setViewVisibility(R.id.tvItems, View.GONE)
            }

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

    private fun formatCurrency(value: Double, currencyCode: String = "USD"): String {
        return "${currencyCode} ${String.format("%,.2f", value)}"
    }
}
