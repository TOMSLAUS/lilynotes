import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

const _uuid = Uuid();

class CounterListWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const CounterListWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<CounterListWidget> createState() => _CounterListWidgetState();
}

class _CounterListWidgetState extends State<CounterListWidget> with WidgetLogMixin<CounterListWidget> {
  late TextEditingController _titleController;
  final _addController = TextEditingController();

  @override
  AppWidget get logWidget => widget.widget;
  @override
  Function(AppWidget) get logOnUpdate => widget.onUpdate;

  List<Map<String, dynamic>> get _items =>
      (widget.widget.data['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  int get _total => _items.fold<int>(0, (s, i) => s + ((i['count'] as num?)?.toInt() ?? 0));

  void _addItem() {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    final items = _items..add({'id': _uuid.v4(), 'name': name, 'count': 0});
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, 'item added: $name');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
    _addController.clear();
  }

  void _changeCount(int index, int delta) {
    final items = _items;
    final cur = (items[index]['count'] as num?)?.toInt() ?? 0;
    final itemName = items[index]['name'] as String? ?? '';
    items[index] = {...items[index], 'count': cur + delta};
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, '$itemName: $cur → ${cur + delta}');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  void _removeItem(int index) {
    final removed = _items[index]['name'] as String? ?? '';
    final items = _items..removeAt(index);
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, 'item removed: $removed');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
  }

  @override
  void didUpdateWidget(CounterListWidget oldWidget) {
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
    final items = _items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          onChanged: (_) => widget.onUpdate(widget.widget.copyWith(title: _titleController.text)),
          style: theme.textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'List title...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
            isDense: true,
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(items.length, (i) {
          final item = items[i];
          final count = (item['count'] as num?)?.toInt() ?? 0;
          return Dismissible(
            key: ValueKey(item['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: theme.colorScheme.error.withAlpha(30),
              child: Icon(Icons.delete, color: theme.colorScheme.error),
            ),
            onDismissed: (_) => _removeItem(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item['name'] as String? ?? '', style: theme.textTheme.bodyMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                    onPressed: () => _changeCount(i, -1),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      count.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                    onPressed: () => _changeCount(i, 1),
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
                  hintText: 'e.g. Glasses of water, Push-ups...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addItem,


            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Total: $_total',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
