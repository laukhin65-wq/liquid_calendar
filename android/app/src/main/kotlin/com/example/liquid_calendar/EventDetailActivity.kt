package com.example.liquid_calendar

import android.app.Activity
import android.content.Intent
import android.os.Bundle

class EventDetailActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val eventId = intent.getStringExtra("event_id") ?: ""

        val prefs = getSharedPreferences("widget_events", MODE_PRIVATE)
        prefs.edit()
            .putString("pending_action", "OPEN_EVENT")
            .putString("pending_event_id", eventId)
            .apply()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        startActivity(launchIntent)
        finish()
    }
}
