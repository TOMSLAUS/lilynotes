import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/app_widget.dart';
import 'widget_log_mixin.dart';

const _uuid = Uuid();

class BookmarkWidget extends StatefulWidget {
  final AppWidget widget;
  final Function(AppWidget) onUpdate;
  final VoidCallback onDelete;

  const BookmarkWidget({
    super.key,
    required this.widget,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<BookmarkWidget> createState() => _BookmarkWidgetState();
}

class _BookmarkWidgetState extends State<BookmarkWidget> with WidgetLogMixin<BookmarkWidget> {
  @override
  AppWidget get logWidget => widget.widget;
  @override
  Function(AppWidget) get logOnUpdate => widget.onUpdate;

  late TextEditingController _titleController;
  final _urlController = TextEditingController();
  final _linkTitleController = TextEditingController();

  List<Map<String, dynamic>> get _items =>
      (widget.widget.data['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _addBookmark() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    final title = _linkTitleController.text.trim();
    final items = _items
      ..add({
        'id': _uuid.v4(),
        'url': url,
        'title': title.isEmpty ? url : title,
      });
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, 'bookmark added: ${title.isEmpty ? url : title}');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
    _urlController.clear();
    _linkTitleController.clear();
  }

  void _removeItem(int index) {
    final removed = _items[index]['title'] as String? ?? _items[index]['url'] as String? ?? '';
    final items = _items..removeAt(index);
    var data = {...widget.widget.data, 'items': items};
    data = addLog(data, 'bookmark removed: $removed');
    widget.onUpdate(widget.widget.copyWith(title: _titleController.text, data: data));
  }

  Future<void> _openUrl(String url) async {
    var uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!uri.hasScheme) uri = Uri.parse('https://$url');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
  }

  @override
  void didUpdateWidget(BookmarkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widget.id != widget.widget.id) {
      _titleController.text = widget.widget.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _linkTitleController.dispose();
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
            hintText: 'Bookmarks title...',
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
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.link, size: 24, color: theme.colorScheme.primary),
              title: Text(
                item['title'] as String? ?? item['url'] as String? ?? '',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                item['url'] as String? ?? '',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openUrl(item['url'] as String? ?? ''),
            ),
          );
        }),
        const Divider(height: 8),
        TextField(
          controller: _urlController,
          style: theme.textTheme.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'e.g. https://example.com...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
            isDense: true,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _linkTitleController,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Title (optional)...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
                onSubmitted: (_) => _addBookmark(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addBookmark,


            ),
          ],
        ),
      ],
    );
  }
}
