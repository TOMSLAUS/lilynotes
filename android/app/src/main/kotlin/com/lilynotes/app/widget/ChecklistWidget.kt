package com.lilynotes.app.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import com.lilynotes.app.MainActivity
import org.json.JSONArray

class ChecklistWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
        provideContent {
            ChecklistContent(launchIntent, currentState())
        }
    }

    @Composable
    private fun ChecklistContent(launchIntent: Intent, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
            ?: prefs.getString("default_checklist", null)
        val title = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_title", "Checklist") ?: "Checklist" else "Checklist"
        val dataJson = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_data", "[]") ?: "[]" else "[]"

        val items = try { JSONArray(dataJson) } catch (_: Exception) { JSONArray() }
        val total = items.length()
        var checked = 0
        for (i in 0 until total) {
            if (items.getJSONObject(i).optBoolean("checked", false)) checked++
        }

        val teal = Color(0xFF009688)
        val bg = Color(0xFFF5F5F5)

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(bg)
                .padding(12.dp)
                .clickable(actionStartActivity(launchIntent))
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = title,
                    style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 14.sp, color = ColorProvider(Color.Black)),
                    maxLines = 1,
                    modifier = GlanceModifier.defaultWeight()
                )
                if (total > 0) {
                    Text(
                        text = "$checked/$total",
                        style = TextStyle(fontSize = 12.sp, color = ColorProvider(if (checked == total) teal else Color.Gray))
                    )
                }
            }
            Spacer(modifier = GlanceModifier.height(6.dp))

            if (total == 0) {
                Text(
                    text = "No items — open app to add",
                    style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.Gray))
                )
            } else {
                for (i in 0 until minOf(total, 8)) {
                    val item = items.getJSONObject(i)
                    val text = item.optString("text", "")
                    val isChecked = item.optBoolean("checked", false)

                    Row(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp)
                            .clickable(actionRunCallback<ChecklistToggleAction>(
                                actionParametersOf(
                                    ActionParameters.Key<String>("widgetId") to (appWidgetId ?: ""),
                                    ActionParameters.Key<String>("index") to i.toString()
                                )
                            )),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = GlanceModifier
                                .size(20.dp)
                                .background(if (isChecked) teal else Color(0xFFE0E0E0))
                                .cornerRadius(4.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            if (isChecked) {
                                Text("✓", style = TextStyle(color = ColorProvider(Color.White), fontSize = 12.sp))
                            }
                        }
                        Spacer(modifier = GlanceModifier.width(8.dp))
                        Text(
                            text = text,
                            style = TextStyle(
                                fontSize = 13.sp,
                                color = ColorProvider(if (isChecked) Color.Gray else Color.Black),
                            ),
                            maxLines = 1
                        )
                    }
                }
                if (total > 8) {
                    Text(
                        text = "+${total - 8} more",
                        style = TextStyle(fontSize = 11.sp, color = ColorProvider(Color.Gray)),
                        modifier = GlanceModifier.padding(top = 2.dp)
                    )
                }
            }
        }
    }
}
