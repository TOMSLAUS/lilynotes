import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:lilynotes/theme/theme.dart';
import 'package:lilynotes/providers/providers.dart';
import 'package:lilynotes/services/services.dart';
import 'package:lilynotes/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    await StorageService().init();
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
