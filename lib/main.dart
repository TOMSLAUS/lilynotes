import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lilynotes/theme/theme.dart';
import 'package:lilynotes/providers/providers.dart';
import 'package:lilynotes/services/services.dart';
import 'package:lilynotes/models/app_widget.dart';
import 'package:lilynotes/screens/home_screen.dart';

/// Called by home_widget when a user taps an interactive element on the home screen widget.
@pragma("vm:entry-point")
FutureOr<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;

  await Hive.initFlutter();
  await StorageService().init();
  await WidgetBridgeService.init();

  final host = uri.host;
  final params = uri.queryParameters;
  final widgetId = params['widgetId'];
  if (widgetId == null) return;

  final storage = StorageService();
  final widgetMap = await storage.getWidget(widgetId);
  if (widgetMap == null) return;
  final appWidget = AppWidget.fromMap(widgetMap);

  switch (host) {
    case 'habit-toggle':
      final habitId = params['habitId'];
      if (habitId == null) return;
      final habits = (appWidget.data['habits'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final idx = habits.indexWhere((h) => h['id'] == habitId);
      if (idx == -1) return;
      final days = List<String>.from(habits[idx]['completedDays'] as List? ?? []);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (days.contains(today)) {
        days.remove(today);
      } else {
        days.add(today);
      }
      habits[idx] = {...habits[idx], 'completedDays': days};
      final updated = appWidget.copyWith(data: {...appWidget.data, 'habits': habits});
      await storage.saveWidget(updated.toMap());
      await WidgetBridgeService.pushWidget(updated);
      break;

    case 'checklist-toggle':
      final indexStr = params['index'];
      if (indexStr == null) return;
      final index = int.tryParse(indexStr);
      if (index == null) return;
      final items = (appWidget.data['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (index < 0 || index >= items.length) return;
      items[index] = {...items[index], 'checked': !(items[index]['checked'] == true)};
      final updated = appWidget.copyWith(data: {...appWidget.data, 'items': items});
      await storage.saveWidget(updated.toMap());
      await WidgetBridgeService.pushWidget(updated);
      break;

    case 'progress-increment':
      final current = (appWidget.data['current'] as num?)?.toInt() ?? 0;
      final updated = appWidget.copyWith(data: {...appWidget.data, 'current': current + 1});
      await storage.saveWidget(updated.toMap());
      await WidgetBridgeService.pushWidget(updated);
      break;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    await StorageService().init();
    await WidgetBridgeService.init();
    await HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);
  } catch (e) {
    runApp(_ErrorApp(error: e.toString()));
    return;
  }
  runApp(const LilyNotesApp());
}

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize storage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LilyNotesApp extends StatefulWidget {
  const LilyNotesApp({super.key});

  @override
  State<LilyNotesApp> createState() => _LilyNotesAppState();
}

class _LilyNotesAppState extends State<LilyNotesApp> {
  late final AppState _appState;
  late final ThemeProvider _themeProvider;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _themeProvider = ThemeProvider();
    _initFuture = _initProviders();
  }

  Future<void> _initProviders() async {
    await Future.wait([
      _appState.init(),
      _themeProvider.init(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appState),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          return Consumer<ThemeProvider>(
            builder: (context, theme, _) {
              return MaterialApp(
                title: 'Lily Notes',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: theme.themeMode,
                home: snapshot.connectionState == ConnectionState.done
                    ? const HomeScreen()
                    : const _SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lily Notes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
