// Updated KitchenStaffScreen
import 'package:booking_management_app/core/models/restaurant_model.dart';
import 'package:booking_management_app/core/models/user_model.dart';
import 'package:booking_management_app/core/services/restaurant_service.dart';
import 'package:booking_management_app/core/services/user_service.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class KitchenStaffScreen extends StatefulWidget {
  const KitchenStaffScreen({super.key});

  @override
  State<KitchenStaffScreen> createState() => _KitchenStaffScreenState();
}

class _KitchenStaffScreenState extends State<KitchenStaffScreen> {
  Map<String, String> _restaurantNameById = {};
  final UserService _userService = UserService();
  List<UserModel> _kitchenStaff = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadKitchenStaff();
    _loadRestaurantNames();
  }

  Future<void> _loadKitchenStaff() async {
    final data = await _userService.getUsersByRole("kitchen");
    if (mounted) {
      setState(() {
        _kitchenStaff = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRestaurantNames() async {
    final restaurants = await RestaurantService().getAllRestaurants();
    setState(() {
      _restaurantNameById = {for (var r in restaurants) r.id: r.name};
    });
  }

  void _showStaffModal({UserModel? existing}) {
    final emailController = TextEditingController(text: existing?.email ?? '');
    final passwordController = TextEditingController();
    Restaurant? selectedRestaurant;

    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null ? 'Add Kitchen Staff' : 'Edit Staff',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (existing == null)
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade500),
                        ),
                      ),
                      obscureText: true,
                    ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final restaurants = await RestaurantService()
                          .getAllRestaurants();
                      if (!mounted) return;

                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (context) {
                          return ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: restaurants.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final r = restaurants[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                dense: true,
                                visualDensity: const VisualDensity(
                                  vertical: -2,
                                ),
                                title: Text(
                                  r.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  r.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                onTap: () {
                                  setModalState(() {
                                    selectedRestaurant = r;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedRestaurant?.name ?? 'Select Restaurant',
                        style: TextStyle(
                          color: selectedRestaurant == null
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();
                        final restaurantId =
                            selectedRestaurant?.id ??
                            existing?.restaurantId ??
                            '';

                        if (email.isEmpty ||
                            restaurantId.isEmpty ||
                            (existing == null && password.isEmpty))
                          return;

                        Navigator.pop(modalContext);
                        await Future.delayed(const Duration(milliseconds: 100));

                        setState(() => _isLoading = true);

                        try {
                          if (existing == null) {
                            await _userService.createUserWithCredentials(
                              email: email,
                              password: password,
                              role: 'kitchen',
                              restaurantId: restaurantId,
                            );
                          } else {
                            final updatedUser = UserModel(
                              uid: existing.uid,
                              email: email,
                              role: existing.role,
                              restaurantId: restaurantId,
                              isActive: existing.isActive,
                            );
                            await _userService.updateUser(updatedUser);
                          }

                          await _loadKitchenStaff();

                          SnackbarHelper.show(
                            parentContext,
                            message: existing == null
                                ? 'Kitchen staff added successfully'
                                : 'Kitchen staff updated successfully',
                            type: MessageType.success,
                          );
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'email-already-in-use') {
                            // Show friendly error or prompt admin to use a different email
                            SnackbarHelper.show(
                              parentContext,
                              message: "Email is already in use",
                              type: MessageType.error,
                            );
                          }
                        } catch (_) {}
                        if (mounted) setState(() => _isLoading = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pinkThemed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        existing == null ? 'Add' : 'Update',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Staff?'),
        content: Text('Are you sure you want to delete ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              await _userService.deleteUser(user.uid);
              await _loadKitchenStaff();
              if (mounted) {
                SnackbarHelper.show(
                  context,
                  message: 'Deleted',
                  type: MessageType.success,
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.secondary,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Kitchen Staff',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 36,
                          color: Colors.white,
                        ),
                        onPressed: () => _showStaffModal(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _kitchenStaff.isEmpty
                          ? const Center(child: Text('No kitchen staff found'))
                          : ListView.separated(
                              itemCount: _kitchenStaff.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final staff = _kitchenStaff[index];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            staff.email,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Restaurant: ${_restaurantNameById[staff.restaurantId] ?? "-"}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Material(
                                            color: Colors.grey.shade200,
                                            shape: const CircleBorder(),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: AppColors.primary,
                                              ),
                                              onPressed: () => _showStaffModal(
                                                existing: staff,
                                              ),
                                              tooltip: 'Edit',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Material(
                                            color: Colors.grey.shade200,
                                            shape: const CircleBorder(),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: AppColors.primary,
                                              ),
                                              onPressed: () =>
                                                  _confirmDelete(staff),
                                              tooltip: 'Delete',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading && _kitchenStaff.isNotEmpty)
          const IgnorePointer(child: CustomLoader()),
      ],
    );
  }
}
