import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
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
