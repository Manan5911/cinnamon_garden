import 'package:booking_management_app/core/screens/kitchen/kitchen_dashboard.dart';
import 'package:booking_management_app/core/screens/manager/manager_dashboard.dart';
import 'package:booking_management_app/core/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  if (loginTime != null && (now - loginTime) > 21600000) {
    await FirebaseAuth.instance.signOut();
    await prefs.remove('loginTime');
  }

  String? role;

  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    role = doc.data()?['role'];
  }

  runApp(ProviderScope(child: MyApp(role: role)));
}

class MyApp extends StatelessWidget {
  final String? role;

  const MyApp({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Widget home;

    switch (role) {
      case 'admin':
        home = const AdminDashboard(showLoginSuccess: false);
        break;
      case 'manager':
        home = const ManagerDashboard(showLoginSuccess: false);
        break;
      case 'kitchen':
        home = const KitchenDashboard(showLoginSuccess: false);
        break;
      default:
        home = const LoginScreen();
    }

    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'CinnaOps',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}

class RoleBasedRedirector extends StatelessWidget {
  const RoleBasedRedirector({super.key});

  Future<String?> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['role'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final role = snapshot.data;

        switch (role) {
          case 'admin':
            return const AdminDashboard(showLoginSuccess: false);
          case 'manager':
            return const ManagerDashboard(showLoginSuccess: false);
          case 'kitchen':
            return const KitchenDashboard(showLoginSuccess: false);
          default:
            return const LoginScreen(); // fallback in case role is invalid
        }
      },
    );
  }
}
