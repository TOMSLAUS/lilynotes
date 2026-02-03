import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

const _uuid = Uuid();

class ExpenseTrackerWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const ExpenseTrackerWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ExpenseTrackerWidget> createState() => _ExpenseTrackerWidgetState();
}

class _ExpenseTrackerWidgetState extends State<ExpenseTrackerWidget> with WidgetLogMixin<ExpenseTrackerWidget> {
  @override
  AppWidget get logWidget => widget.widget;
  @override
  Function(AppWidget) get logOnUpdate => widget.onUpdate;

  late TextEditingController _titleController;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  List<Map<String, dynamic>> get _items =>
      (widget.widget.data['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  double get _total => _items.fold<double>(
      0, (s, i) => s + ((i['amount'] as num?)?.toDouble() ?? 0));

  void _addItem() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null) return;
    final items = _items..add({'id': _uuid.v4(), 'name': name, 'amount': amount});
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, 'expense added: $name (${amount.toStringAsFixed(2)})');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
    _nameController.clear();
    _amountController.clear();
  }

  void _removeItem(int index) {
    final item = _items[index];
    final removedName = item['name'] as String? ?? '';
    final removedAmt = ((item['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    final items = _items..removeAt(index);
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, 'expense removed: $removedName ($removedAmt)');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  void _editItem(int index) {
    final item = _items[index];
    final nameC = TextEditingController(text: item['name'] as String? ?? '');
    final amountC = TextEditingController(
      text: ((item['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = nameC.text.trim();
              final a = double.tryParse(amountC.text.trim());
              if (n.isNotEmpty && a != null) {
                final items = _items;
                items[index] = {...items[index], 'name': n, 'amount': a};
                var data = {...widget.widget.data, 'items': items};
                data = addLog(data, 'expense edited: $n (${a.toStringAsFixed(2)})');
                widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
  }

  @override
  void didUpdateWidget(ExpenseTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widget.id != widget.widget.id) {
      _titleController.text = widget.widget.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _amountController.dispose();
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
            hintText: 'Expenses title...',
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
          final amount = (item['amount'] as num?)?.toDouble() ?? 0;
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
              onTap: () => _editItem(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] as String? ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      amount.toStringAsFixed(2),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
              flex: 2,
              child: TextField(
                controller: _nameController,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'e.g. Coffee, Bus ticket...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: '0.00',
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
          padding: const EdgeInsets.only(top: 6, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total: ', style: theme.textTheme.bodySmall),
              Text(
                _total.toStringAsFixed(2),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
