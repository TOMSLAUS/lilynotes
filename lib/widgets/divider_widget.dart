import 'package:flutter/material.dart';
import '../models/app_widget.dart';

class DividerWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const DividerWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<DividerWidget> createState() => _DividerWidgetState();
}

class _DividerWidgetState extends State<DividerWidget> {
  late TextEditingController _headerController;

  String get _style => widget.widget.data['style'] as String? ?? 'divider';
  bool get _isDivider => _style == 'divider';

  void _toggleStyle() {
    final newStyle = _isDivider ? 'header' : 'divider';
    widget.onUpdate(widget.widget.copyWith(
      data: {...widget.widget.data, 'style': newStyle},
    ));
  }

  @override
  void initState() {
    super.initState();
    _headerController = TextEditingController(text: widget.widget.title);
  }

  @override
  void didUpdateWidget(DividerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widget.id != widget.widget.id) {
      _headerController.text = widget.widget.title;
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isDivider) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: theme.colorScheme.outlineVariant, thickness: 1.5),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.title),
            onPressed: _toggleStyle,
            tooltip: 'Switch to header',


          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _headerController,
            onChanged: (_) => widget.onUpdate(
              widget.widget.copyWith(title: _headerController.text),
            ),
            style: theme.textTheme.headlineSmall,
            decoration: const InputDecoration(
              hintText: 'Header text...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.horizontal_rule),
          onPressed: _toggleStyle,
          tooltip: 'Switch to divider',
        ),
      ],
    );
  }
}
