import 'package:flutter/material.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager Dashboard'), centerTitle: true),
      body: const Center(
        child: Text('Welcome, Manager!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
