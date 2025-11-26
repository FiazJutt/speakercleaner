import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/notification_service.dart';
import 'viewmodels/settings_provider.dart';
import 'viewmodels/subscription_provider.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();
  
  // Request permissions early
  await NotificationService().requestPermissions();
  
  // WidgetsFlutterBinding.ensureInitialized();
  // try {
  //   await NotificationService().init();
  // } catch (e) {
  //   // Handle initialization error gracefully
  //   print('Notification service initialization failed: $e');
  // }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Initialize providers
    ref.watch(subscriptionProvider);
    ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Speaker Cleaner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
