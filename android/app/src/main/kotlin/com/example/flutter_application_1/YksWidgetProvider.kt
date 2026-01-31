package com.example.flutter_application_1 // <-- BURASI SENİN PAKET ADIN KALACAK

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class YksWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                
                // 1. Gün Verisini Al
                val kalanGun = widgetData.getString("kalan_gun", "--")
                setTextViewText(R.id.widget_count, kalanGun)

                // 2. Progress Bar (Yüzde) Verisini Al
                val progressValue = widgetData.getInt("progress_value", 0)
                setProgressBar(R.id.widget_progress, 100, progressValue, false)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}