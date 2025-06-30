import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/models/menu_item_model.dart';
import 'package:booking_management_app/core/services/booking_service.dart';
import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AddBookingPage extends StatefulWidget {
  const AddBookingPage({super.key});

  @override
  State<AddBookingPage> createState() => _AddBookingPageState();
}

class _AddBookingPageState extends State<AddBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _guideNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _ratePerPersonController = TextEditingController();
  final _members = ValueNotifier<int>(1);
  bool _isLoading = false;

  DateTime? _selectedDate;
  bool _isDineIn = true;
  List<MenuItemModel> _dineInItems = [];
  List<MenuItemModel> _cateringItems = [];
  String? _selectedRestaurant;
  String? _assignedManager;

  List<MenuItemModel> get _menuItems =>
      _isDineIn ? _dineInItems : _cateringItems;

  @override
  void dispose() {
    _guideNameController.dispose();
    _mobileController.dispose();
    _companyNameController.dispose();
    _tableNumberController.dispose();
    _ratePerPersonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
          currentList[index] = item; // Editing
        } else {
          currentList.add(item); // New
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
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
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Add Booking",
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
                                "Table Number (optional)",
                              ),
                            _buildTextField(
                              _guideNameController,
                              "Guide Name",
                              required: true,
                            ),
                            _buildPhoneField(),
                            _buildTextField(
                              _companyNameController,
                              "Company Name (optional)",
                            ),
                            _buildCustomDropdown(
                              label: "Restaurant",
                              items: ["Restaurant A", "Restaurant B"],
                              selected: _selectedRestaurant,
                              onChanged: (val) =>
                                  setState(() => _selectedRestaurant = val),
                            ),
                            _buildMembersField(),
                            if (!_isDineIn)
                              _buildTextField(
                                _ratePerPersonController,
                                "Rate per Person (CHF)",
                                type: TextInputType.number,
                                required: !_isDineIn,
                              ),
                            _buildCustomDropdown(
                              label: "Assigned Manager",
                              items: ["Manager 1", "Manager 2"],
                              selected: _assignedManager,
                              onChanged: (val) =>
                                  setState(() => _assignedManager = val),
                            ),
                            const SizedBox(height: 20),
                            _buildAddMenuButton(),
                            const SizedBox(height: 10),
                            if (_menuItems.isNotEmpty) _buildMenuList(),
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
    bool required = false,
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
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white, // 👈 White background for modal
            surfaceTintColor: Colors.white,
          ),
          colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: Colors.white,
            primary: AppColors.primary, // Optional: for pink accent
          ),
        ),
        child: IntlPhoneField(
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
          initialCountryCode: 'IN',
          flagsButtonMargin: const EdgeInsets.only(right: 8),
          onChanged: (phone) => _mobileController.text = phone.completeNumber,
        ),
      ),
    );
  }

  Widget _buildCustomDropdown({
    required String label,
    required List<String> items,
    required String? selected,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showCustomDropdown(items, selected, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selected ?? 'Select $label',
                    style: TextStyle(
                      fontSize: 15,
                      color: selected == null ? Colors.grey : Colors.black,
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

  void _showCustomDropdown(
    List<String> items,
    String? selected,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                onSelected(item);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(item, style: const TextStyle(fontSize: 15)),
              ),
            );
          },
        );
      },
    );
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
          _buildToggleChip(
            "Dine In",
            _isDineIn,
            () => setState(() => _isDineIn = true),
          ),
          _buildToggleChip(
            "Catering",
            !_isDineIn,
            () => setState(() => _isDineIn = false),
          ),
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
              style: TextStyle(
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
      onPressed: () async {
        if (_selectedDate == null) {
          SnackbarHelper.show(
            context,
            message: 'Please select a booking date.',
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

        if (!_isDineIn) {
          final rate = double.tryParse(_ratePerPersonController.text.trim());
          if (rate == null || rate <= 0) {
            SnackbarHelper.show(
              context,
              message: 'Enter valid rate per person.',
              type: MessageType.warning,
            );
            return;
          }
        }

        if (_formKey.currentState?.validate() ?? false) {
          setState(() => _isLoading = true);

          final newBooking = BookingModel(
            id: '',
            date: _selectedDate!,
            type: _isDineIn ? BookingType.dineIn : BookingType.catering,
            tableNumber: _isDineIn ? _tableNumberController.text.trim() : null,
            guideName: _guideNameController.text.trim(),
            guideMobile: _mobileController.text.trim(),
            companyName: _companyNameController.text.trim(),
            restaurantId: _selectedRestaurant!,
            assignedManagerId: _assignedManager!,
            members: _members.value,
            ratePerPerson: !_isDineIn
                ? double.tryParse(_ratePerPersonController.text.trim()) ?? 0.0
                : null,
            menuItems: _menuItems,
            isClosed: false,
          );

          final bookingService = BookingService();
          await bookingService.createBooking(newBooking);

          if (context.mounted) {
            setState(() => _isLoading = false);
            SnackbarHelper.show(
              context,
              message: 'Booking created successfully!',
              type: MessageType.success,
            );
            Navigator.pop(context, true);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Confirm"),
    );
  }
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
