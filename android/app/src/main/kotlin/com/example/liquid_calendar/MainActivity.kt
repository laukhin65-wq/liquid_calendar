package com.example.liquid_calendar

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.example.liquid_calendar/widget"
    private val ACTIONS_CHANNEL = "com.example.liquid_calendar/widget_actions"

    private var widgetChannel: MethodChannel? = null
    private var actionsChannel: MethodChannel? = null
    private var isFlutterReady = false
    private var pendingAction: String? = null
    private var pendingEventId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "updateWidget") {
                val dayEvents = call.argument<String>("dayEvents") ?: "[]"
                val monthEventsDetail = call.argument<String>("monthEventsDetail") ?: "[]"
                val prefs = getSharedPreferences("widget_events", Context.MODE_PRIVATE)
                prefs.edit()
                    .putString("day_events", dayEvents)
                    .putString("day_events_detail", monthEventsDetail)
                    .apply()
                updateDayWidgets()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        actionsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACTIONS_CHANNEL)
        actionsChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "widgetReady") {
                isFlutterReady = true
                pendingAction?.let { action ->
                    sendActionToFlutter(action, pendingEventId)
                    pendingAction = null
                    pendingEventId = null
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        val registry = flutterEngine.platformViewsController
        registry.registry.registerViewFactory(
            "com.example.liquid_calendar/liquid_glass",
            LiquidGlassViewFactory(applicationContext)
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("Widget", "onCreate: action=${intent?.action}")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d("Widget", "onNewIntent: action=${intent.action}")
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        Log.d("Widget", "handleIntent: action=$action")
        if (action == "ADD_EVENT" || action == "ADD_TASK" || action == "OPEN_EVENT") {
            val eventId = intent.getStringExtra("event_id")
            if (isFlutterReady) {
                sendActionToFlutter(action, eventId)
            } else {
                pendingAction = action
                pendingEventId = eventId
            }
        }
    }

    private fun sendActionToFlutter(action: String, eventId: String?) {
        Log.d("Widget", "sendToFlutter: $action eventId=$eventId")
        runOnUiThread {
            try {
                actionsChannel?.invokeMethod("onWidgetAction", mapOf(
                    "action" to action,
                    "eventId" to (eventId ?: "")
                ))
            } catch (e: Exception) {
                Log.e("Widget", "sendToFlutter error: ${e.message}")
            }
        }
    }

    private fun updateDayWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val dayIds = manager.getAppWidgetIds(ComponentName(this, DayWidgetProvider::class.java))
        for (id in dayIds) {
            val intent = Intent(this, DayWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(id))
            }
            sendBroadcast(intent)
        }
        val compactIds = manager.getAppWidgetIds(ComponentName(this, CompactWidgetProvider::class.java))
        for (id in compactIds) {
            val intent = Intent(this, CompactWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(id))
            }
            sendBroadcast(intent)
        }
    }
}
