package com.mmamc.bca.bca_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log

class QuickActionsWidget : AppWidgetProvider() {
    
    companion object {
        private const val TAG = "QuickActionsWidget"
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
                Log.d(TAG, "Successfully updated widget $appWidgetId")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $appWidgetId", e)
            }
        }
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "First widget enabled")
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "Last widget disabled")
    }
    
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        Log.d(TAG, "Widgets deleted: ${appWidgetIds.joinToString()}")
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    try {
        val views = RemoteViews(context.packageName, R.layout.quick_actions_widget)

        // Set up click intents for each action
        setClickIntent(context, views, R.id.widget_calendar, "/calendar")
        setClickIntent(context, views, R.id.widget_events, "/events")
        setClickIntent(context, views, R.id.widget_finance, "/finance")
        setClickIntent(context, views, R.id.widget_study, "/study")
        setClickIntent(context, views, R.id.widget_ai, "/ai-assistant")
        setClickIntent(context, views, R.id.widget_pomodoro, "/pomodoro")

        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d("QuickActionsWidget", "Widget $appWidgetId updated successfully")
    } catch (e: Exception) {
        Log.e("QuickActionsWidget", "Error in updateAppWidget", e)
        throw e
    }
}

private fun setClickIntent(
    context: Context,
    views: RemoteViews,
    viewId: Int,
    route: String
) {
    try {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra("route", route)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            viewId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        views.setOnClickPendingIntent(viewId, pendingIntent)
    } catch (e: Exception) {
        Log.e("QuickActionsWidget", "Error setting click intent for $route", e)
    }
}
