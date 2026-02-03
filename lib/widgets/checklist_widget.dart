import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

const _uuid = Uuid();

class ChecklistWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const ChecklistWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> with WidgetLogMixin<ChecklistWidget> {
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

  int get _checked => _items.where((i) => i['checked'] == true).length;

  void _toggle(int index) {
    final items = _items;
    final newChecked = !(items[index]['checked'] == true);
    items[index] = {...items[index], 'checked': newChecked};
    var data = {...widget.widget.data, 'items': items};
    final itemText = items[index]['text'] as String? ?? '';
    data = addLog(data, '${newChecked ? 'checked' : 'unchecked'}: $itemText');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  void _addItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    final items = _items..add({'id': _uuid.v4(), 'text': text, 'checked': false});
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, 'item added: $text');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
    _addController.clear();
  }

  void _removeItem(int index) {
    final removed = _items[index]['text'] as String? ?? '';
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
  void didUpdateWidget(ChecklistWidget oldWidget) {
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
    final total = items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          onChanged: (_) => widget.onUpdate(widget.widget.copyWith(title: _titleController.text)),
          style: theme.textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'Checklist title...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
            isDense: true,
          ),
        ),
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 4),
            child: Text(
              '$_checked/$total done',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _checked == total && total > 0
                    ? theme.colorScheme.primary
                    : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (total > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? _checked / total : 0,
              minHeight: 4,
            ),
          ),
        const SizedBox(height: 4),
        ...List.generate(items.length, (i) {
          final item = items[i];
          final checked = item['checked'] == true;
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
            child: InkWell(
              onTap: () => _toggle(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (_) => _toggle(i),
        

                    ),
                    Expanded(
                      child: Text(
                        item['text'] as String? ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: checked ? TextDecoration.lineThrough : null,
                          color: checked
                              ? theme.colorScheme.onSurface.withAlpha(100)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  hintText: 'e.g. Buy groceries, Call dentist...',
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
      ],
    );
  }
}
