package com.tasheel.tasheel_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ContinueListeningWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_continue_listening).apply {
                val title = widgetData.getString("last_lesson_title", null)
                    ?: widgetData.getString("flutter.last_lesson_title", "شرح كتاب التوحيد")
                    ?: "شرح كتاب التوحيد"

                val subtitle = widgetData.getString("last_lesson_subtitle", null)
                    ?: widgetData.getString("flutter.last_lesson_subtitle", "الشيخ بن عثيمين • الدرس الأول")
                    ?: "الشيخ بن عثيمين • الدرس الأول"

                val progress = widgetData.getInt("last_lesson_progress", -1).let {
                    if (it < 0) widgetData.getInt("flutter.last_lesson_progress", 0) else it
                }

                val lessonId = widgetData.getString("last_lesson_id", "")
                    ?: widgetData.getString("flutter.last_lesson_id", "")
                    ?: ""

                val seriesId = widgetData.getString("last_series_id", "")
                    ?: widgetData.getString("flutter.last_series_id", "")
                    ?: ""

                setTextViewText(R.id.widget_lesson_title, title)
                setTextViewText(R.id.widget_lesson_subtitle, subtitle)
                setTextViewText(R.id.widget_progress_text, "$progress%")
                setProgressBar(R.id.widget_progress_bar, 100, progress, false)

                val uri = Uri.parse("tasheel://play_lesson?lessonId=$lessonId&seriesId=$seriesId")
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    uri
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_btn_play, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

