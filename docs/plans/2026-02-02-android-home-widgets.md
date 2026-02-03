# Android Home Screen Widgets Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add three interactive Android home screen widgets (Habit Tracker, Checklist, Progress Bar) that share live data with the Lily Notes Flutter app.

**Architecture:** The `home_widget` Flutter package bridges data between Dart and native Android. Flutter writes JSON snapshots to SharedPreferences on every widget update. Native Android widgets (Jetpack Glance + Kotlin) read from SharedPreferences and render UI. Interactive taps fire URI callbacks that route back to Dart to update Hive, then re-push to SharedPreferences and refresh the native widget.

**Tech Stack:** Flutter `home_widget ^0.9.0`, Jetpack Glance `1.1.1`, Kotlin, Jetpack Compose (for Glance), Hive (existing storage)

---

## Task 1: Add `home_widget` dependency and configure Android build

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Add home_widget to pubspec.yaml**

In `pubspec.yaml`, add under `dependencies`:
```yaml
  home_widget: ^0.9.0
```

**Step 2: Add Glance dependencies to android/app/build.gradle.kts**

After the `flutter { source = "../.." }` block, add:
```kotlin
dependencies {
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance:1.1.1")
}
```

Also add inside the `android { }` block:
```kotlin
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }
```

**Step 3: Add background receiver to AndroidManifest.xml**

Inside `<application>`, after the `</activity>` closing tag, add:
```xml
        <!-- home_widget background receiver for interactive widgets -->
        <receiver android:name="es.antonborri.home_widget.HomeWidgetBackgroundReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="es.antonborri.home_widget.action.BACKGROUND" />
            </intent-filter>
        </receiver>
```

**Step 4: Add launch intent filter to MainActivity**

Inside the existing `<activity>` tag for `.MainActivity`, add another intent-filter:
```xml
            <intent-filter>
                <action android:name="es.antonborri.home_widget.action.LAUNCH" />
            </intent-filter>
```

**Step 5: Run flutter pub get and verify build**

Run:
```bash
flutter pub get
```
Expected: resolves successfully with home_widget added.

**Step 6: Commit**
```bash
git add -A && git commit -m "feat: add home_widget and Glance dependencies for Android widgets"
```

---

## Task 2: Create the Widget Bridge Service (Flutter/Dart)

**Files:**
- Create: `lib/services/widget_bridge_service.dart`
- Modify: `lib/services/services.dart` (add export)

**Step 1: Create widget_bridge_service.dart**

```dart
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/app_widget.dart';
import '../models/widget_type.dart';

/// Bridges Flutter app widget data to native Android home screen widgets
/// via SharedPreferences (home_widget's transport layer).
class WidgetBridgeService {
  static const String _appGroupId = 'com.lilynotes.app.widgets';
  static final _fmt = DateFormat('yyyy-MM-dd');

  /// Initialize home_widget with app group
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Push a widget's data to the native home screen widget bridge.
  /// Call this every time an AppWidget is updated.
  static Future<void> pushWidget(AppWidget widget) async {
    final id = widget.id;
    await HomeWidget.saveWidgetData('widget_${id}_type', widget.type.name);
    await HomeWidget.saveWidgetData('widget_${id}_title', widget.title);
    await HomeWidget.saveWidgetData('widget_${id}_updated', DateTime.now().toIso8601String());

    switch (widget.type) {
      case WidgetType.habitTracker:
        await _pushHabitData(id, widget.data);
        await HomeWidget.updateWidget(
          androidName: 'com.lilynotes.app.widget.HabitWidgetReceiver',
        );
        break;
      case WidgetType.checklist:
        await _pushChecklistData(id, widget.data);
        await HomeWidget.updateWidget(
          androidName: 'com.lilynotes.app.widget.ChecklistWidgetReceiver',
        );
        break;
      case WidgetType.progressBar:
        await _pushProgressData(id, widget.data);
        await HomeWidget.updateWidget(
          androidName: 'com.lilynotes.app.widget.ProgressWidgetReceiver',
        );
        break;
      default:
        break;
    }
  }

  /// Push simplified habit data: today's status + streak for each habit
  static Future<void> _pushHabitData(String id, Map<String, dynamic> data) async {
    final habits = (data['habits'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final today = _fmt.format(DateTime.now());
    final simplified = habits.map((h) {
      final completedDays = List<String>.from(h['completedDays'] as List? ?? []);
      final done = completedDays.contains(today);
      final streak = _calculateStreak(completedDays);
      return {
        'id': h['id'],
        'name': h['name'],
        'color': h['color'],
        'done': done,
        'streak': streak,
      };
    }).toList();
    await HomeWidget.saveWidgetData('widget_${id}_data', jsonEncode(simplified));
  }

  static Future<void> _pushChecklistData(String id, Map<String, dynamic> data) async {
    final items = (data['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final simplified = items.map((i) => {
      'id': i['id'],
      'text': i['text'],
      'checked': i['checked'] ?? false,
    }).toList();
    await HomeWidget.saveWidgetData('widget_${id}_data', jsonEncode(simplified));
  }

  static Future<void> _pushProgressData(String id, Map<String, dynamic> data) async {
    final current = (data['current'] as num?)?.toInt() ?? 0;
    final target = (data['target'] as num?)?.toInt() ?? 10;
    final percent = target > 0 ? (current / target * 100).round() : 0;
    final simplified = {
      'current': current,
      'target': target,
      'percent': percent,
    };
    await HomeWidget.saveWidgetData('widget_${id}_data', jsonEncode(simplified));
  }

  /// Push a list of all available widgets of given types so the config screen can show them.
  static Future<void> pushWidgetList(List<AppWidget> allWidgets) async {
    final eligible = allWidgets.where((w) =>
      w.type == WidgetType.habitTracker ||
      w.type == WidgetType.checklist ||
      w.type == WidgetType.progressBar
    ).toList();
    final list = eligible.map((w) => {
      'id': w.id,
      'type': w.type.name,
      'title': w.title.isEmpty ? w.type.name : w.title,
    }).toList();
    await HomeWidget.saveWidgetData('available_widgets', jsonEncode(list));
  }

  /// Save which app widget ID is bound to a given Android widget instance.
  static Future<void> saveConfig(int androidWidgetId, String appWidgetId) async {
    await HomeWidget.saveWidgetData('config_$androidWidgetId', appWidgetId);
  }

  /// Get the app widget ID bound to a given Android widget instance.
  static Future<String?> getConfig(int androidWidgetId) async {
    return HomeWidget.getWidgetData<String>('config_$androidWidgetId');
  }

  static int _calculateStreak(List<String> completedDays) {
    final completed = completedDays.toSet();
    final fmt = DateFormat('yyyy-MM-dd');
    int streak = 0;
    var day = DateTime.now();
    if (!completed.contains(fmt.format(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    while (completed.contains(fmt.format(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
```

**Step 2: Export from services barrel**

In `lib/services/services.dart`, add:
```dart
export 'widget_bridge_service.dart';
```

**Step 3: Commit**
```bash
git add -A && git commit -m "feat: add WidgetBridgeService for home screen widget data bridge"
```

---

## Task 3: Hook bridge into AppState and main.dart

**Files:**
- Modify: `lib/providers/app_state.dart`
- Modify: `lib/main.dart`

**Step 1: Import and call bridge in AppState.updateWidget()**

In `lib/providers/app_state.dart`, add import at top:
```dart
import '../services/widget_bridge_service.dart';
```

In the `updateWidget` method (around line 181), after `await _storage.saveWidget(widget.toMap());`, add:
```dart
    await WidgetBridgeService.pushWidget(widget);
```

Also in `init()`, after `await _loadCurrentWidgets();` and before `notifyListeners();`, add:
```dart
    // Push all eligible widgets to home screen bridge
    final allWidgets = <AppWidget>[];
    for (final page in _pages) {
      final maps = await _storage.getWidgetsForPage(page.id);
      allWidgets.addAll(maps.map((m) => AppWidget.fromMap(m)));
    }
    await WidgetBridgeService.pushWidgetList(allWidgets);
```

**Step 2: Register interactivity callback in main.dart**

In `lib/main.dart`, add imports:
```dart
import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:lilynotes/services/widget_bridge_service.dart';
```

Add the background callback function BEFORE `void main()`:
```dart
/// Called by home_widget when a user taps an interactive element on the home screen widget.
@pragma("vm:entry-point")
FutureOr<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;

  await Hive.initFlutter();
  await StorageService().init();

  final host = uri.host; // e.g. "habit-toggle", "checklist-toggle", "progress-increment"
  final params = uri.queryParameters;
  final widgetId = params['widgetId'];
  if (widgetId == null) return;

  final storage = StorageService();
  final widgetMap = await storage.getWidget(widgetId);
  if (widgetMap == null) return;
  final appWidget = AppWidget.fromMap(widgetMap);

  switch (host) {
    case 'habit-toggle':
      final habitId = params['habitId'];
      if (habitId == null) return;
      final habits = (appWidget.data['habits'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final idx = habits.indexWhere((h) => h['id'] == habitId);
      if (idx == -1) return;
      final days = List<String>.from(habits[idx]['completedDays'] as List? ?? []);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (days.contains(today)) {
        days.remove(today);
      } else {
        days.add(today);
      }
      habits[idx] = {...habits[idx], 'completedDays': days};
      final updated = appWidget.copyWith(data: {...appWidget.data, 'habits': habits});
      await storage.saveWidget(updated.toMap());
      await WidgetBridgeService.pushWidget(updated);
      break;

    case 'checklist-toggle':
      final indexStr = params['index'];
      if (indexStr == null) return;
      final index = int.tryParse(indexStr);
      if (index == null) return;
      final items = (appWidget.data['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (index < 0 || index >= items.length) return;
      items[index] = {...items[index], 'checked': !(items[index]['checked'] == true)};
      final updated = appWidget.copyWith(data: {...appWidget.data, 'items': items});
      await storage.saveWidget(updated.toMap());
      await WidgetBridgeService.pushWidget(updated);
      break;

    case 'progress-increment':
      final current = (appWidget.data['current'] as num?)?.toInt() ?? 0;
      final updated = appWidget.copyWith(data: {...appWidget.data, 'current': current + 1});
      await storage.saveWidget(updated.toMap());
      await WidgetBridgeService.pushWidget(updated);
      break;
  }
}
```

Add the `intl` import for DateFormat:
```dart
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
```

In `main()`, after `await StorageService().init();` and before `runApp(...)`:
```dart
  await WidgetBridgeService.init();
  await HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);
```

**Step 3: Commit**
```bash
git add -A && git commit -m "feat: hook widget bridge into AppState and register background callback"
```

---

## Task 4: Create Habit Tracker Android Widget (Kotlin + Glance)

**Files:**
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/HabitWidget.kt`
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/HabitWidgetReceiver.kt`
- Create: `android/app/src/main/res/xml/habit_widget_info.xml`
- Create: `android/app/src/main/res/layout/glance_default_loading_layout.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Create the default loading layout**

Create `android/app/src/main/res/layout/glance_default_loading_layout.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@android:color/background_light">
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center"
        android:text="Loading..."
        android:textColor="@android:color/darker_gray" />
</FrameLayout>
```

**Step 2: Create habit_widget_info.xml**

Create `android/app/src/main/res/xml/habit_widget_info.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/glance_default_loading_layout"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:resizeMode="horizontal|vertical"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="1800000"
    android:description="@string/habit_widget_description"
    android:previewLayout="@layout/glance_default_loading_layout">
</appwidget-provider>
```

**Step 3: Add string resources**

Create `android/app/src/main/res/values/widget_strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="habit_widget_description">Track your daily habits</string>
    <string name="checklist_widget_description">Quick checklist access</string>
    <string name="progress_widget_description">Track your progress goals</string>
</resources>
```

**Step 4: Create HabitWidget.kt (Glance composable)**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/HabitWidget.kt`:
```kotlin
package com.lilynotes.app.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.layout.*
import androidx.glance.text.*
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import com.lilynotes.app.MainActivity
import org.json.JSONArray

class HabitWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            HabitContent(context, currentState())
        }
    }

    @Composable
    private fun HabitContent(context: Context, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        // Find which app widget is bound to this Android widget
        val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
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
                .clickable(actionStartActivity<MainActivity>(context, Uri.parse("lilynotes://open")))
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
                        // Colored done indicator — tap to toggle
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
```

**Step 5: Create HabitToggleAction.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/HabitToggleAction.kt`:
```kotlin
package com.lilynotes.app.widget

import android.content.Context
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class HabitToggleAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val widgetId = parameters[ActionParameters.Key<String>("widgetId")] ?: return
        val habitId = parameters[ActionParameters.Key<String>("habitId")] ?: return
        val intent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("lilynotes://habit-toggle?widgetId=$widgetId&habitId=$habitId")
        )
        intent.send()
    }
}
```

**Step 6: Create HabitWidgetReceiver.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/HabitWidgetReceiver.kt`:
```kotlin
package com.lilynotes.app.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class HabitWidgetReceiver : HomeWidgetGlanceWidgetReceiver<HabitWidget>() {
    override val glanceAppWidget = HabitWidget()
}
```

**Step 7: Register in AndroidManifest.xml**

Inside `<application>`, add:
```xml
        <!-- Habit Tracker Home Widget -->
        <receiver android:name=".widget.HabitWidgetReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/habit_widget_info" />
        </receiver>
```

**Step 8: Build and verify**

Run:
```bash
flutter build apk --debug
```
Expected: builds successfully.

**Step 9: Commit**
```bash
git add -A && git commit -m "feat: add Habit Tracker home screen widget (Android/Glance)"
```

---

## Task 5: Create Progress Bar Android Widget

**Files:**
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/ProgressWidget.kt`
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/ProgressWidgetReceiver.kt`
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/ProgressIncrementAction.kt`
- Create: `android/app/src/main/res/xml/progress_widget_info.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Create progress_widget_info.xml**

Create `android/app/src/main/res/xml/progress_widget_info.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/glance_default_loading_layout"
    android:minWidth="250dp"
    android:minHeight="60dp"
    android:resizeMode="horizontal"
    android:targetCellWidth="4"
    android:targetCellHeight="1"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="1800000"
    android:description="@string/progress_widget_description"
    android:previewLayout="@layout/glance_default_loading_layout">
</appwidget-provider>
```

**Step 2: Create ProgressWidget.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/ProgressWidget.kt`:
```kotlin
package com.lilynotes.app.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.layout.*
import androidx.glance.text.*
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import com.lilynotes.app.MainActivity
import org.json.JSONObject

class ProgressWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            ProgressContent(context, currentState())
        }
    }

    @Composable
    private fun ProgressContent(context: Context, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
        val title = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_title", "Progress") ?: "Progress" else "Progress"
        val dataJson = if (appWidgetId != null) prefs.getString("widget_${appWidgetId}_data", "{}") ?: "{}" else "{}"

        val data = try { JSONObject(dataJson) } catch (_: Exception) { JSONObject() }
        val current = data.optInt("current", 0)
        val target = data.optInt("target", 10)
        val percent = data.optInt("percent", 0)

        val teal = Color(0xFF009688)
        val bg = Color(0xFFF5F5F5)
        val barBg = Color(0xFFE0E0E0)

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(bg)
                .padding(12.dp)
                .clickable(actionStartActivity<MainActivity>(context, Uri.parse("lilynotes://open")))
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
            // Progress bar background
            Box(
                modifier = GlanceModifier.fillMaxWidth().height(10.dp).background(barBg).cornerRadius(5.dp)
            ) {
                val fraction = if (target > 0) (current.toFloat() / target).coerceIn(0f, 1f) else 0f
                // Filled portion — use width percentage approximation
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth(fraction)
                        .height(10.dp)
                        .background(if (percent >= 100) Color(0xFF4CAF50) else teal)
                        .cornerRadius(5.dp)
                ) {}
            }
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
                        color = ColorProvider(if (percent >= 100) Color(0xFF4CAF50) else teal)
                    )
                )
                Spacer(modifier = GlanceModifier.width(8.dp))
                // + button
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
```

**Step 3: Create ProgressIncrementAction.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/ProgressIncrementAction.kt`:
```kotlin
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
```

**Step 4: Create ProgressWidgetReceiver.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/ProgressWidgetReceiver.kt`:
```kotlin
package com.lilynotes.app.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class ProgressWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ProgressWidget>() {
    override val glanceAppWidget = ProgressWidget()
}
```

**Step 5: Register in AndroidManifest.xml**

Inside `<application>`, add:
```xml
        <!-- Progress Bar Home Widget -->
        <receiver android:name=".widget.ProgressWidgetReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/progress_widget_info" />
        </receiver>
```

**Step 6: Commit**
```bash
git add -A && git commit -m "feat: add Progress Bar home screen widget (Android/Glance)"
```

---

## Task 6: Create Checklist Android Widget

**Files:**
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/ChecklistWidget.kt`
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/ChecklistWidgetReceiver.kt`
- Create: `android/app/src/main/kotlin/com/lilynotes/app/widget/ChecklistToggleAction.kt`
- Create: `android/app/src/main/res/xml/checklist_widget_info.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Create checklist_widget_info.xml**

Create `android/app/src/main/res/xml/checklist_widget_info.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/glance_default_loading_layout"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:resizeMode="horizontal|vertical"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="1800000"
    android:description="@string/checklist_widget_description"
    android:previewLayout="@layout/glance_default_loading_layout">
</appwidget-provider>
```

**Step 2: Create ChecklistWidget.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/ChecklistWidget.kt`:
```kotlin
package com.lilynotes.app.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.layout.*
import androidx.glance.text.*
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import com.lilynotes.app.MainActivity
import org.json.JSONArray

class ChecklistWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            ChecklistContent(context, currentState())
        }
    }

    @Composable
    private fun ChecklistContent(context: Context, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
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
                .clickable(actionStartActivity<MainActivity>(context, Uri.parse("lilynotes://open")))
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
```

**Step 3: Create ChecklistToggleAction.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/ChecklistToggleAction.kt`:
```kotlin
package com.lilynotes.app.widget

import android.content.Context
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class ChecklistToggleAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val widgetId = parameters[ActionParameters.Key<String>("widgetId")] ?: return
        val index = parameters[ActionParameters.Key<String>("index")] ?: return
        val intent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("lilynotes://checklist-toggle?widgetId=$widgetId&index=$index")
        )
        intent.send()
    }
}
```

**Step 4: Create ChecklistWidgetReceiver.kt**

Create `android/app/src/main/kotlin/com/lilynotes/app/widget/ChecklistWidgetReceiver.kt`:
```kotlin
package com.lilynotes.app.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class ChecklistWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ChecklistWidget>() {
    override val glanceAppWidget = ChecklistWidget()
}
```

**Step 5: Register in AndroidManifest.xml**

Inside `<application>`, add:
```xml
        <!-- Checklist Home Widget -->
        <receiver android:name=".widget.ChecklistWidgetReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/checklist_widget_info" />
        </receiver>
```

**Step 6: Commit**
```bash
git add -A && git commit -m "feat: add Checklist home screen widget (Android/Glance)"
```

---

## Task 7: Widget Configuration — Bind Android widget to app widget

This is the mechanism that lets users pick WHICH habit tracker / checklist / progress bar to show when they add the widget to their home screen.

**Note:** `home_widget` doesn't provide a built-in Flutter config activity. The simplest approach is: when the widget first loads and has no config, show a "Tap to configure in app" message. When the user opens the app, a settings screen lets them bind widgets. However, a simpler V1 approach: auto-bind to the FIRST widget of matching type. We'll use this for V1.

**Files:**
- Modify: `lib/services/widget_bridge_service.dart`
- Modify: `lib/providers/app_state.dart`

**Step 1: Add auto-binding logic to WidgetBridgeService**

In `widget_bridge_service.dart`, add a method:
```dart
  /// For V1: auto-bind by saving the first widget of each type as the default.
  /// Native widgets will read 'default_habit', 'default_checklist', 'default_progress'.
  static Future<void> pushDefaults(List<AppWidget> allWidgets) async {
    final firstHabit = allWidgets.where((w) => w.type == WidgetType.habitTracker).firstOrNull;
    final firstChecklist = allWidgets.where((w) => w.type == WidgetType.checklist).firstOrNull;
    final firstProgress = allWidgets.where((w) => w.type == WidgetType.progressBar).firstOrNull;

    if (firstHabit != null) {
      await HomeWidget.saveWidgetData('default_habit', firstHabit.id);
      await pushWidget(firstHabit);
    }
    if (firstChecklist != null) {
      await HomeWidget.saveWidgetData('default_checklist', firstChecklist.id);
      await pushWidget(firstChecklist);
    }
    if (firstProgress != null) {
      await HomeWidget.saveWidgetData('default_progress', firstProgress.id);
      await pushWidget(firstProgress);
    }
  }
```

**Step 2: Update native widgets to read default ID**

In each Kotlin widget class (`HabitWidget.kt`, `ProgressWidget.kt`, `ChecklistWidget.kt`), change the config lookup line from:
```kotlin
val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
```
to:
```kotlin
val appWidgetId = prefs.getString("config_${LocalGlanceId.current}", null)
    ?: prefs.getString("default_habit", null) // use "default_checklist" or "default_progress" for the other widgets
```

**Step 3: Call pushDefaults in AppState.init()**

In `app_state.dart`, replace the `WidgetBridgeService.pushWidgetList(allWidgets)` call added in Task 3 with:
```dart
    await WidgetBridgeService.pushDefaults(allWidgets);
```

**Step 4: Commit**
```bash
git add -A && git commit -m "feat: auto-bind home widgets to first widget of matching type"
```

---

## Task 8: Build, deploy, and test on device

**Step 1: Full build**
```bash
flutter build apk --debug
```

**Step 2: Install on device/emulator**
```bash
flutter install
```

**Step 3: Manual test checklist**
- [ ] Open app, create a habit tracker widget with 2-3 habits
- [ ] Create a checklist with items
- [ ] Create a progress bar
- [ ] Go to home screen, long press → Widgets → find "Lily Notes"
- [ ] Add Habit Tracker widget — verify habits show with today's status
- [ ] Tap a habit circle on the widget — verify it toggles
- [ ] Open app — verify the toggle persisted
- [ ] Add Progress widget — verify bar and percentage show
- [ ] Tap + on progress widget — verify count increments
- [ ] Add Checklist widget — verify items show
- [ ] Tap an item — verify it toggles checked state

**Step 4: Fix any issues found during testing**

**Step 5: Final commit**
```bash
git add -A && git commit -m "feat: Android home screen widgets complete — habit, checklist, progress"
```
