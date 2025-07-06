import 'package:booking_management_app/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/screens/auth/login_screen.dart';
import 'core/screens/admin/admin_dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final loginTime = prefs.getInt('loginTime');
  final now = DateTime.now().millisecondsSinceEpoch;

  final user = FirebaseAuth.instance.currentUser;

  // Invalidate session if more than 48 hours (172800000 ms) have passed
  print('loginTime: $loginTime');
  print('now: $now');
  print('$now - $loginTime');
  if (loginTime != null && (now - loginTime) > 86400000) {
    await FirebaseAuth.instance.signOut();
    await prefs.remove('loginTime');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'CinnaOps',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: user != null
          ? const AdminDashboard(showLoginSuccess: false)
          : const LoginScreen(),
    );
  }
}
