import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

const _uuid = Uuid();

/// Habit Tracker Widget
///
/// Data schema:
/// {
///   'habits': [
///     {
///       'id': 'uuid',
///       'name': 'Exercise',
///       'color': 0xFFE57373 (int),
///       'completedDays': ['2026-01-15', '2026-01-16', ...]
///     },
///     ...
///   ]
/// }
class HabitTrackerWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const HabitTrackerWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<HabitTrackerWidget> createState() => _HabitTrackerWidgetState();
}

class _HabitTrackerWidgetState extends State<HabitTrackerWidget> with WidgetLogMixin<HabitTrackerWidget> {
  @override
  AppWidget get logWidget => widget.widget;
  @override
  Function(AppWidget) get logOnUpdate => widget.onUpdate;

  late TextEditingController _titleController;
  final _addController = TextEditingController();
  final _fmt = DateFormat('yyyy-MM-dd');

  static const _habitColors = [
    0xFFE57373, // red
    0xFF81C784, // green
    0xFF64B5F6, // blue
    0xFFFFB74D, // orange
    0xFFBA68C8, // purple
    0xFF4DB6AC, // teal
    0xFFFF8A65, // deep orange
    0xFFA1887F, // brown
  ];

  List<Map<String, dynamic>> get _habits =>
      (widget.widget.data['habits'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _addHabit() {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    final habits = _habits;
    final colorIndex = habits.length % _habitColors.length;
    habits.add({
      'id': _uuid.v4(),
      'name': name,
      'color': _habitColors[colorIndex],
      'completedDays': <String>[],
    });
    var data = {...widget.widget.data, 'habits': habits};
    data = addLog(data, 'habit added: $name');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
    _addController.clear();
  }

  void _removeHabit(int index) {
    final removed = _habits[index]['name'] as String? ?? '';
    final habits = _habits..removeAt(index);
    var data = {...widget.widget.data, 'habits': habits};
    data = addLog(data, 'habit removed: $removed');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  void _toggleDay(int habitIndex, String dayStr) {
    final habits = _habits;
    final days = List<String>.from(habits[habitIndex]['completedDays'] as List? ?? []);
    if (days.contains(dayStr)) {
      days.remove(dayStr);
    } else {
      days.add(dayStr);
    }
    final habitName = habits[habitIndex]['name'] as String? ?? '';
    final toggled = days.contains(dayStr) ? 'completed' : 'unmarked';
    habits[habitIndex] = {...habits[habitIndex], 'completedDays': days};
    var data = {...widget.widget.data, 'habits': habits};
    data = addLog(data, '$habitName $toggled: $dayStr');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  int _calculateStreak(List<String> completedDays) {
    final completed = completedDays.toSet();
    int streak = 0;
    var day = DateTime.now();
    if (!completed.contains(_fmt.format(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    while (completed.contains(_fmt.format(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _renameHabit(int index) {
    final habits = _habits;
    final controller = TextEditingController(text: habits[index]['name'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Habit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Habit name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final oldName = habits[index]['name'] as String? ?? '';
                habits[index] = {...habits[index], 'name': name};
                var data = {...widget.widget.data, 'habits': habits};
                data = addLog(data, 'renamed: $oldName → $name');
                widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
  }

  @override
  void didUpdateWidget(HabitTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widget.id != widget.widget.id) {
      _titleController.text = widget.widget.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = DateTime.now();
    final todayStr = _fmt.format(today);
    final habits = _habits;

    // Show last 14 days for a compact grid
    final days = List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          onChanged: (_) => widget.onUpdate(widget.widget.copyWith(title: _titleController.text)),
          style: theme.textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'Habit Tracker',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        if (habits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Add your first habit below',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else ...[
          // Day headers row
          Row(
            children: [
              const SizedBox(width: 100), // habit name column
              ...days.map((day) {
                final isToday = _fmt.format(day) == todayStr;
                return Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('E').format(day).substring(0, 1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                        color: isToday ? cs.primary : cs.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          // Date numbers row
          Row(
            children: [
              const SizedBox(width: 100),
              ...days.map((day) {
                final isToday = _fmt.format(day) == todayStr;
                return Expanded(
                  child: Center(
                    child: Text(
                      day.day.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                        color: isToday ? cs.primary : cs.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          // Habit rows
          ...List.generate(habits.length, (habitIdx) {
            final habit = habits[habitIdx];
            final name = habit['name'] as String? ?? '';
            final color = Color(habit['color'] as int? ?? 0xFF64B5F6);
            final completedDays = List<String>.from(habit['completedDays'] as List? ?? []);
            final completedSet = completedDays.toSet();
            final streak = _calculateStreak(completedDays);
            final daysCompleted = days.where((d) => completedSet.contains(_fmt.format(d))).length;

            return Dismissible(
              key: ValueKey(habit['id']),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: cs.error.withAlpha(30),
                child: Icon(Icons.delete, color: cs.error),
              ),
              onDismissed: (_) => _removeHabit(habitIdx),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    // Habit name + stats
                    GestureDetector(
                      onTap: () => _renameHabit(habitIdx),
                      child: SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$daysCompleted/14 · ${streak}d streak',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Day cells
                    ...List.generate(days.length, (dayIdx) {
                      final dayStr = _fmt.format(days[dayIdx]);
                      final done = completedSet.contains(dayStr);
                      final isToday = dayStr == todayStr;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleDay(habitIdx, dayStr),
                          child: Container(
                            height: 22,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: done
                                  ? color.withAlpha(200)
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                              border: isToday
                                  ? Border.all(color: cs.primary, width: 1.5)
                                  : null,
                            ),
                            child: done
                                ? Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addController,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'e.g. Exercise, Read, Meditate...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
                onSubmitted: (_) => _addHabit(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addHabit,


            ),
          ],
        ),
      ],
    );
  }
}
