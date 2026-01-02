import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/router/app_router.dart';
import 'package:hisabi/core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize persistent storage
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
    // Initial launch from widget
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (!mounted || uri == null) return;
      _handleWidgetAction(uri.host);
    });

    // Clicks while app is running
    HomeWidget.widgetClicked.listen((uri) {
      if (!mounted || uri == null) return;
      _handleWidgetAction(uri.host);
    });
  }

  void _handleWidgetAction(String? action) {
    if (action == null) return;
    final router = ref.read(goRouterProvider);
    if (action == 'quick_voice_add') {
      router.go('/add-receipt'); // Route to your voice/receipt screen
    } else if (action == 'open_dashboard') {
      router.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Hisabi',
      theme: hisabiDarkTheme,
      themeMode: ThemeMode.dark, 
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
