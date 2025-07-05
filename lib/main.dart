import 'package:booking_management_app/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'core/screens/auth/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'CinnaOps',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
