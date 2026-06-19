package com.example.liquid_calendar

import android.content.Intent
import android.widget.RemoteViewsService

class CompactWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CompactWidgetFactory(applicationContext)
    }
}
