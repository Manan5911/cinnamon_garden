import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class KitchenDashboard extends StatefulWidget {
  final bool showLoginSuccess;
  const KitchenDashboard({super.key, this.showLoginSuccess = false});

  @override
  State<KitchenDashboard> createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends State<KitchenDashboard> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.showLoginSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.show(
          context,
          message: 'Login successful!',
          type: MessageType.success,
        );
      });
    }
  }

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
