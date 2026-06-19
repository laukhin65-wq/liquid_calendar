package com.example.liquid_calendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.util.Calendar

class DateWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            updateWidget(context, manager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_ADD_EVENT -> openAddEvent(context)
            ACTION_ADD_TASK -> openAddTask(context)
            ACTION_UPDATE -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(ComponentName(context, DateWidgetProvider::class.java))
                for (id in ids) {
                    updateWidget(context, manager, id)
                }
            }
        }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_date)
        val cal = Calendar.getInstance()
        val day = cal.get(Calendar.DAY_OF_MONTH)
        val monthShort = getMonthShort(cal.get(Calendar.MONTH))

        views.setTextViewText(R.id.widget_day, "$day")
        views.setTextViewText(R.id.widget_month, monthShort)

        // Тап на виджет → открыть приложение
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val launchPending = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchPending)

        // Долгое нажатие через context menuhandled via IntentService
        val eventIntent = Intent(context, DateWidgetProvider::class.java).apply {
            action = ACTION_ADD_EVENT
        }
        val eventPending = PendingIntent.getBroadcast(
            context, 1, eventIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val taskIntent = Intent(context, DateWidgetProvider::class.java).apply {
            action = ACTION_ADD_TASK
        }
        val taskPending = PendingIntent.getBroadcast(
            context, 2, taskIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Кнопки быстрого доступа (видны при long-press через Activity)
        views.setOnClickPendingIntent(R.id.btn_add_event, eventPending)
        views.setOnClickPendingIntent(R.id.btn_add_task, taskPending)

        manager.updateAppWidget(id, views)
    }

    private fun openAddEvent(context: Context) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_EVENT"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(intent)
    }

    private fun openAddTask(context: Context) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_TASK"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(intent)
    }

    private fun getMonthShort(month: Int): String {
        val months = arrayOf("ЯНВ", "ФЕВ", "МАР", "АПР", "МАЯ", "ИЮН", "ИЮЛ", "АВГ", "СЕН", "ОКТ", "НОЯ", "ДЕК")
        return months[month]
    }

    companion object {
        const val ACTION_ADD_EVENT = "com.example.liquid_calendar.ADD_EVENT"
        const val ACTION_ADD_TASK = "com.example.liquid_calendar.ADD_TASK"
        const val ACTION_UPDATE = "com.example.liquid_calendar.UPDATE_WIDGET"

        fun updateAllWidgets(context: Context) {
            val intent = Intent(context, DateWidgetProvider::class.java).apply {
                action = ACTION_UPDATE
            }
            context.sendBroadcast(intent)
        }
    }
}
