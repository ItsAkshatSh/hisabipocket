package com.example.hisabipocket

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import com.example.hisabipocket.R

class SavingsGoalWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.savings_goal_widget)
            val widgetData = HomeWidgetPlugin.getData(context)
            val summaryJson = widgetData.getString("widget_summary", "{}")
            val obj = JSONObject(summaryJson ?: "{}")
            
            val goalObj = obj.optJSONObject("savingsGoal")
            if (goalObj != null) {
                val title = goalObj.optString("title", "Goal")
                val target = goalObj.optDouble("targetAmount", 1.0)
                val current = goalObj.optDouble("currentAmount", 0.0)
                val progress = ((current / target) * 100).toInt()

                views.setTextViewText(R.id.tvGoalTitle, title)
                views.setProgressBar(R.id.pbGoal, 100, progress, false)
                views.setTextViewText(R.id.tvProgress, "$progress%")
                
                val currencyCode = widgetData.getString("currency_code", "USD") ?: "USD"
                views.setTextViewText(R.id.tvAmount, "${formatValue(current, currencyCode)} / ${formatValue(target, currencyCode)}")
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun formatValue(value: Double, currencyCode: String): String {
        return "$currencyCode ${String.format("%.0f", value)}"
    }
}
