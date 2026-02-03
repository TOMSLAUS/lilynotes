package com.lilynotes.app.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class HabitWidgetReceiver : HomeWidgetGlanceWidgetReceiver<HabitWidget>() {
    override val glanceAppWidget = HabitWidget()
}
