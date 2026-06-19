package com.example.liquid_calendar

import android.content.Context
import android.content.res.Configuration

/// Определяет оформление виджета по теме, выбранной в приложении.
/// Flutter пишет ключ "theme" ("light" / "dark" / "system") в SharedPreferences
/// "widget_events"; для "system" берём системный night-mode устройства.
object WidgetTheme {

    fun isDark(context: Context): Boolean {
        val prefs = context.getSharedPreferences("widget_events", Context.MODE_PRIVATE)
        return when (prefs.getString("theme", "system")) {
            "light" -> false
            "dark" -> true
            else -> {
                val mode = context.resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK
                mode == Configuration.UI_MODE_NIGHT_YES
            }
        }
    }

    /// Фон карточки виджета.
    fun bgRes(context: Context): Int =
        if (isDark(context)) R.drawable.widget_ios26_bg
        else R.drawable.widget_ios26_bg_light

    /// Основной цвет текста.
    fun primaryText(context: Context): Int =
        if (isDark(context)) 0xFFFFFFFF.toInt() else 0xFF1C1C1E.toInt()

    /// Вторичный (приглушённый) цвет текста.
    fun secondaryText(context: Context): Int =
        if (isDark(context)) 0x99FFFFFF.toInt() else 0x99000000.toInt()
}
