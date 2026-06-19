package com.example.liquid_calendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("Widget", "WidgetActionReceiver: action=$action")

        if (action == "ADD_EVENT" || action == "ADD_TASK" || action == "OPEN_EVENT") {
            val eventId = intent.getStringExtra("event_id")
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("flutter.pending_action", action)
                .putString("flutter.pending_event_id", eventId ?: "")
                .apply()
            Log.d("Widget", "WidgetActionReceiver saved: $action eventId=$eventId")

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            context.startActivity(launchIntent)
        }
    }
}
