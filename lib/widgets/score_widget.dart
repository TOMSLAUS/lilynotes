import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

const _uuid = Uuid();

class ScoreWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const ScoreWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ScoreWidget> createState() => _ScoreWidgetState();
}

class _ScoreWidgetState extends State<ScoreWidget> with WidgetLogMixin<ScoreWidget> {
  late TextEditingController _titleController;
  final _addController = TextEditingController();

  List<Map<String, dynamic>> get _options =>
      (widget.widget.data['options'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  @override
  AppWidget get logWidget => widget.widget;
  @override
  Function(AppWidget) get logOnUpdate => widget.onUpdate;

  int get _maxVotes {
    final opts = _options;
    if (opts.isEmpty) return 0;
    return opts.map((o) => (o['votes'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);
  }

  void _addOption() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    final options = _options..add({'id': _uuid.v4(), 'text': text, 'votes': 0});
    var data = {...widget.widget.data, 'options': options};
    data = addLog(data, 'option added: $text');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
    _addController.clear();
  }

  void _changeVotes(int index, int delta) {
    final options = _options;
    final cur = (options[index]['votes'] as num?)?.toInt() ?? 0;
    final newVal = (cur + delta).clamp(0, 999999);
    final name = options[index]['text'] as String? ?? '';
    options[index] = {...options[index], 'votes': newVal};
    var data = {...widget.widget.data, 'options': options};
    data = addLog(data, '$name: $cur → $newVal');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  void _removeOption(int index) {
    final removed = _options[index]['text'] as String? ?? '';
    final options = _options..removeAt(index);
    var data = {...widget.widget.data, 'options': options};
    data = addLog(data, 'option removed: $removed');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  void _resetVotes() {
    final options = _options.map((o) => {...o, 'votes': 0}).toList();
    var data = {...widget.widget.data, 'options': options};
    data = addLog(data, 'votes reset');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
  }

  @override
  void didUpdateWidget(ScoreWidget oldWidget) {
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
    final options = _options;
    final maxV = _maxVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          onChanged: (_) => widget.onUpdate(widget.widget.copyWith(title: _titleController.text)),
          style: theme.textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'Score title...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
            isDense: true,
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(options.length, (i) {
          final opt = options[i];
          final votes = (opt['votes'] as num?)?.toInt() ?? 0;
          final isWinner = votes == maxV && maxV > 0;
          final fraction = maxV > 0 ? votes / maxV : 0.0;
          return Dismissible(
            key: ValueKey(opt['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: cs.error.withAlpha(30),
              child: Icon(Icons.delete, color: cs.error),
            ),
            onDismissed: (_) => _removeOption(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isWinner)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.emoji_events, size: 20, color: cs.primary),
                        ),
                      Expanded(
                        child: Text(
                          opt['text'] as String? ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isWinner ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
                        onPressed: votes > 0 ? () => _changeVotes(i, -1) : null,
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          votes.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                        onPressed: () => _changeVotes(i, 1),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        isWinner ? cs.primary : cs.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addController,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'e.g. Design A, Pizza place...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
                onSubmitted: (_) => _addOption(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addOption,
            ),
          ],
        ),
        if (options.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetVotes,
              icon: const Icon(Icons.restart_alt, size: 20),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
