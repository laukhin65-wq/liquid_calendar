package com.example.liquid_calendar

import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import java.util.Calendar

class CompactWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var days = listOf<DayInfo>()

    data class DayInfo(val dayNumber: Int, val isToday: Boolean, val hasHoliday: Boolean)

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val cal = Calendar.getInstance()
        cal.firstDayOfWeek = Calendar.MONDAY
        val year = cal.get(Calendar.YEAR)
        val month = cal.get(Calendar.MONTH)
        val daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH)

        val firstDay = Calendar.getInstance()
        firstDay.firstDayOfWeek = Calendar.MONDAY
        firstDay.set(year, month, 1)
        val startOffset = (firstDay.get(Calendar.DAY_OF_WEEK) + 5) % 7

        val prefs = context.getSharedPreferences("widget_events", Context.MODE_PRIVATE)
        val eventsJson = prefs.getString("day_events_detail", "[]") ?: "[]"

        val holidayDays = mutableSetOf<Int>()
        try {
            val jsonArray = JSONArray(eventsJson)
            for (i in 0 until jsonArray.length()) {
                val item = jsonArray.get(i)
                if (item is org.json.JSONObject) {
                    val category = item.optInt("category", -1)
                    val dayNum = item.optInt("day", 0)
                    if (category == 7 && dayNum > 0) {
                        holidayDays.add(dayNum)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("CompactWidgetFactory", "Parse error: ${e.message}")
        }

        val result = mutableListOf<DayInfo>()

        for (i in 0 until startOffset) {
            result.add(DayInfo(0, false, false))
        }

        for (day in 1..daysInMonth) {
            val isToday = day == cal.get(Calendar.DAY_OF_MONTH) &&
                    month == cal.get(Calendar.MONTH) &&
                    year == cal.get(Calendar.YEAR)
            result.add(DayInfo(day, isToday, holidayDays.contains(day)))
        }

        while (result.size % 7 != 0) {
            result.add(DayInfo(0, false, false))
        }

        days = result
        Log.d("CompactWidgetFactory", "Loaded ${days.size} cells, holidays: $holidayDays")
    }

    override fun onDestroy() {}

    override fun getCount(): Int = days.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_compact_day)
        val day = days[position]

        if (day.dayNumber == 0) {
            views.setTextViewText(R.id.widget_day_number, "")
            views.setViewVisibility(R.id.widget_today_bg, View.GONE)
        } else {
            views.setTextViewText(R.id.widget_day_number, "${day.dayNumber}")

            val positionInWeek = position % 7
            val isWeekend = positionInWeek == 5 || positionInWeek == 6

            if (day.isToday) {
                views.setTextColor(R.id.widget_day_number, 0xFFFFFFFF.toInt())
                views.setViewVisibility(R.id.widget_today_bg, View.VISIBLE)
            } else if (day.hasHoliday) {
                views.setTextColor(R.id.widget_day_number, 0xFFEF5350.toInt())
                views.setViewVisibility(R.id.widget_today_bg, View.GONE)
            } else if (isWeekend) {
                views.setTextColor(R.id.widget_day_number, 0xFFFF3344.toInt())
                views.setViewVisibility(R.id.widget_today_bg, View.GONE)
            } else {
                views.setTextColor(R.id.widget_day_number, 0xCCFFFFFF.toInt())
                views.setViewVisibility(R.id.widget_today_bg, View.GONE)
            }
        }

        val fillInIntent = Intent().apply {
            action = "OPEN_CALENDAR"
            putExtra("day_number", day.dayNumber)
            putExtra("is_today", day.isToday)
        }
        views.setOnClickFillInIntent(R.id.widget_day_number, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
