package com.example.liquid_calendar

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

class DayWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            updateWidget(context, manager, id)
        }
        scheduleMidnightUpdate(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_UPDATE, ACTION_MIDNIGHT_UPDATE -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(ComponentName(context, DayWidgetProvider::class.java))
                for (id in ids) {
                    updateWidget(context, manager, id)
                }
                if (intent.action == ACTION_MIDNIGHT_UPDATE) {
                    scheduleMidnightUpdate(context)
                }
            }
        }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_day)
        val cal = Calendar.getInstance()

        // Тема виджета по выбору в приложении (light/dark/system).
        views.setInt(R.id.widget_root, "setBackgroundResource", WidgetTheme.bgRes(context))
        val primaryText = WidgetTheme.primaryText(context)
        val secondaryText = WidgetTheme.secondaryText(context)

        val day = cal.get(Calendar.DAY_OF_MONTH)
        val weekday = getWeekdayName(cal.get(Calendar.DAY_OF_WEEK))

        views.setTextViewText(R.id.widget_day, "$day")
        views.setTextViewText(R.id.widget_weekday, weekday)
        views.setTextColor(R.id.widget_weekday, 0xFFFF3B30.toInt())
        views.setTextColor(R.id.widget_day, primaryText)

        val prefs = context.getSharedPreferences("widget_events", Context.MODE_PRIVATE)
        val eventsJson = prefs.getString("day_events", "[]") ?: "[]"
        Log.d("DayWidget", "Raw events: $eventsJson")

        val eventCount = try {
            val jsonArray = JSONArray(eventsJson)
            val count = minOf(jsonArray.length(), 3)

            for (i in 0 until 4) {
                val slotId = context.resources.getIdentifier("event_slot_$i", "id", context.packageName)
                if (i < count) {
                    val item = jsonArray.get(i)
                    val time: String
                    val title: String
                    val color: Int
                    val eventId: String
                    val isTask: Boolean
                    val isCompleted: Boolean

                    if (item is org.json.JSONObject) {
                        time = item.optString("time", "")
                        title = item.optString("title", "")
                        color = item.optLong("color", 0xFF4A90D9L).toInt()
                        eventId = item.optString("id", "")
                        isTask = item.optBoolean("isTask", false)
                        isCompleted = item.optBoolean("isCompleted", false)
                    } else {
                        time = ""
                        title = item.toString()
                        color = 0xFF4A90D9.toInt()
                        eventId = ""
                        isTask = false
                        isCompleted = false
                    }

                    views.setViewVisibility(slotId, View.VISIBLE)

                    val dotId = context.resources.getIdentifier("dot_$i", "id", context.packageName)
                    val density = context.resources.displayMetrics.density
                    val dotSize = (8 * density).toInt()
                    val bitmap = android.graphics.Bitmap.createBitmap(dotSize, dotSize, android.graphics.Bitmap.Config.ARGB_8888)
                    val canvas = android.graphics.Canvas(bitmap)
                    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
                    paint.color = color
                    canvas.drawCircle(dotSize / 2f, dotSize / 2f, dotSize / 2f, paint)
                    views.setImageViewBitmap(dotId, bitmap)

                    val titleId = context.resources.getIdentifier("title_$i", "id", context.packageName)
                    views.setTextViewText(titleId, title)
                    views.setTextColor(titleId, primaryText)
                    if (isTask && isCompleted) {
                        views.setInt(titleId, "setPaintFlags", Paint.STRIKE_THRU_TEXT_FLAG.toInt() or Paint.ANTI_ALIAS_FLAG.toInt())
                    } else {
                        views.setInt(titleId, "setPaintFlags", Paint.ANTI_ALIAS_FLAG.toInt())
                    }

                    val timeId = context.resources.getIdentifier("time_$i", "id", context.packageName)
                    views.setTextViewText(timeId, time)
                    views.setTextColor(timeId, secondaryText)

                    val eventIntent = Intent(context, MainActivity::class.java).apply {
                        action = "OPEN_EVENT"
                        data = Uri.parse("liquidcalendar://day_event/$eventId/$i/${System.nanoTime()}")
                        putExtra("event_id", eventId)
                        putExtra("slot_index", i)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val eventPending = PendingIntent.getActivity(
                        context, 10 + i, eventIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(slotId, eventPending)
                } else {
                    views.setViewVisibility(slotId, View.GONE)
                }
            }
            count
        } catch (e: Exception) {
            Log.e("DayWidget", "Parse error: ${e.message}")
            for (i in 0 until 4) {
                val slotId = context.resources.getIdentifier("event_slot_$i", "id", context.packageName)
                views.setViewVisibility(slotId, View.GONE)
            }
            0
        }

        if (eventCount == 0) {
            views.setTextColor(R.id.widget_events_text, secondaryText)
            views.setViewVisibility(R.id.widget_events_text, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_events_text, View.GONE)
        }

        val addIntent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_EVENT"
            data = Uri.parse("liquidcalendar://day_add/$id/${System.nanoTime()}")
            putExtra("widget_id", id)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addPending = PendingIntent.getActivity(
            context, 20, addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_add_container, addPending)

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = "OPEN_CALENDAR"
            data = Uri.parse("liquidcalendar://day_open/$id/${System.nanoTime()}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val launchPending = PendingIntent.getActivity(
            context, 30, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchPending)

        manager.updateAppWidget(id, views)
    }

    private fun scheduleMidnightUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, DayWidgetProvider::class.java).apply {
            action = ACTION_MIDNIGHT_UPDATE
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.cancel(pendingIntent)

        val midnight = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                midnight.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                midnight.timeInMillis,
                pendingIntent
            )
        }
        Log.d("DayWidget", "Midnight alarm scheduled for: ${midnight.time}")
    }

    private fun getWeekdayName(day: Int): String {
        val cal = Calendar.getInstance(java.util.Locale.getDefault())
        cal.firstDayOfWeek = Calendar.MONDAY
        cal.set(Calendar.DAY_OF_WEEK, day)
        return java.text.SimpleDateFormat("EEEE", java.util.Locale.getDefault())
            .format(cal.time)
            .uppercase()
    }

    companion object {
        const val ACTION_UPDATE = "com.example.liquid_calendar.UPDATE_DAY_WIDGET"
        const val ACTION_MIDNIGHT_UPDATE = "com.example.liquid_calendar.MIDNIGHT_UPDATE"

        fun updateAllWidgets(context: Context) {
            val intent = Intent(context, DayWidgetProvider::class.java).apply {
                action = ACTION_UPDATE
            }
            context.sendBroadcast(intent)
        }
    }
}
