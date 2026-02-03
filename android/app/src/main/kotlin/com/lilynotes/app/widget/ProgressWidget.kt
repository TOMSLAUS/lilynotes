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
import androidx.glance.appwidget.LinearProgressIndicator
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
import org.json.JSONObject

class ProgressWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
        provideContent {
            ProgressContent(launchIntent, currentState())
        }
    }

    @Composable
    private fun ProgressContent(launchIntent: Intent, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
            ?: prefs.getString("default_progress", null)
        val title = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_title", "Progress") ?: "Progress" else "Progress"
        val dataJson = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_data", "{}") ?: "{}" else "{}"

        val data = try { JSONObject(dataJson) } catch (_: Exception) { JSONObject() }
        val current = data.optInt("current", 0)
        val target = data.optInt("target", 10)
        val percent = data.optInt("percent", 0)

        val teal = Color(0xFF009688)
        val bg = Color(0xFFF5F5F5)
        val fraction = if (target > 0) (current.toFloat() / target).coerceIn(0f, 1f) else 0f
        val barColor = if (percent >= 100) Color(0xFF4CAF50) else teal

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
                Text(
                    text = "$current/$target",
                    style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.Gray))
                )
            }
            Spacer(modifier = GlanceModifier.height(6.dp))
            LinearProgressIndicator(
                progress = fraction,
                modifier = GlanceModifier.fillMaxWidth(),
                color = ColorProvider(barColor),
                backgroundColor = ColorProvider(Color(0xFFE0E0E0))
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = "$percent%",
                    style = TextStyle(
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = ColorProvider(barColor)
                    )
                )
                Spacer(modifier = GlanceModifier.width(8.dp))
                Box(
                    modifier = GlanceModifier
                        .size(28.dp)
                        .background(teal)
                        .cornerRadius(14.dp)
                        .clickable(actionRunCallback<ProgressIncrementAction>(
                            actionParametersOf(
                                ActionParameters.Key<String>("widgetId") to (appWidgetId ?: "")
                            )
                        )),
                    contentAlignment = Alignment.Center
                ) {
                    Text("+", style = TextStyle(color = ColorProvider(Color.White), fontSize = 16.sp, fontWeight = FontWeight.Bold))
                }
            }
        }
    }
}
