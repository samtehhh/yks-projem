package com.example.flutter_application_1 // <-- BURAYI KONTROL ET

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TytWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val gun = widgetData.getString("tyt_gun", "--")
                val yuzde = widgetData.getInt("tyt_yuzde", 0)
                
                setTextViewText(R.id.widget_title, "TYT 2026")
                setTextViewText(R.id.widget_count, gun)
                setProgressBar(R.id.widget_progress, 100, yuzde, false)
                
                // MAVİ ARKAPLAN
                setInt(R.id.widget_root, "setBackgroundColor", Color.parseColor("#FF2e6eb7"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}   