package com.example.hisabipocket

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import com.example.hisabipocket.R

class ExpenseTrendWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.expense_trend_widget)
            val widgetData = HomeWidgetPlugin.getData(context)
            val summaryJson = widgetData.getString("widget_summary", "{}")
            val obj = JSONObject(summaryJson ?: "{}")
            
            val trendObj = obj.optJSONObject("expenseTrend")
            if (trendObj != null) {
                val isUp = trendObj.optBoolean("isUp", false)
                val change = trendObj.optDouble("monthlyChange", 0.0)
                
                val color = if (isUp) Color.parseColor("#EF4444") else Color.parseColor("#10B981")
                val sign = if (change >= 0) "+" else ""
                
                views.setTextViewText(R.id.tvTrendValue, "$sign${String.format("%.1f", change)}%")
                views.setTextColor(R.id.tvTrendValue, color)
                
                views.setImageViewResource(R.id.ivTrendIcon, if (isUp) android.R.drawable.arrow_up_float else android.R.drawable.arrow_down_float)
                views.setInt(R.id.ivTrendIcon, "setColorFilter", color)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
