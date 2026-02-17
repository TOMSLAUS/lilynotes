import 'package:flutter/material.dart';
import '../models/app_widget.dart';

class TextBlockWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;
  final bool fillHeight;

  const TextBlockWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
    this.fillHeight = false,
  });

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.widget.data['content'] as String? ?? '',
    );
  }

  @override
  void didUpdateWidget(TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widget.id != widget.widget.id) {
      _controller.text = widget.widget.data['content'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onUpdate(widget.widget.copyWith(
      data: {...widget.widget.data, 'content': value},
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(height: 1.6);
    const decoration = InputDecoration(
      hintText: '',
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
    );
    if (!widget.fillHeight) {
      return TextField(
        controller: _controller,
        maxLines: null,
        minLines: 1,
        style: style,
        decoration: decoration,
        onChanged: _onChanged,
      );
    }
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: style,
        decoration: decoration,
        onChanged: _onChanged,
      ),
    );
  }
}
