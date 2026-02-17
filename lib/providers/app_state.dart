import 'package:flutter/foundation.dart';
import '../models/app_page.dart';
import '../models/app_widget.dart';
import '../models/widget_type.dart';
import '../services/storage_service.dart';
class SearchResult {
  final AppWidget widget;
  final String pageName;
  final String pageId;

  const SearchResult({
    required this.widget,
    required this.pageName,
    required this.pageId,
  });
}

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<AppPage> _pages = [];
  String? _currentPageId;
  List<AppWidget> _currentWidgets = [];

  List<AppPage> get pages => List.unmodifiable(_pages);
  String? get currentPageId => _currentPageId;
  AppPage? get currentPage =>
      _currentPageId == null ? null : _pages.cast<AppPage?>().firstWhere(
        (p) => p!.id == _currentPageId,
        orElse: () => null,
      );
  List<AppWidget> get currentWidgets => List.unmodifiable(_currentWidgets);

  Future<void> init() async {
    final pageMaps = await _storage.getAllPages();
    _pages = pageMaps.map((m) => AppPage.fromMap(m)).toList();
    _pages.sort((a, b) => a.order.compareTo(b.order));

    if (_pages.isEmpty) {
      await _createDefaultPage();
    }

    final lastId = await _storage.getLastPageId();
    if (lastId != null && _pages.any((p) => p.id == lastId)) {
      _currentPageId = lastId;
    } else {
      _currentPageId = _pages.first.id;
    }

    await _loadCurrentWidgets();

    notifyListeners();
  }

  Future<void> _createDefaultPage() async {
    final textBlock = AppWidget(
      type: WidgetType.text,
      title: '',
      data: {'content': ''},
      order: 0,
    );
    await _storage.saveWidget(textBlock.toMap());
    final page = AppPage(name: 'My Page', order: 0, widgetIds: [textBlock.id]);
    await _storage.savePage(page.toMap());
    _pages = [page];
  }

  Future<void> _loadCurrentWidgets() async {
    if (_currentPageId == null) {
      _currentWidgets = [];
      return;
    }
    final widgetMaps = await _storage.getWidgetsForPage(_currentPageId!);
    _currentWidgets = widgetMaps.map((m) => AppWidget.fromMap(m)).toList();
    _currentWidgets.sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> addPage(String name) async {
    final textBlock = AppWidget(
      type: WidgetType.text,
      title: '',
      data: {'content': ''},
      order: 0,
    );
    await _storage.saveWidget(textBlock.toMap());
    final page = AppPage(name: name, order: _pages.length, widgetIds: [textBlock.id]);
    await _storage.savePage(page.toMap());
    _pages.add(page);
    _currentPageId = page.id;
    await _storage.setLastPageId(page.id);
    await _loadCurrentWidgets();
    notifyListeners();
  }

  Future<void> renamePage(String id, String name) async {
    final index = _pages.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final updated = _pages[index].copyWith(name: name);
    await _storage.savePage(updated.toMap());
    _pages[index] = updated;
    notifyListeners();
  }

  Future<void> deletePage(String id) async {
    await _storage.deletePage(id);
    _pages.removeWhere((p) => p.id == id);

    if (_pages.isEmpty) {
      await _createDefaultPage();
    }

    if (_currentPageId == id) {
      _currentPageId = _pages.first.id;
      await _storage.setLastPageId(_currentPageId!);
      await _loadCurrentWidgets();
    }

    notifyListeners();
  }

  Future<void> reorderPages(List<String> orderedIds) async {
    await _storage.reorderPages(orderedIds);
    final pageMap = {for (final p in _pages) p.id: p};
    _pages = orderedIds
        .where((id) => pageMap.containsKey(id))
        .toList()
        .asMap()
        .entries
        .map((e) => pageMap[e.value]!.copyWith(order: e.key))
        .toList();
    notifyListeners();
  }

  Future<void> switchToPage(String id) async {
    if (!_pages.any((p) => p.id == id)) return;
    _currentPageId = id;
    await _storage.setLastPageId(id);
    await _loadCurrentWidgets();
    notifyListeners();
  }

  Future<void> addWidget(WidgetType type) async {
    if (_currentPageId == null) return;

    final title = _defaultTitle(type);
    final data = _defaultData(type);
    final widget = AppWidget(
      type: type,
      title: title,
      data: data,
      order: _currentWidgets.length,
    );

    await _storage.saveWidget(widget.toMap());

    final newIds = <String>[...currentPage!.widgetIds, widget.id];
    _currentWidgets.add(widget);

    if (type != WidgetType.text) {
      final textBlock = AppWidget(
        type: WidgetType.text,
        title: '',
        data: {'content': ''},
        order: _currentWidgets.length,
      );
      await _storage.saveWidget(textBlock.toMap());
      newIds.add(textBlock.id);
      _currentWidgets.add(textBlock);
    }

    final page = currentPage!;
    final updatedPage = page.copyWith(widgetIds: newIds);
    await _storage.savePage(updatedPage.toMap());

    final index = _pages.indexWhere((p) => p.id == _currentPageId);
    _pages[index] = updatedPage;
    notifyListeners();

  }

  Future<void> updateWidget(AppWidget widget) async {
    final index = _currentWidgets.indexWhere((w) => w.id == widget.id);
    if (index != -1) {
      _currentWidgets[index] = widget;
      notifyListeners();
    }
    await _storage.saveWidget(widget.toMap());
  }

  Future<void> deleteWidget(String widgetId) async {
    if (_currentPageId == null) return;
    await _storage.deleteWidget(widgetId, _currentPageId!);

    _currentWidgets.removeWhere((w) => w.id == widgetId);

    await _mergeAdjacentTextBlocks();

    final page = currentPage!;
    final updatedPage = page.copyWith(
      widgetIds: _currentWidgets.map((w) => w.id).toList(),
    );
    final index = _pages.indexWhere((p) => p.id == _currentPageId);
    _pages[index] = updatedPage;
    notifyListeners();
  }

  Future<void> _mergeAdjacentTextBlocks() async {
    if (_currentPageId == null) return;
    var i = 0;
    while (i < _currentWidgets.length - 1) {
      final current = _currentWidgets[i];
      final next = _currentWidgets[i + 1];
      if (current.type == WidgetType.text && next.type == WidgetType.text) {
        final contentA = current.data['content'] as String? ?? '';
        final contentB = next.data['content'] as String? ?? '';
        final merged = contentA.isEmpty
            ? contentB
            : contentB.isEmpty
                ? contentA
                : '$contentA\n$contentB';
        final updated = current.copyWith(data: {...current.data, 'content': merged});
        _currentWidgets[i] = updated;
        await _storage.saveWidget(updated.toMap());
        _currentWidgets.removeAt(i + 1);
        await _storage.deleteWidget(next.id, _currentPageId!);
      } else {
        i++;
      }
    }
  }

  Future<void> reorderWidgets(List<String> orderedWidgetIds) async {
    if (_currentPageId == null) return;
    await _storage.reorderWidgets(_currentPageId!, orderedWidgetIds);

    final widgetMap = {for (final w in _currentWidgets) w.id: w};
    _currentWidgets = orderedWidgetIds
        .where((id) => widgetMap.containsKey(id))
        .toList()
        .asMap()
        .entries
        .map((e) => widgetMap[e.value]!.copyWith(order: e.key))
        .toList();

    final page = currentPage!;
    final updatedPage = page.copyWith(widgetIds: orderedWidgetIds);
    final pageIndex = _pages.indexWhere((p) => p.id == _currentPageId);
    _pages[pageIndex] = updatedPage;
    notifyListeners();
  }

  Future<List<SearchResult>> searchWidgets(String query) async {
    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    for (final page in _pages) {
      final widgetMaps = await _storage.getWidgetsForPage(page.id);
      for (final wMap in widgetMaps) {
        final widget = AppWidget.fromMap(wMap);
        if (_widgetMatchesQuery(widget, lowerQuery)) {
          results.add(SearchResult(
            widget: widget,
            pageName: page.name,
            pageId: page.id,
          ));
        }
      }
    }

    return results;
  }

  bool _widgetMatchesQuery(AppWidget widget, String query) {
    if (widget.title.toLowerCase().contains(query)) return true;

    final data = widget.data;
    if (data['content'] is String &&
        (data['content'] as String).toLowerCase().contains(query)) {
      return true;
    }

    if (data['items'] is List) {
      for (final item in data['items'] as List) {
        if (item is Map) {
          for (final value in item.values) {
            if (value is String && value.toLowerCase().contains(query)) {
              return true;
            }
          }
        }
      }
    }

    if (data['options'] is List) {
      for (final option in data['options'] as List) {
        if (option is Map && option['text'] is String &&
            (option['text'] as String).toLowerCase().contains(query)) {
          return true;
        }
      }
    }

    return false;
  }

  String _defaultTitle(WidgetType type) {
    switch (type) {
      case WidgetType.text:
        return '';
      case WidgetType.score:
        return 'Score';
      case WidgetType.counterList:
        return 'Counter List';
      case WidgetType.checklist:
        return 'Checklist';
      case WidgetType.habitTracker:
        return 'Habit Tracker';
      case WidgetType.timer:
        return 'Timer';
      case WidgetType.bookmark:
        return 'Bookmarks';
      case WidgetType.divider:
        return 'Divider';
      case WidgetType.progressBar:
        return 'Progress';
      case WidgetType.expenseTracker:
        return 'Expense Tracker';
    }
  }

  Map<String, dynamic> _defaultData(WidgetType type) {
    switch (type) {
      case WidgetType.text:
        return {'content': ''};
      case WidgetType.score:
        return {'options': [], 'showResults': true};
      case WidgetType.counterList:
        return {'items': []};
      case WidgetType.checklist:
        return {'items': []};
      case WidgetType.habitTracker:
        return {'habits': []};
      case WidgetType.timer:
        return {'mode': 'timer', 'durationSeconds': 300, 'laps': []};
      case WidgetType.bookmark:
        return {'items': []};
      case WidgetType.divider:
        return {'style': 'divider'};
      case WidgetType.progressBar:
        return {'current': 0, 'target': 10};
      case WidgetType.expenseTracker:
        return {'items': []};
    }
  }
}
