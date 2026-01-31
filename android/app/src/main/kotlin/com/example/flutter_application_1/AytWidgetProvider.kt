package com.example.flutter_application_1 // <-- PAKET ADINI KONTROL ET

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AytWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val gun = widgetData.getString("ayt_gun", "--")
                val yuzde = widgetData.getInt("ayt_yuzde", 0)
                
                setTextViewText(R.id.widget_title, "AYT 2026")
                setTextViewText(R.id.widget_count, gun)
                setProgressBar(R.id.widget_progress, 100, yuzde, false)
                
                // Kırmızı/Bordo Arkaplan
                setInt(R.id.widget_root, "setBackgroundColor", Color.parseColor("#FFe11111"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}