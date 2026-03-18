import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hhmevsifjcdkuowzpupa.supabase.co',
    anonKey: 'sb_publishable_GprqRBJVc-SzALVC-HrZbg_YGU22_TB',
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ScanBibliApp());
}

class ScanBibliApp extends StatelessWidget {
  const ScanBibliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'scan_bibli',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
