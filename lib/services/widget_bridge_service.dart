import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/app_widget.dart';
import '../models/widget_type.dart';

/// Bridges Flutter app widget data to native Android home screen widgets
/// via SharedPreferences (home_widget's transport layer).
class WidgetBridgeService {
  static const String _appGroupId = 'group.com.lilynotes.app.widgets';
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
          iOSName: 'HabitWidget',
        );
        break;
      case WidgetType.checklist:
        await _pushChecklistData(id, widget.data);
        await HomeWidget.updateWidget(
          androidName: 'com.lilynotes.app.widget.ChecklistWidgetReceiver',
          iOSName: 'ChecklistWidget',
        );
        break;
      case WidgetType.progressBar:
        await _pushProgressData(id, widget.data);
        await HomeWidget.updateWidget(
          androidName: 'com.lilynotes.app.widget.ProgressWidgetReceiver',
          iOSName: 'ProgressWidget',
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
