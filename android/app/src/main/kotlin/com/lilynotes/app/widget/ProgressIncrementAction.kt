package com.lilynotes.app.widget

import android.content.Context
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class ProgressIncrementAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val widgetId = parameters[ActionParameters.Key<String>("widgetId")] ?: return
        val intent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("lilynotes://progress-increment?widgetId=$widgetId")
        )
        intent.send()
    }
}
