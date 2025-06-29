// ignore_for_file: unused_field

import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/models/user_model.dart';
import 'package:booking_management_app/core/services/booking_service.dart';
import 'package:booking_management_app/core/services/user_service.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminUserControllerProvider =
    StateNotifierProvider<AdminUserController, bool>((ref) {
      return AdminUserController(ref);
    });

class AdminUserController extends StateNotifier<bool> {
  final Ref _ref;
  AdminUserController(this._ref) : super(false);

  final _userService = UserService();
  final _bookingService = BookingService();

  /// 🔹 Create user with email/password + Firestore entry
  Future<void> createNewUser({
    required BuildContext context,
    required String email,
    required String password,
    required String role,
    required String restaurantId,
  }) async {
    try {
      state = true;

      if (email.isEmpty ||
          password.isEmpty ||
          role.isEmpty ||
          restaurantId.isEmpty) {
        throw Exception("All fields are required");
      }

      await _userService.createUserWithCredentials(
        email: email,
        password: password,
        role: role,
        restaurantId: restaurantId,
      );

      SnackbarHelper.show(
        context,
        message: 'User created successfully',
        type: MessageType.success,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: 'Failed to create user: ${e.toString()}',
        type: MessageType.error,
      );
    } finally {
      state = false;
    }
  }

  /// 🔹 Soft delete (revoke access)
  Future<void> revokeUser({
    required BuildContext context,
    required String uid,
  }) async {
    try {
      state = true;
      await _userService.revokeUserAccess(uid);
      SnackbarHelper.show(
        context,
        message: 'Access revoked',
        type: MessageType.warning,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: 'Failed to revoke user: ${e.toString()}',
        type: MessageType.error,
      );
    } finally {
      state = false;
    }
  }

  /// 🔹 Grant/Re-activate access
  Future<void> grantUser({
    required BuildContext context,
    required String uid,
  }) async {
    try {
      state = true;
      await _userService.grantUserAccess(uid);
      SnackbarHelper.show(
        context,
        message: 'Access restored',
        type: MessageType.success,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: 'Failed to grant access: ${e.toString()}',
        type: MessageType.error,
      );
    } finally {
      state = false;
    }
  }

  /// 🔹 Update user details (role, restaurant)
  Future<void> updateUser({
    required BuildContext context,
    required UserModel updatedUser,
  }) async {
    try {
      state = true;
      await _userService.updateUser(updatedUser);
      SnackbarHelper.show(
        context,
        message: 'User updated successfully',
        type: MessageType.success,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: 'Failed to update user: ${e.toString()}',
        type: MessageType.error,
      );
    } finally {
      state = false;
    }
  }

  Future<List<BookingModel>> getBookingsBetweenDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allBookings = await BookingService().fetchBookings();

      final filtered = allBookings.where((booking) {
        final bookingDate = booking.date;

        return bookingDate.isAfter(
              startDate.subtract(const Duration(days: 1)),
            ) &&
            bookingDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      return filtered;
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 Delete permanently
  Future<void> deleteUser({
    required BuildContext context,
    required String uid,
  }) async {
    try {
      state = true;
      await _userService.deleteUser(uid);
      SnackbarHelper.show(
        context,
        message: 'User deleted',
        type: MessageType.success,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: 'Failed to delete user: ${e.toString()}',
        type: MessageType.error,
      );
    } finally {
      state = false;
    }
  }
}
