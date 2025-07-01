import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class ManagerDashboard extends StatefulWidget {
  final bool showLoginSuccess;
  const ManagerDashboard({super.key, this.showLoginSuccess = false});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
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
      appBar: AppBar(title: const Text('Manager Dashboard'), centerTitle: true),
      body: const Center(
        child: Text('Welcome, Manager!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
