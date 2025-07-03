import 'package:booking_management_app/core/models/restaurant_model.dart';
import 'package:booking_management_app/core/models/user_model.dart';
import 'package:booking_management_app/core/services/restaurant_service.dart';
import 'package:booking_management_app/core/services/user_service.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  Map<String, String> _restaurantNameById = {};
  final UserService _userService = UserService();
  List<UserModel> _managers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadManagers();
    _loadRestaurantNames();
  }

  Future<void> _loadManagers() async {
    final data = await _userService.getUsersByRole("manager");
    if (mounted) {
      setState(() {
        _managers = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRestaurantNames() async {
    final restaurants = await RestaurantService().getAllRestaurants();
    if (!mounted) return;
    setState(() {
      _restaurantNameById = {for (var r in restaurants) r.id: r.name};
    });
  }

  void _showManagerModal({UserModel? existing}) {
    final emailController = TextEditingController(text: existing?.email ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? restaurantError;

    bool showPassword = false;
    bool showConfirmPassword = false;

    Restaurant? selectedRestaurant;

    // Pre-fill the restaurant on edit
    if (existing != null && selectedRestaurant == null) {
      final restId = existing.restaurantId;
      if (restId.isNotEmpty) {
        selectedRestaurant = Restaurant(
          id: restId,
          name: _restaurantNameById[restId] ?? 'Unknown',
          address: '',
        );
      }
    }

    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SingleChildScrollView(
          child: Padding(
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
                      existing == null ? 'Add Manager' : 'Edit Manager',
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
                        errorText: emailError,
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

                    if (existing == null) ...[
                      TextField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setModalState(
                              () => showPassword = !showPassword,
                            ),
                          ),
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
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          errorText: confirmPasswordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setModalState(
                              () => showConfirmPassword = !showConfirmPassword,
                            ),
                          ),
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
                    ],

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
                    if (restaurantError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 6),
                        child: Text(
                          restaurantError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
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
                          final confirmPassword = confirmPasswordController.text
                              .trim();
                          final restaurantId =
                              selectedRestaurant?.id ??
                              existing?.restaurantId ??
                              '';

                          setModalState(() {
                            emailError = passwordError = confirmPasswordError =
                                restaurantError = null;

                            final emailRegex = RegExp(
                              r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                            );

                            if (email.isEmpty) {
                              setModalState(
                                () => emailError = "Email is required",
                              );
                            } else if (!emailRegex.hasMatch(email)) {
                              setModalState(
                                () => emailError = "Invalid email format",
                              );
                            }

                            if (existing == null && password.isEmpty) {
                              passwordError = "Password required";
                            }
                            if (existing == null && confirmPassword.isEmpty) {
                              confirmPasswordError = "Confirm your password";
                            }
                            if (existing == null &&
                                password != confirmPassword) {
                              confirmPasswordError = "Passwords do not match";
                            }
                            if (selectedRestaurant == null) {
                              restaurantError = "Select a restaurant";
                            }
                          });

                          if ([
                            emailError,
                            passwordError,
                            confirmPasswordError,
                            restaurantError,
                          ].any((e) => e != null))
                            return;

                          Navigator.pop(modalContext);
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );
                          setState(() => _isLoading = true);

                          try {
                            if (existing == null) {
                              await _userService.createUserWithCredentials(
                                email: email,
                                password: password,
                                role: 'manager',
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

                            await _loadManagers();

                            SnackbarHelper.show(
                              parentContext,
                              message: existing == null
                                  ? 'Manager added successfully'
                                  : 'Manager updated successfully',
                              type: MessageType.success,
                            );
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'email-already-in-use') {
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
        title: const Text('Delete Manager?'),
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
              await _loadManagers();
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
                          'Managers',
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
                        onPressed: () => _showManagerModal(),
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
                          : _managers.isEmpty
                          ? const Center(child: Text('No managers found'))
                          : ListView.separated(
                              itemCount: _managers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final manager = _managers[index];
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
                                            manager.email,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Restaurant: ${_restaurantNameById[manager.restaurantId] ?? "-"}',
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
                                              onPressed: () =>
                                                  _showManagerModal(
                                                    existing: manager,
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
                                                  _confirmDelete(manager),
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
        if (_isLoading && _managers.isNotEmpty)
          const IgnorePointer(child: CustomLoader()),
      ],
    );
  }
}
