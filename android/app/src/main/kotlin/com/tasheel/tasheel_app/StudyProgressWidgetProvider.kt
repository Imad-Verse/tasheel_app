package com.tasheel.tasheel_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class StudyProgressWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val completed = widgetData.getInt("completed_lessons_count", -1).let {
            if (it < 0) widgetData.getInt("flutter.completed_lessons_count", 0) else it
        }
        val total = widgetData.getInt("total_lessons_count", -1).let {
            if (it < 0) widgetData.getInt("flutter.total_lessons_count", 0) else it
        }
        val percent = widgetData.getInt("overall_progress_percent", -1).let {
            if (it < 0) widgetData.getInt("flutter.overall_progress_percent", 0) else it
        }
        val streak = widgetData.getInt("daily_streak", -1).let {
            if (it < 0) widgetData.getInt("flutter.daily_streak", 1) else it
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_study_progress).apply {
                setTextViewText(R.id.widget_progress_percent, "$percent%")
                setTextViewText(R.id.widget_progress_detail, "$completed من $total درساً")
                val streakText = if (streak > 0) "سلسلة استمرارية $streak أيام" else "واصل وردك اليومي"
                setTextViewText(R.id.widget_progress_streak, streakText)

                val openIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("tasheel://stats")
                )
                setOnClickPendingIntent(R.id.widget_container, openIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

