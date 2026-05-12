package com.example.waterdays

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

internal object WaterdaysWidgetStore {
    const val prefsName = "waterdays.widget"
    const val drankKey = "drankCups"
    const val goalKey = "goalCups"
    const val currentDateKey = "currentDateKey"
    const val defaultGoal = 8
}

class WaterdaysWidgetProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleMidnightRefresh(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        updateAllWidgets(context)
        scheduleMidnightRefresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH_WIDGET,
            Intent.ACTION_BOOT_COMPLETED,
            AppWidgetManager.ACTION_APPWIDGET_UPDATE,
            AppWidgetManager.ACTION_APPWIDGET_OPTIONS_CHANGED,
            -> {
                updateAllWidgets(context)
                scheduleMidnightRefresh(context)
            }
        }
    }

    companion object {
        const val ACTION_REFRESH_WIDGET = "com.example.waterdays.REFRESH_WIDGET"
        const val EXTRA_LAUNCH_ACTION = "waterdays_launch_action"
        private const val QUICK_ADD_ACTION = "quick_add"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, WaterdaysWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(componentName)
            widgetIds.forEach { widgetId ->
                manager.updateAppWidget(widgetId, buildRemoteViews(context))
            }
        }

        fun scheduleMidnightRefresh(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WaterdaysWidgetProvider::class.java).apply {
                action = ACTION_REFRESH_WIDGET
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                1205,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            alarmManager.cancel(pendingIntent)

            val calendar = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 5)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            alarmManager.setInexactRepeating(
                AlarmManager.RTC,
                calendar.timeInMillis,
                AlarmManager.INTERVAL_DAY,
                pendingIntent,
            )
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(WaterdaysWidgetStore.prefsName, Context.MODE_PRIVATE)
            val goalCups = prefs.getInt(
                WaterdaysWidgetStore.goalKey,
                WaterdaysWidgetStore.defaultGoal,
            ).coerceAtLeast(1)
            val storedDrankCups = prefs.getInt(WaterdaysWidgetStore.drankKey, 0).coerceIn(0, goalCups)
            val storedDateKey = prefs.getString(
                WaterdaysWidgetStore.currentDateKey,
                todayKey(),
            )
            val drankCups = if (storedDateKey == todayKey()) storedDrankCups else 0

            val views = RemoteViews(context.packageName, R.layout.waterdays_widget)
            views.setTextViewText(R.id.widget_status, statusText(context, drankCups, goalCups))
            views.setTextViewText(R.id.widget_count, "$drankCups / $goalCups")
            views.setTextViewText(
                R.id.widget_subtitle,
                context.getString(R.string.widget_goal_format, goalCups),
            )
            views.setProgressBar(R.id.widget_progress, goalCups, drankCups, false)

            views.setOnClickPendingIntent(
                R.id.widget_root,
                launchIntent(context, null, 2201),
            )
            views.setOnClickPendingIntent(
                R.id.widget_add_button,
                launchIntent(context, QUICK_ADD_ACTION, 2202),
            )

            return views
        }

        private fun launchIntent(
            context: Context,
            launchAction: String?,
            requestCode: Int,
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                if (launchAction != null) {
                    putExtra(EXTRA_LAUNCH_ACTION, launchAction)
                }
            }

            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun statusText(context: Context, drankCups: Int, goalCups: Int): String {
            return when {
                drankCups <= 0 -> context.getString(R.string.widget_status_drink_water)
                drankCups >= goalCups -> context.getString(R.string.widget_status_done)
                else -> context.getString(R.string.widget_status_hydrated)
            }
        }

        private fun todayKey(): String {
            return SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        }
    }
}
