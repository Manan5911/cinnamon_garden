import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:booking_management_app/core/models/restaurant_model.dart';
import 'package:booking_management_app/core/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final data = await _restaurantService.getAllRestaurants();
    if (mounted) {
      setState(() {
        _restaurants = data;
        _isLoading = false;
      });
    }
  }

  void _showRestaurantModal({Restaurant? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final parentContext = context;

    String? nameError;
    String? addressError;

    showModalBottomSheet(
      context: parentContext,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Add Restaurant' : 'Edit Restaurant',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restaurant Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Restaurant Name',
                        errorText: nameError,
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

                    // Address
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        errorText: addressError,
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

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final address = addressController.text.trim();

                          setModalState(() {
                            nameError = name.isEmpty
                                ? "Name is required"
                                : null;
                            addressError = address.isEmpty
                                ? "Address is required"
                                : null;
                          });

                          if (nameError != null || addressError != null) return;

                          Navigator.of(modalContext).pop();

                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );
                          if (!mounted) return;

                          setState(() => _isLoading = true);

                          final restaurant = Restaurant(
                            id: existing?.id ?? const Uuid().v4(),
                            name: name,
                            address: address,
                          );

                          try {
                            if (existing == null) {
                              await _restaurantService.createRestaurant(
                                restaurant,
                              );
                            } else {
                              await _restaurantService.updateRestaurant(
                                restaurant,
                              );
                            }

                            if (!mounted) return;
                            await _loadRestaurants();

                            if (!mounted) return;
                            SnackbarHelper.show(
                              parentContext,
                              message: existing == null
                                  ? 'Restaurant added successfully'
                                  : 'Restaurant updated successfully',
                              type: MessageType.success,
                            );
                          } catch (_) {
                            // handle error if needed
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
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

  void _confirmDelete(Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Confirm Delete',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to delete "${restaurant.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;

              setState(() => _isLoading = true);

              try {
                await _restaurantService.deleteRestaurant(restaurant.id);
                if (!mounted) return;

                await _loadRestaurants();

                if (!mounted) return;
                SnackbarHelper.show(
                  context,
                  message: 'Restaurant deleted',
                  type: MessageType.success,
                );
              } catch (_) {
                // Show error if needed
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRestaurants() async {
    if (!mounted) return;
    setState(() => _isLoading = true); // ✅ Show custom loader

    final data = await _restaurantService.getAllRestaurants();
    if (!mounted) return;

    setState(() {
      _restaurants = data;
      _isLoading = false; // ✅ Hide custom loader
    });
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
                          'My Restaurants',
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
                        onPressed: () => _showRestaurantModal(),
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
                          : _restaurants.isEmpty
                          ? const Center(child: Text('No restaurants found'))
                          : RefreshIndicator(
                              onRefresh: () async {
                                setState(() => _isLoading = true);
                                await _loadRestaurants();
                              },
                              child: ListView.separated(
                                itemCount: _restaurants.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final r = _restaurants[index];
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                                              r.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: AppColors.text,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              r.address,
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
                                                    _showRestaurantModal(
                                                      existing: r,
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
                                                    _confirmDelete(r),
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
                ),
              ],
            ),
          ),
        ),
        if (_isLoading && _restaurants.isNotEmpty)
          const IgnorePointer(child: CustomLoader()),
      ],
    );
  }
}
