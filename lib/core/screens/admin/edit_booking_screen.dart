// edit_booking_screen.dart
// ✅ Full screen similar to AddBookingPage, but with prefilled values for editing

import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/models/menu_item_model.dart';
import 'package:booking_management_app/core/models/serving_staff_model.dart';
import 'package:booking_management_app/core/services/booking_service.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditBookingPage extends StatefulWidget {
  final BookingModel booking;

  const EditBookingPage({super.key, required this.booking});

  @override
  State<EditBookingPage> createState() => _EditBookingPageState();
}

class _EditBookingPageState extends State<EditBookingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _guideNameController;
  late TextEditingController _mobileController;
  late TextEditingController _companyNameController;
  late TextEditingController _tableNumberController;
  late TextEditingController _ratePerPersonController;
  late TextEditingController _extraDetailsController;
  final _members = ValueNotifier<int>(1);
  bool _isLoading = false;

  DateTime? _selectedDate;
  bool _isDineIn = true;
  List<MenuItemModel> _dineInItems = [];
  List<MenuItemModel> _cateringItems = [];
  List<Map<String, dynamic>> _restaurantOptions = [];
  List<Map<String, dynamic>> _managerOptions = [];
  String? _selectedRestaurant;
  String? _assignedManager;

  List<MenuItemModel> get _menuItems =>
      _isDineIn ? _dineInItems : _cateringItems;

  List<ServingStaffModel>? _servingStaff = [];

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _guideNameController = TextEditingController(text: b.guideName);
    _mobileController = TextEditingController(text: b.guideMobile);
    _companyNameController = TextEditingController(text: b.companyName);
    _tableNumberController = TextEditingController(text: b.tableNumber);
    _ratePerPersonController = TextEditingController(
      text: b.ratePerPerson?.toString(),
    );
    _extraDetailsController = TextEditingController(text: b.extraDetails);
    _members.value = b.members;
    _selectedDate = b.date;
    _isDineIn = b.type == BookingType.dineIn;
    if (_isDineIn) {
      _dineInItems = List.from(b.menuItems);
    } else {
      _cateringItems = List.from(b.menuItems);
    }
    _selectedRestaurant = b.restaurantId;
    _assignedManager = b.assignedManagerId;
    _servingStaff = List.from(b.servingStaff ?? []);

    _fetchDropdownData();
  }

  void _openServingStaffModal({ServingStaffModel? existingStaff, int? index}) {
    final nameController = TextEditingController(
      text: existingStaff?.name ?? '',
    );
    final phoneController = TextEditingController(
      text: existingStaff?.phoneNumber ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Serving Staff",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final newStaff = ServingStaffModel(
                      name: nameController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                    );
                    setState(() {
                      if (index != null) {
                        _servingStaff?[index] = newStaff;
                      } else {
                        _servingStaff?.add(newStaff);
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkThemed,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddStaffButton() {
    return ElevatedButton.icon(
      onPressed: _openServingStaffModal,
      icon: const Icon(Icons.add),
      label: const Text("Add Serving Staff"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pinkThemed,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildServingStaffList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Serving Staff:"),
        const SizedBox(height: 8),
        ..._servingStaff!.map(
          (staff) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("${staff.name} (${staff.phoneNumber})")),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final index = _servingStaff?.indexOf(staff);
                        _openServingStaffModal(
                          existingStaff: staff,
                          index: index,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final index = _servingStaff?.indexOf(staff);
                        if (index != null && index >= 0) {
                          setState(() {
                            _servingStaff!.removeAt(index);
                            _servingStaff = List.from(
                              _servingStaff!,
                            ); // force state update
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _fetchDropdownData() async {
    try {
      final restaurantSnap = await FirebaseFirestore.instance
          .collection('restaurants')
          .get();
      final managerSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .get();

      if (!mounted) return;

      final fetchedManagers = managerSnap.docs
          .map((e) => {'id': e.id, 'email': e['email'] ?? ''})
          .toList();

      setState(() {
        _restaurantOptions = restaurantSnap.docs
            .map(
              (e) => {
                'id': e.id,
                'name': e['name'] ?? '',
                'address': e['address'] ?? '',
              },
            )
            .toList();

        _managerOptions = fetchedManagers;

        // Check if assignedManager still exists in the fetched list
        final exists = fetchedManagers.any((m) => m['id'] == _assignedManager);
        if (!exists) _assignedManager = null;
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        message: 'Error loading dropdowns',
        type: MessageType.error,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openMenuModal({MenuItemModel? existingItem, int? index}) async {
    final currentList = _menuItems;

    final item = await showModalBottomSheet<MenuItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _AddMenuItemModal(isCatering: !_isDineIn, initialItem: existingItem),
    );

    if (item != null) {
      final isDuplicate = currentList.any(
        (e) =>
            e.name.trim().toLowerCase() == item.name.trim().toLowerCase() &&
            (index == null || currentList.indexOf(e) != index),
      );

      if (isDuplicate) {
        SnackbarHelper.show(
          context,
          message: 'Item already exists in the menu.',
          type: MessageType.warning,
        );
        return;
      }

      setState(() {
        if (index != null) {
          currentList[index] = item;
        } else {
          currentList.add(item);
        }
      });
    }
  }

  Future<void> _saveBooking() async {
    if (_selectedDate == null) {
      SnackbarHelper.show(
        context,
        message: 'Please select a booking date.',
        type: MessageType.warning,
      );
      return;
    }

    if (_guideNameController.text.trim().isEmpty) {
      SnackbarHelper.show(
        context,
        message: 'Please enter guide name',
        type: MessageType.warning,
      );
      return;
    }

    if (_mobileController.text.trim().isEmpty) {
      SnackbarHelper.show(
        context,
        message: 'Please enter mobile number',
        type: MessageType.warning,
      );
      return;
    }

    if (_menuItems.isEmpty) {
      SnackbarHelper.show(
        context,
        message: 'Please add at least one menu item.',
        type: MessageType.warning,
      );
      return;
    }

    if (_selectedRestaurant == null) {
      SnackbarHelper.show(
        context,
        message: 'Please select a restaurant.',
        type: MessageType.warning,
      );
      return;
    }

    if (_assignedManager == null) {
      SnackbarHelper.show(
        context,
        message: 'Please assign a manager.',
        type: MessageType.warning,
      );
      return;
    }

    if (!_isDineIn &&
        (_ratePerPersonController.text.trim().isEmpty ||
            double.tryParse(_ratePerPersonController.text.trim()) == null)) {
      SnackbarHelper.show(
        context,
        message: 'Enter valid rate per person',
        type: MessageType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final updated = widget.booking.copyWith(
      date: _selectedDate,
      type: _isDineIn ? BookingType.dineIn : BookingType.catering,
      guideName: _guideNameController.text.trim(),
      guideMobile: _mobileController.text.trim(),
      companyName: _companyNameController.text.trim(),
      restaurantId: _selectedRestaurant,
      assignedManagerId: _assignedManager,
      members: _members.value,
      extraDetails: _extraDetailsController.text.trim(),
      menuItems: List.from(_menuItems),
      // Only include relevant fields:
      tableNumber: _isDineIn ? _tableNumberController.text.trim() : null,
      ratePerPerson: !_isDineIn
          ? double.tryParse(_ratePerPersonController.text.trim())
          : null,
      servingStaff: _servingStaff ?? [],
    );

    final bookingService = BookingService();
    await bookingService.updateBooking(updated);

    if (mounted) {
      setState(() => _isLoading = false);
      SnackbarHelper.show(
        context,
        message: 'Booking updated successfully!',
        type: MessageType.success,
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _guideNameController.dispose();
    _mobileController.dispose();
    _companyNameController.dispose();
    _tableNumberController.dispose();
    _ratePerPersonController.dispose();
    _extraDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.secondary,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 15, 0, 15),
                    color: AppColors.secondary,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Edit Booking",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            _buildDateField(),
                            const SizedBox(height: 8),
                            _buildToggleSelector(),
                            if (_isDineIn)
                              _buildTextField(
                                _tableNumberController,
                                "Section/Location (optional)",
                              ),
                            _buildTextField(_guideNameController, "Guide Name"),
                            _buildPhoneField(),
                            _buildTextField(
                              _companyNameController,
                              "Company Name (optional)",
                            ),
                            _buildExtraDetailsField(),
                            _buildDropdownWithMap(
                              "Restaurant",
                              _restaurantOptions,
                              _selectedRestaurant,
                              (id) => setState(() => _selectedRestaurant = id),
                            ),
                            _buildMembersField(),
                            if (!_isDineIn)
                              _buildTextField(
                                _ratePerPersonController,
                                "Rate per Person (CHF)",
                                type: TextInputType.number,
                              ),
                            _buildDropdownWithMap(
                              "Assigned Manager",
                              _managerOptions,
                              _assignedManager,
                              (id) => setState(() => _assignedManager = id),
                            ),
                            const SizedBox(height: 20),
                            if (_menuItems.isNotEmpty) _buildMenuList(),
                            const SizedBox(height: 10),
                            _buildAddMenuButton(),
                            const SizedBox(height: 15),
                            if (_servingStaff!.isNotEmpty)
                              _buildServingStaffList(),
                            const SizedBox(height: 12),
                            _buildAddStaffButton(),
                            const SizedBox(height: 30),
                            _buildConfirmButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const CustomLoader(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: _mobileController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Guide Mobile Number',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildExtraDetailsField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: _extraDetailsController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: "Extra Details (optional)",
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildDropdownWithMap(
    String label,
    List<Map<String, dynamic>> options,
    String? selectedId,
    Function(String) onChanged,
  ) {
    final selectedItem = options.firstWhere(
      (opt) => opt['id'] == selectedId,
      orElse: () => {},
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              _showDropdownBottomSheet(
                label: label,
                options: options,
                onSelected: onChanged,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedItem.isEmpty
                          ? 'Select $label'
                          : (label == 'Restaurant'
                                ? "${selectedItem['name']} (${selectedItem['address']})"
                                : selectedItem['email'] ?? ''),
                      style: TextStyle(
                        fontSize: 15,
                        color: selectedItem.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDropdownBottomSheet({
    required String label,
    required List<Map<String, dynamic>> options,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: options.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final item = options[index];
            final title = label == 'Restaurant'
                ? item['name'] ?? 'Unnamed'
                : item['email'] ?? 'Unnamed';
            final subtitle = label == 'Restaurant'
                ? item['address'] ?? 'No address'
                : null;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                onSelected(item['id']);
                if (label == 'Restaurant') {
                  _filterManagersByRestaurant(item['id']);
                }
              },
            );
          },
        );
      },
    );
  }

  void _filterManagersByRestaurant(String restaurantId) async {
    try {
      final managerSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      setState(() {
        _managerOptions = managerSnap.docs
            .map((e) => {'id': e.id, 'email': e['email'] ?? ''})
            .toList();
        _assignedManager = null; // Reset manager selection
      });
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: 'Error loading managers',
        type: MessageType.error,
      );
    }
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Booking Date"),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _selectedDate == null
                  ? 'Select Date'
                  : DateFormat('d MMM yyyy').format(_selectedDate!),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleChip("Dine In", _isDineIn, () {
            setState(() {
              _isDineIn = true;
              _ratePerPersonController.clear(); // clear rate
            });
          }),
          _buildToggleChip("Catering", !_isDineIn, () {
            setState(() {
              _isDineIn = false;
              _tableNumberController.clear(); // clear table number
            });
          }),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.pinkThemed : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text("Members:"),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCounterButton("-", () {
                  _members.value = (_members.value - 1).clamp(1, 100);
                }),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: Colors.white,
                  child: ValueListenableBuilder(
                    valueListenable: _members,
                    builder: (_, val, __) =>
                        Text('$val', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                _buildCounterButton("+", () {
                  _members.value = (_members.value + 1).clamp(1, 100);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.pinkThemed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildAddMenuButton() {
    return ElevatedButton.icon(
      onPressed: _openMenuModal,
      icon: const Icon(Icons.add),
      label: const Text("Add Menu Item"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pinkThemed,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMenuList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Menu Items:"),
        const SizedBox(height: 8),
        ..._menuItems.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name + (_isDineIn ? ' x${item.quantity}' : ''),
                  ),
                ),
                if (_isDineIn) Text('${item.price?.toStringAsFixed(2)} CHF'),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final index = _menuItems.indexOf(item);
                        _openMenuModal(existingItem: item, index: index);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _menuItems.remove(item));
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _saveBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Save Changes"),
    );
  }

  // The _buildX helper methods follow the same as AddBookingPage
  // You can copy or modularize them based on your existing file.
}

class _AddMenuItemModal extends StatefulWidget {
  final bool isCatering;
  final MenuItemModel? initialItem;

  const _AddMenuItemModal({this.isCatering = false, this.initialItem});

  @override
  State<_AddMenuItemModal> createState() => _AddMenuItemModalState();
}

class _AddMenuItemModalState extends State<_AddMenuItemModal> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _quantityController.text = item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Text(
              'Add Menu Item',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Item Name",
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
          if (!widget.isCatering) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Price (CHF)",
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Quantity", style: TextStyle(fontSize: 15)),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        splashRadius: 20,
                        onPressed: () {
                          final current =
                              int.tryParse(_quantityController.text) ?? 1;
                          final updated = (current - 1).clamp(1, 99);
                          setState(() => _quantityController.text = '$updated');
                        },
                      ),
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            _quantityController.text,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        splashRadius: 20,
                        onPressed: () {
                          final current =
                              int.tryParse(_quantityController.text) ?? 1;
                          final updated = (current + 1).clamp(1, 99);
                          setState(() => _quantityController.text = '$updated');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final price = widget.isCatering
                    ? 0.0
                    : double.tryParse(_priceController.text.trim()) ?? 0.0;
                final quantity = widget.isCatering
                    ? 1
                    : int.tryParse(_quantityController.text.trim()) ?? 1;

                if (name.isNotEmpty) {
                  Navigator.pop(
                    context,
                    MenuItemModel(name: name, price: price, quantity: quantity),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkThemed,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Add Item"),
            ),
          ),
        ],
      ),
    );
  }
}
