import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'features/dashboard/dashboard_dispatcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AreteEduApp());
}

class AreteEduApp extends StatelessWidget {
  const AreteEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aretéEDU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryTeal,
          primary: AppColors.primaryTeal,
          secondary: AppColors.accentOrange,
        ),
        scaffoldBackgroundColor: AppColors.lightBg,
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    if (!mounted) return;
    if (token != null && role != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardDispatcher(role: role)),
      );
    } else {
      // Guest Mode: Users can immediately browse schools & view locations without logging in!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardDispatcher(role: 'GUEST')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );
  }
}
