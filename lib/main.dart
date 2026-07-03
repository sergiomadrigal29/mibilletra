import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService.executePeriodicTask();
      return true;
    } catch (e) {
      debugPrint('WorkManager task failed: $e');
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  await SupabaseService.initialize();
  await NotificationService.instance.init();
  runApp(const MiBilleteraApp());
}

class MiBilleteraApp extends StatelessWidget {
  const MiBilleteraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = SupabaseService.instance.isLoggedIn;
    return MaterialApp(
      title: 'Mi Billetera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
