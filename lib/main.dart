import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/router/app_router.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Error initializing Firebase: $e');
    print('Stack trace: $stackTrace');
  }
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
  }
  
  try {
    await StorageService.init();
  } catch (e, stackTrace) {
    print('❌ Error initializing storage: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _listenToWidgetLaunches();
  }

  void _listenToWidgetLaunches() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (!mounted || uri == null) return;
      _handleWidgetAction(uri.host);
    });

    HomeWidget.widgetClicked.listen((uri) {
      if (!mounted || uri == null) return;
      _handleWidgetAction(uri.host);
    });
  }

  void _handleWidgetAction(String? action) {
    if (action == null) return;
    final router = ref.read(goRouterProvider);
    if (action == 'quick_voice_add') {
      router.go('/add-receipt');
    } else if (action == 'open_dashboard') {
      router.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final settingsAsync = ref.watch(settingsProvider);
    
    return settingsAsync.when(
      data: (settings) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            return MaterialApp.router(
              title: 'Hisabi',
              theme: AppTheme.getTheme(
                settings.themeSelection, 
                Brightness.light, 
                lightDynamic,
              ),
              darkTheme: AppTheme.getTheme(
                settings.themeSelection, 
                Brightness.dark, 
                darkDynamic,
              ),
              themeMode: settings.themeMode == AppThemeMode.light
                  ? ThemeMode.light
                  : settings.themeMode == AppThemeMode.dark
                      ? ThemeMode.dark
                      : ThemeMode.system,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
