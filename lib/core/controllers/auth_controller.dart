import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);

class AuthState {
  final bool isLoading;
  AuthState({required this.isLoading});
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState(isLoading: false));

  Future<void> signInWithEmailPassword({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      state = AuthState(isLoading: true);

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw 'Unexpected login error. Please try again.';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw 'User not registered in Firestore.';
      }

      final data = userDoc.data()!;
      final role = data['role'];

      if (role != 'admin' && role != 'manager' && role != 'kitchen') {
        throw 'Unknown role: $role';
      }

      return;
    } on FirebaseAuthException catch (e) {
      final message = e.message?.toLowerCase() ?? '';
      final code = e.code;

      if (code == 'user-not-found') {
        throw 'No user found with this email.';
      } else if (code == 'wrong-password') {
        throw 'Incorrect password.';
      } else if (code == 'invalid-email') {
        throw 'Invalid email address.';
      } else if (code == 'network-request-failed') {
        throw 'No internet connection.';
      } else if (code == 'user-disabled') {
        throw 'User account has been disabled.';
      } else if (message.contains('credential is incorrect') ||
          message.contains('invalid login credentials') ||
          message.contains('malformed') ||
          message.contains('expired')) {
        throw 'Invalid email or password.';
      } else {
        throw message.isNotEmpty ? message : 'Login failed. Try again.';
      }
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    } finally {
      state = AuthState(isLoading: false);
    }
  }
}
