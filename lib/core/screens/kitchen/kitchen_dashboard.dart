import 'package:flutter/material.dart';

class KitchenDashboard extends StatelessWidget {
  const KitchenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Dashboard'), centerTitle: true),
      body: const Center(
        child: Text('Welcome, Kitchen Staff!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
