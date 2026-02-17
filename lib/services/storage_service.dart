import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _pagesBox = 'pages';
  static const String _widgetsBox = 'widgets';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLastPageId = 'last_page_id';

  late Box<Map> _pages;
  late Box<Map> _widgets;
  late SharedPreferences _prefs;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _pages = await Hive.openBox<Map>(_pagesBox);
    _widgets = await Hive.openBox<Map>(_widgetsBox);
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Map<String, dynamic> _safeMap(Map? raw) {
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return {};
    }
  }

  int _safeInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  Future<List<Map<String, dynamic>>> getAllPages() async {
    try {
      final pages = _pages.values
          .map((m) => _safeMap(m))
          .where((m) => m.isNotEmpty)
          .toList();
      pages.sort((a, b) => _safeInt(a['order']).compareTo(_safeInt(b['order'])));
      return pages;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPage(String id) async {
    try {
      final raw = _pages.get(id);
      if (raw == null) return null;
      return _safeMap(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePage(Map<String, dynamic> page) async {
    try {
      await _pages.put(page['id'] as String, page);
    } catch (_) {}
  }

  Future<void> deletePage(String id) async {
    try {
      final page = _pages.get(id);
      if (page != null) {
        final widgetIds = List<String>.from(page['widgetIds'] ?? []);
        for (final wid in widgetIds) {
          await _widgets.delete(wid);
        }
      }
      await _pages.delete(id);
    } catch (_) {}
  }

  Future<void> reorderPages(List<String> orderedIds) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        final raw = _pages.get(orderedIds[i]);
        if (raw != null) {
          final page = _safeMap(raw);
          page['order'] = i;
          page['updatedAt'] = DateTime.now().toIso8601String();
          await _pages.put(orderedIds[i], page);
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getWidget(String id) async {
    try {
      final raw = _widgets.get(id);
      if (raw == null) return null;
      return _safeMap(raw);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWidgetsForPage(String pageId) async {
    try {
      final page = _pages.get(pageId);
      if (page == null) return [];
      final widgetIds = List<String>.from(page['widgetIds'] ?? []);
      final results = <Map<String, dynamic>>[];
      for (final wid in widgetIds) {
        final raw = _widgets.get(wid);
        if (raw != null) {
          final m = _safeMap(raw);
          if (m.isNotEmpty) results.add(m);
        }
      }
      results.sort((a, b) => _safeInt(a['order']).compareTo(_safeInt(b['order'])));
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWidget(Map<String, dynamic> widget) async {
    try {
      await _widgets.put(widget['id'] as String, widget);
    } catch (_) {}
  }

  Future<void> deleteWidget(String widgetId, String pageId) async {
    try {
      await _widgets.delete(widgetId);
      final raw = _pages.get(pageId);
      if (raw != null) {
        final page = _safeMap(raw);
        final ids = List<String>.from(page['widgetIds'] ?? []);
        ids.remove(widgetId);
        page['widgetIds'] = ids;
        page['updatedAt'] = DateTime.now().toIso8601String();
        await _pages.put(pageId, page);
      }
    } catch (_) {}
  }

  Future<void> reorderWidgets(String pageId, List<String> orderedIds) async {
    try {
      final raw = _pages.get(pageId);
      if (raw != null) {
        final page = _safeMap(raw);
        page['widgetIds'] = orderedIds;
        page['updatedAt'] = DateTime.now().toIso8601String();
        await _pages.put(pageId, page);
      }
      for (var i = 0; i < orderedIds.length; i++) {
        final wRaw = _widgets.get(orderedIds[i]);
        if (wRaw != null) {
          final w = _safeMap(wRaw);
          w['order'] = i;
          w['updatedAt'] = DateTime.now().toIso8601String();
          await _widgets.put(orderedIds[i], w);
        }
      }
    } catch (_) {}
  }

  Future<String> getThemeMode() async {
    try {
      return _prefs.getString(_keyThemeMode) ?? 'system';
    } catch (_) {
      return 'system';
    }
  }

  Future<void> setThemeMode(String mode) async {
    try {
      await _prefs.setString(_keyThemeMode, mode);
    } catch (_) {}
  }

  Future<String?> getLastPageId() async {
    try {
      return _prefs.getString(_keyLastPageId);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLastPageId(String id) async {
    try {
      await _prefs.setString(_keyLastPageId, id);
    } catch (_) {}
  }
}
