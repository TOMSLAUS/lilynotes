import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_widget.dart';
import '../models/widget_type.dart';
import 'text_block_widget.dart';
import 'score_widget.dart';
import 'counter_list_widget.dart';
import 'checklist_widget.dart';
import 'habit_tracker_widget.dart';
import 'timer_widget.dart';
import 'bookmark_widget.dart';
import 'divider_widget.dart';
import 'progress_bar_widget.dart';
import 'expense_tracker_widget.dart';

class WidgetCard extends StatelessWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;
  final bool isLastTextBlock;

  const WidgetCard({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
    this.isLastTextBlock = false,
  });

  @override
  Widget build(BuildContext context) {
    // Text blocks: completely seamless, no decoration
    if (widget.type == WidgetType.text) {
      return TextBlockWidget(
        widget: widget,
        onUpdate: onUpdate,
        onDelete: onDelete,
        fillHeight: isLastTextBlock,
      );
    }

    // Divider: render inline, no container
    if (widget.type == WidgetType.divider) {
      return _InlineWidget(
        onDelete: onDelete,
        child: DividerWidget(
          widget: widget,
          onUpdate: onUpdate,
          onDelete: onDelete,
        ),
      );
    }

    // All other widgets: subtle embedded container
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _InlineWidget(
      onDelete: onDelete,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withAlpha(60),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action icons, right-aligned
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showLog(context),
                    icon: Icon(Icons.history),
                    color: cs.onSurfaceVariant.withAlpha(100),
                    iconSize: 22,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    tooltip: 'Activity log',
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(Icons.close),
                    color: cs.onSurfaceVariant.withAlpha(100),
                    iconSize: 22,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
            _buildInner(),
          ],
        ),
      ),
    );
  }

  static final _logTimeFmt = DateFormat('MMM d, HH:mm');

  void _showLog(BuildContext context) {
    final logs = (widget.data['log'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final reversed = logs.reversed.toList();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activity Log'),
        content: SizedBox(
          width: double.maxFinite,
          child: reversed.isEmpty
              ? const Text('No activity yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: reversed.length,
                  itemBuilder: (_, i) {
                    final entry = reversed[i];
                    final time = DateTime.tryParse(entry['t'] as String? ?? '');
                    final action = entry['a'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time != null ? _logTimeFmt.format(time) : '—',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              action,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Widget'),
        content: const Text('Are you sure you want to delete this widget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInner() {
    switch (widget.type) {
      case WidgetType.text:
      case WidgetType.divider:
        return const SizedBox.shrink();
      case WidgetType.score:
        return ScoreWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
      case WidgetType.counterList:
        return CounterListWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
      case WidgetType.checklist:
        return ChecklistWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
      case WidgetType.habitTracker:
        return HabitTrackerWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
      case WidgetType.timer:
        return TimerWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
      case WidgetType.bookmark:
        return BookmarkWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
      case WidgetType.progressBar:
        return ProgressBarWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
      case WidgetType.expenseTracker:
        return ExpenseTrackerWidget(widget: widget, onUpdate: onUpdate, onDelete: onDelete);
    }
  }
}

/// Wraps an inline widget with long-press-to-delete gesture.
class _InlineWidget extends StatelessWidget {
  final VoidCallback onDelete;
  final Widget child;

  const _InlineWidget({required this.onDelete, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
