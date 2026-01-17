package com.mmamc.bca.bca_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class QuickActionsWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val views = RemoteViews(context.packageName, R.layout.quick_actions_widget)

    // Set up click intents for each action
    setClickIntent(context, views, R.id.widget_calendar, "/calendar")
    setClickIntent(context, views, R.id.widget_events, "/events")
    setClickIntent(context, views, R.id.widget_finance, "/finance")
    setClickIntent(context, views, R.id.widget_study, "/study")
    setClickIntent(context, views, R.id.widget_ai, "/ai-assistant")
    setClickIntent(context, views, R.id.widget_pomodoro, "/pomodoro")

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

private fun setClickIntent(
    context: Context,
    views: RemoteViews,
    viewId: Int,
    route: String
) {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_VIEW
        putExtra("route", route)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    
    val pendingIntent = PendingIntent.getActivity(
        context,
        viewId,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    
    views.setOnClickPendingIntent(viewId, pendingIntent)
}
