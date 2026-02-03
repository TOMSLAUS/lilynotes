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

class HabitWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
        provideContent {
            HabitContent(launchIntent, currentState())
        }
    }

    @Composable
    private fun HabitContent(launchIntent: Intent, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
            ?: prefs.getString("default_habit", null)
        val title = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_title", "Habits") ?: "Habits" else "Habits"
        val dataJson = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_data", "[]") ?: "[]" else "[]"

        val habits = try { JSONArray(dataJson) } catch (_: Exception) { JSONArray() }

        val teal = Color(0xFF009688)
        val bg = Color(0xFFF5F5F5)

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(bg)
                .padding(12.dp)
                .clickable(actionStartActivity(launchIntent))
        ) {
            Text(
                text = title,
                style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 16.sp, color = ColorProvider(Color.Black)),
                maxLines = 1
            )
            Spacer(modifier = GlanceModifier.height(6.dp))

            if (habits.length() == 0) {
                Text(
                    text = "No habits yet — open app to add",
                    style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.Gray))
                )
            } else {
                for (i in 0 until minOf(habits.length(), 6)) {
                    val habit = habits.getJSONObject(i)
                    val name = habit.optString("name", "")
                    val done = habit.optBoolean("done", false)
                    val streak = habit.optInt("streak", 0)
                    val colorInt = habit.optLong("color", 0xFF64B5F6)
                    val habitId = habit.optString("id", "")
                    val habitColor = Color(colorInt.toInt())

                    Row(
                        modifier = GlanceModifier.fillMaxWidth().padding(vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = GlanceModifier
                                .size(22.dp)
                                .background(if (done) habitColor else Color(0xFFE0E0E0))
                                .cornerRadius(4.dp)
                                .clickable(actionRunCallback<HabitToggleAction>(
                                    actionParametersOf(
                                        ActionParameters.Key<String>("widgetId") to (appWidgetId ?: ""),
                                        ActionParameters.Key<String>("habitId") to habitId
                                    )
                                )),
                            contentAlignment = Alignment.Center
                        ) {
                            if (done) {
                                Text("✓", style = TextStyle(color = ColorProvider(Color.White), fontSize = 14.sp))
                            }
                        }
                        Spacer(modifier = GlanceModifier.width(8.dp))
                        Text(
                            text = name,
                            style = TextStyle(fontSize = 13.sp, color = ColorProvider(Color.Black)),
                            maxLines = 1,
                            modifier = GlanceModifier.defaultWeight()
                        )
                        if (streak > 0) {
                            Text(
                                text = "${streak}d",
                                style = TextStyle(fontSize = 11.sp, color = ColorProvider(teal))
                            )
                        }
                    }
                }
            }
        }
    }
}
