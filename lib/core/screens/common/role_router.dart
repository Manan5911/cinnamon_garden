import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../manager/manager_dashboard.dart';
import '../kitchen/kitchen_dashboard.dart';
import '../../utils/snackbar_helper.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({Key? key}) : super(key: key);

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        SnackbarHelper.show(
          context,
          message: "User not logged in",
          type: MessageType.error,
        );
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        SnackbarHelper.show(
          context,
          message: "User data not found",
          type: MessageType.error,
        );
        return;
      }

      final user = UserModel.fromMap(doc.data()!, doc.id);

      if (!user.isActive) {
        SnackbarHelper.show(
          context,
          message: "Access revoked",
          type: MessageType.warning,
        );
        return;
      }

      switch (user.role) {
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
          break;
        case 'manager':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ManagerDashboard()),
          );
          break;
        case 'kitchen':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const KitchenDashboard()),
          );
          break;
        default:
          SnackbarHelper.show(
            context,
            message: "Invalid role",
            type: MessageType.error,
          );
      }
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: "Routing failed: $e",
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomLoader(), // 👈 Replaces CircularProgressIndicator
    );
  }
}
