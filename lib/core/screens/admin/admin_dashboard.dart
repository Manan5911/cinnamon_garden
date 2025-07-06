import 'dart:ui';

import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/screens/admin/add_booking_page.dart';
import 'package:booking_management_app/core/screens/admin/controllers/booking_filter_controller.dart';
import 'package:booking_management_app/core/screens/admin/kitchen_staff_screen.dart';
import 'package:booking_management_app/core/screens/admin/manager_screen.dart';
import 'package:booking_management_app/core/screens/admin/restaurant_screen.dart';
import 'package:booking_management_app/core/screens/admin/view_booking_screen.dart';
import 'package:booking_management_app/core/screens/auth/login_screen.dart';
import 'package:booking_management_app/core/utils/constants.dart';
import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminDashboard extends StatefulWidget {
  final bool showLoginSuccess;
  const AdminDashboard({super.key, this.showLoginSuccess = false});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _showSidebar = false;
  bool _loginSnackbarShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.showLoginSuccess && !_loginSnackbarShown) {
      _loginSnackbarShown = true; // ✅ ensure only once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.show(
          context,
          message: 'Login successful!',
          type: MessageType.success,
        );
      });
    }
  }

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      BookingHome(
        onToggleSidebar: () {
          setState(() {
            _showSidebar = !_showSidebar;
          });
        },
      ),
      const KitchenStaffScreen(),
      const ManagerScreen(),
      const RestaurantScreen(),
    ];
  }

  Widget _sidebarButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              physics: const BouncingScrollPhysics(),
              children: _screens,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top:
                MediaQuery.of(context).size.height * 0.2, // You can adjust this
            left: _showSidebar ? 0 : -100,
            width: 80,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _showSidebar ? 1 : 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // ✅ Reduces height to fit content
                      children: [
                        _sidebarButton(
                          icon: Icons.close,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          iconColor: Colors.white,
                          tooltip: "Close",
                          onTap: () => setState(() => _showSidebar = false),
                        ),
                        const SizedBox(height: 16),
                        _sidebarButton(
                          icon: Icons.logout,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          iconColor: Colors.redAccent,
                          tooltip: "Logout",
                          onTap: () async {
                            setState(() => _showSidebar = false);
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 13, // ↓ Reduce font size
          unselectedFontSize: 11,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
            );
            setState(() => _currentIndex = index); // update tab UI
          },
          items: [
            _customBarItem(Icons.event_note_outlined, 'Booking', 0),
            _customBarItem(Icons.restaurant_menu_outlined, 'Kitchen', 1),
            _customBarItem(Icons.people_outline, 'Managers', 2),
            _customBarItem(Icons.storefront_outlined, 'Restaurants', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Admin Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              onTap: () async {
                Navigator.pop(context); // close drawer
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),

            // Add more items here as needed
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 20),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _customBarItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = index == _currentIndex;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}

class BookingHome extends ConsumerStatefulWidget {
  final VoidCallback onToggleSidebar;

  const BookingHome({super.key, required this.onToggleSidebar});

  @override
  ConsumerState<BookingHome> createState() => _BookingHomeState();
}

class _BookingHomeState extends ConsumerState<BookingHome> with RouteAware {
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  Map<String, String> _restaurantMap = {};
  Map<String, String> _managerMap = {};
  int _activeFilterCount = 0;

  List<String> _selectedRestaurantIds = [];
  List<String> _selectedManagerIds = [];
  List<String> _selectedTypes = [];
  List<String> _selectedStatuses = [];

  DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return DateTimeRange(start: today, end: tomorrow);
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    refreshBookings();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // 👈 unsubscribe
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  Future<void> refreshBookings() async {
    try {
      final controller = ref.read(bookingFilterControllerProvider.notifier);
      await controller.loadAllBookings();
      if (_selectedRange != null &&
          !(_selectedRange!.start.year == 2000 &&
              _selectedRange!.end.year == 2100)) {
        controller.filterByDateRange(_selectedRange!);
      }
    } finally {}
  }

  @override
  void initState() {
    super.initState();
    _selectedRange = _defaultRange();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(bookingFilterControllerProvider.notifier);

      final restaurantSnap = await FirebaseFirestore.instance
          .collection('restaurants')
          .get();
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        _restaurantMap = {
          for (var doc in restaurantSnap.docs) doc.id: doc['name'] ?? 'Unknown',
        };
        _managerMap = {
          for (var doc in userSnap.docs)
            if (doc['role'] == 'manager') doc.id: doc['email'] ?? 'N/A',
        };
      });

      await controller.loadAllBookings();
      if (_selectedRange != null) {
        controller.filterByDateRange(_selectedRange!);
      }
    });
  }

  Widget _roundedIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(bookingFilterControllerProvider.notifier);
    final bookingsAsync = ref.watch(bookingFilterControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Modern Profile Icon with Modal Sheet
                  GestureDetector(
                    onTap: widget.onToggleSidebar,
                    child: const Icon(
                      Icons.account_circle_outlined,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 12),
                  // Greeting + Date Filter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Admin',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (_selectedRange == null ||
                                  (_selectedRange!.start.year == 2000 &&
                                      _selectedRange!.end.year == 2100))
                              ? 'Showing all bookings'
                              : _selectedRange!.start == _selectedRange!.end
                              ? 'Showing for ${DateFormat('d MMM yyyy').format(_selectedRange!.start)}'
                              : 'From ${DateFormat('d MMM yyyy').format(_selectedRange!.start)} to ${DateFormat('d MMM yyyy').format(_selectedRange!.end)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Add Booking Button (intact)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddBookingPage(),
                        ),
                      );
                      if (result == true && _selectedRange != null) {
                        ref
                            .read(bookingFilterControllerProvider.notifier)
                            .filterByDateRange(_selectedRange!);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshBookings,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatBox(
                                        title: 'Open',
                                        value:
                                            '${bookingsAsync.value?.where((b) => !b.isClosed).length ?? 0}',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildStatBox(
                                        title: 'Closed',
                                        value:
                                            '${bookingsAsync.value?.where((b) => b.isClosed).length ?? 0}',
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Calendar button
                                    _roundedIconButton(
                                      icon: Icons.calendar_month,
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (ctx) =>
                                              SingleChildScrollView(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: MediaQuery.of(
                                                      ctx,
                                                    ).viewInsets.bottom,
                                                  ),
                                                  child: _DateRangeModal(
                                                    initialRange:
                                                        _selectedRange!,
                                                    onApply: (range) {
                                                      setState(
                                                        () => _selectedRange =
                                                            range,
                                                      );
                                                      controller
                                                          .filterByDateRange(
                                                            range,
                                                          );
                                                    },
                                                  ),
                                                ),
                                              ),
                                        );
                                      },
                                    ),

                                    const SizedBox(width: 8),
                                    Stack(
                                      children: [
                                        _roundedIconButton(
                                          icon: Icons.filter_alt_outlined,
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (ctx) => _FilterModal(
                                                restaurantMap: _restaurantMap,
                                                managerMap: _managerMap,
                                                initialRestaurants:
                                                    _selectedRestaurantIds,
                                                initialManagers:
                                                    _selectedManagerIds,
                                                initialTypes: _selectedTypes,
                                                initialStatuses:
                                                    _selectedStatuses,
                                                onApply: (filters) {
                                                  final restaurantIds =
                                                      filters['restaurantIds']
                                                          as List<String>?;
                                                  final managerIds =
                                                      filters['managerIds']
                                                          as List<String>?;
                                                  final types =
                                                      filters['types']
                                                          as List<String>?;
                                                  final statuses =
                                                      filters['statuses']
                                                          as List<String>?;

                                                  setState(() {
                                                    _selectedRestaurantIds =
                                                        restaurantIds ?? [];
                                                    _selectedManagerIds =
                                                        managerIds ?? [];
                                                    _selectedTypes =
                                                        types ?? [];
                                                    _selectedStatuses =
                                                        statuses ?? [];

                                                    // count badge
                                                    int count = 0;
                                                    if (_selectedRestaurantIds
                                                        .isNotEmpty)
                                                      count++;
                                                    if (_selectedManagerIds
                                                        .isNotEmpty)
                                                      count++;
                                                    if (_selectedTypes
                                                        .isNotEmpty)
                                                      count++;
                                                    if (_selectedStatuses
                                                        .isNotEmpty)
                                                      count++;
                                                    _activeFilterCount = count;
                                                  });

                                                  // ✅ Apply filter on visible bookings
                                                  ref
                                                      .read(
                                                        bookingFilterControllerProvider
                                                            .notifier,
                                                      )
                                                      .applyCustomFilters(
                                                        restaurantIds:
                                                            restaurantIds,
                                                        managerIds: managerIds,
                                                        types: types
                                                            ?.map(
                                                              (e) => e
                                                                  .toLowerCase(),
                                                            )
                                                            .toList(),
                                                        statuses: statuses
                                                            ?.map(
                                                              (e) => e
                                                                  .toLowerCase(),
                                                            )
                                                            .toList(),
                                                      );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        if (_activeFilterCount > 0)
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$_activeFilterCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              bookingsAsync.when(
                                loading: () => const SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (e, _) =>
                                    Center(child: Text('Error: $e')),
                                data: (bookings) => bookings.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(
                                          child: Text('No bookings available'),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              0,
                                              20,
                                              12,
                                            ),
                                            child: Text(
                                              'Bookings (${bookings.length})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            itemCount: bookings.length,
                                            itemBuilder: (_, i) =>
                                                _buildBookingTile(
                                                  booking: bookings[i],
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(
                                height: 50,
                              ), // To allow pull padding
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(child: CustomLoader()),
            ),
          ),
      ],
    );
  }

  Widget _buildStatBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTile({required BookingModel booking}) {
    return GestureDetector(
      onTap: () async {
        final restaurantName =
            _restaurantMap[booking.restaurantId] ?? 'Unknown';
        final managerEmail = _managerMap[booking.assignedManagerId] ?? 'N/A';

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewBookingScreen(
              booking: booking,
              restaurantName: restaurantName,
              managerEmail: managerEmail,
            ),
          ),
        );

        if (result == true) {
          refreshBookings(); // ✅ Refresh on return
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.guideName,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('d MMM').format(booking.date)} • ${booking.type.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeModal extends StatefulWidget {
  final DateTimeRange initialRange;
  final void Function(DateTimeRange) onApply;

  const _DateRangeModal({required this.initialRange, required this.onApply});

  @override
  State<_DateRangeModal> createState() => _DateRangeModalState();
}

class _DateRangeModalState extends State<_DateRangeModal> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialRange.start;
    _rangeEnd = widget.initialRange.end;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Date Range',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    rangeStartDay: _rangeStart,
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 12, height: 2.0),
                      weekendStyle: TextStyle(fontSize: 12, height: 2.0),
                    ),
                    rangeEndDay: _rangeEnd,
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        if (_rangeStart != null &&
                            _rangeEnd == null &&
                            selectedDay.isAfter(_rangeStart!)) {
                          _rangeEnd = selectedDay;
                        } else {
                          _rangeStart = selectedDay;
                          _rangeEnd = null;
                        }
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary, // ✅ Blue outline for today
                          width: 2,
                        ),
                      ),
                      todayTextStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      rangeStartTextStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      rangeEndTextStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      rangeHighlightColor: Colors.pink.shade100,
                      rangeStartDecoration: BoxDecoration(
                        color: const Color(0xFFFFE5EC),
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: BoxDecoration(
                        color: const Color(0xFFFFE5EC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    selectedDayPredicate: (day) => false,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_rangeStart != null && _rangeEnd != null)
                            ? () {
                                widget.onApply(
                                  DateTimeRange(
                                    start: _rangeStart!,
                                    end: _rangeEnd!,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (_rangeStart != null && _rangeEnd != null)
                              ? const Color(0xFFFFE5EC)
                              : Colors.grey,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply Filter'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onApply(
                            DateTimeRange(
                              start: DateTime(2000),
                              end: DateTime(2100),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFD0F0C0,
                          ), // light green
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Show All Bookings'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterModal extends StatefulWidget {
  final Map<String, String> restaurantMap;
  final Map<String, String> managerMap;
  final void Function(Map<String, dynamic>) onApply;

  final List<String> initialRestaurants;
  final List<String> initialManagers;
  final List<String> initialTypes;
  final List<String> initialStatuses;

  const _FilterModal({
    required this.restaurantMap,
    required this.managerMap,
    required this.onApply,
    this.initialRestaurants = const [],
    this.initialManagers = const [],
    this.initialTypes = const [],
    this.initialStatuses = const [],
  });

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  List<String> selectedRestaurants = [];
  List<String> selectedManagers = [];
  List<String> selectedTypes = [];
  List<String> selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    selectedRestaurants = [...widget.initialRestaurants];
    selectedManagers = [...widget.initialManagers];
    selectedTypes = [...widget.initialTypes];
    selectedStatuses = [...widget.initialStatuses];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Filter Bookings',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),

              _modalMultiPicker(
                label: 'Restaurant',
                values: selectedRestaurants,
                options: widget.restaurantMap,
                onSelect: (vals) => setState(() => selectedRestaurants = vals),
              ),
              const SizedBox(height: 16),

              _modalMultiPicker(
                label: 'Manager',
                values: selectedManagers,
                options: widget.managerMap,
                onSelect: (vals) => setState(() => selectedManagers = vals),
              ),
              const SizedBox(height: 16),

              _modalMultiPicker(
                label: 'Booking Type',
                values: selectedTypes,
                options: {'dineIn': 'Dine In', 'catering': 'Catering'},
                onSelect: (vals) => setState(() => selectedTypes = vals),
              ),
              const SizedBox(height: 16),

              _modalMultiPicker(
                label: 'Booking Status',
                values: selectedStatuses,
                options: {'open': 'Open', 'closed': 'Closed'},
                onSelect: (vals) => setState(() => selectedStatuses = vals),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply({
                      'restaurantIds': selectedRestaurants,
                      'managerIds': selectedManagers,
                      'types': selectedTypes,
                      'statuses': selectedStatuses,
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE5EC),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalMultiPicker({
    required String label,
    required List<String> values,
    required Map<String, String> options,
    required void Function(List<String>) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final selected = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _MultiSelectBottomPicker(
                title: label,
                options: options,
                selectedValues: values,
              ),
            );
            if (selected != null) onSelect(selected);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    values.isEmpty
                        ? 'Select $label'
                        : values.map((v) => options[v]).join(', '),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () => onSelect([]),
              style: TextButton.styleFrom(
                minimumSize: const Size(40, 28),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }
}

class _MultiSelectBottomPicker extends StatefulWidget {
  final String title;
  final Map<String, String> options;
  final List<String> selectedValues;

  const _MultiSelectBottomPicker({
    required this.title,
    required this.options,
    required this.selectedValues,
  });

  @override
  State<_MultiSelectBottomPicker> createState() =>
      _MultiSelectBottomPickerState();
}

class _MultiSelectBottomPickerState extends State<_MultiSelectBottomPicker> {
  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = [...widget.selectedValues];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select ${widget.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ...widget.options.entries.map(
              (e) => Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.grey,
                      checkboxTheme: CheckboxThemeData(
                        checkColor: MaterialStateProperty.all(
                          Colors.black,
                        ), // white tick
                        fillColor: MaterialStateProperty.all(
                          Colors.white,
                        ), // box color
                      ),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: selected.contains(e.key),
                      title: Text(
                        e.value,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onChanged: (checked) {
                        setState(() {
                          checked!
                              ? selected.add(e.key)
                              : selected.remove(e.key);
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, selected),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: AppColors.pinkThemed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPicker extends StatelessWidget {
  final String title;
  final Map<String, String> options;
  final String? selectedValue;

  const _BottomPicker({
    required this.title,
    required this.options,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'Select $title',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final entry = entries[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: const VisualDensity(vertical: -2),
                  title: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: selectedValue == entry.key
                      ? const Icon(Icons.check, color: Colors.pinkAccent)
                      : null,
                  onTap: () => Navigator.pop(context, entry.key),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
