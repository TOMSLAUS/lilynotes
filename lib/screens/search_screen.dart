import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lilynotes/providers/providers.dart';
import 'package:lilynotes/providers/app_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<SearchResult> _results = [];
  bool _hasSearched = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final appState = context.read<AppState>();
    final results = await appState.searchWidgets(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _hasSearched = true;
      _loading = false;
    });
  }

  String _snippet(SearchResult result, String query) {
    final data = result.widget.data;
    if (data['content'] is String) {
      final content = data['content'] as String;
      if (content.toLowerCase().contains(query.toLowerCase())) {
        return _extractSnippet(content, query);
      }
    }
    if (data['items'] is List) {
      for (final item in data['items'] as List) {
        if (item is Map) {
          for (final value in item.values) {
            if (value is String && value.toLowerCase().contains(query.toLowerCase())) {
              return _extractSnippet(value, query);
            }
          }
        }
      }
    }
    if (data['options'] is List) {
      for (final option in data['options'] as List) {
        if (option is Map && option['text'] is String) {
          final text = option['text'] as String;
          if (text.toLowerCase().contains(query.toLowerCase())) {
            return _extractSnippet(text, query);
          }
        }
      }
    }
    return result.widget.title;
  }

  String _extractSnippet(String text, String query) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx == -1) return text.length > 80 ? '${text.substring(0, 80)}...' : text;
    final start = (idx - 30).clamp(0, text.length);
    final end = (idx + query.length + 50).clamp(0, text.length);
    var snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';
    return snippet;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search across all pages',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _controller.clear(),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (!_hasSearched && !_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Search across all pages',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final query = _controller.text.trim();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final result = _results[index];
        return ListTile(
          title: Text(
            result.widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _snippet(result, query),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          trailing: Chip(
            label: Text(result.pageName),
            visualDensity: VisualDensity.compact,
          ),
          onTap: () {
            final appState = context.read<AppState>();
            appState.switchToPage(result.pageId);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
