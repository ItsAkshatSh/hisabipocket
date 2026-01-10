import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/router/app_router.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize storage service
  await StorageService.init();

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
    
    final appThemeMode = settingsAsync.valueOrNull?.themeMode ?? AppThemeMode.dark;
    final materialThemeMode = appThemeMode == AppThemeMode.light
        ? ThemeMode.light
        : appThemeMode == AppThemeMode.dark
            ? ThemeMode.dark
            : ThemeMode.system;

    return MaterialApp.router(
      title: 'Hisabi',
      theme: hisabiLightTheme,
      darkTheme: hisabiDarkTheme,
      themeMode: materialThemeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
