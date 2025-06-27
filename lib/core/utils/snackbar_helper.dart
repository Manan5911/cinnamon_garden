import 'package:flutter/material.dart';

enum MessageType { success, error, warning }

class SnackbarHelper {
  static void show(
    BuildContext context, {
    required String message,
    required MessageType type,
  }) {
    final icon = {
      MessageType.success: Icons.check_circle_outline,
      MessageType.error: Icons.error_outline,
      MessageType.warning: Icons.warning_amber_rounded,
    }[type];

    final background = {
      MessageType.success: const Color(0xFF4CAF50),
      MessageType.error: const Color(0xFFF44336),
      MessageType.warning: const Color(0xFFFF9800),
    }[type];

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.fixed, // full-width
      backgroundColor: background,
      elevation: 6,
      duration: const Duration(seconds: 3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      content: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedSlide(
          offset: const Offset(0, 0.1),
          duration: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
