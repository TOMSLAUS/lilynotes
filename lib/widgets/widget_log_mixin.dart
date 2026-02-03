import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_widget.dart';

const _maxLogEntries = 50;
final _logTimeFmt = DateFormat('MMM d, HH:mm');

/// Mixin that gives any widget State logging capabilities.
///
/// The host State must provide [logWidget] and [logOnUpdate] accessors
/// so the mixin can read/write the widget's data.
mixin WidgetLogMixin<T extends StatefulWidget> on State<T> {
  AppWidget get logWidget;
  Function(AppWidget) get logOnUpdate;

  /// Append a log entry and return the updated data map.
  /// Call this inside your action methods, then pass the returned
  /// data to onUpdate.
  Map<String, dynamic> addLog(Map<String, dynamic> data, String action) {
    final logs = List<Map<String, dynamic>>.from(
      (data['log'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
    );
    logs.add({'t': DateTime.now().toIso8601String(), 'a': action});
    if (logs.length > _maxLogEntries) {
      logs.removeRange(0, logs.length - _maxLogEntries);
    }
    return {...data, 'log': logs};
  }

  /// Show the log dialog for this widget.
  void showLogDialog() {
    final logs = (logWidget.data['log'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    showDialog(
      context: context,
      builder: (ctx) {
        final reversed = logs.reversed.toList();
        return AlertDialog(
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
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                action,
                                style: Theme.of(ctx).textTheme.bodySmall,
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
        );
      },
    );
  }
}
