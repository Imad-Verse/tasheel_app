package com.tasheel.tasheel_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class DailyBenefitWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_NEXT_BENEFIT = "com.tasheel.tasheel_app.ACTION_NEXT_BENEFIT"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_NEXT_BENEFIT) {
            val prefs = HomeWidgetPlugin.getData(context)
            val total = prefs.getInt("benefit_count", 0).let {
                if (it <= 0) prefs.getInt("flutter.benefit_count", 0) else it
            }
            val currentIndex = prefs.getInt("widget_benefit_current_index", 0)
            val nextIndex = if (total > 0) (currentIndex + 1) % total else 0
            prefs.edit().putInt("widget_benefit_current_index", nextIndex).apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, DailyBenefitWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds, prefs)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val currentIndex = widgetData.getInt("widget_benefit_current_index", 0)

        val text = widgetData.getString("benefit_${currentIndex}_text", null)
            ?: widgetData.getString("flutter.benefit_${currentIndex}_text", null)
            ?: widgetData.getString("benefit_text", null)
            ?: widgetData.getString("flutter.benefit_text", "العلم قال الله قال رسوله، قال الصحابة هم أولو العرفان")
            ?: "العلم قال الله قال رسوله، قال الصحابة هم أولو العرفان"

        val source = widgetData.getString("benefit_${currentIndex}_source", null)
            ?: widgetData.getString("flutter.benefit_${currentIndex}_source", null)
            ?: widgetData.getString("benefit_source", null)
            ?: widgetData.getString("flutter.benefit_source", "ابن القيم رحمه الله")
            ?: "ابن القيم رحمه الله"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_benefit).apply {
                setTextViewText(R.id.widget_benefit_text, text)
                setTextViewText(R.id.widget_benefit_source, "— $source")

                val openIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("tasheel://notes")
                )
                setOnClickPendingIntent(R.id.widget_container, openIntent)

                val refreshIntent = Intent(context, DailyBenefitWidgetProvider::class.java).apply {
                    action = ACTION_NEXT_BENEFIT
                }
                val pendingRefresh = PendingIntent.getBroadcast(
                    context,
                    widgetId,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_refresh, pendingRefresh)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

