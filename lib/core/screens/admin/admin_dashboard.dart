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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.showLoginSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.show(
          context,
          message: 'Login successful!',
          type: MessageType.success,
        );
      });
    }
  }

  final List<Widget> _screens = [
    const BookingHome(),
    const KitchenStaffScreen(),
    const ManagerScreen(),
    const RestaurantScreen(),
    const Center(child: Text('More')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index; // update selected tab when swiped
            });
          },
          physics: const BouncingScrollPhysics(),
          children: _screens,
        ),
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
            _customBarItem(Icons.settings_outlined, 'More', 4),
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
  const BookingHome({super.key});

  @override
  ConsumerState<BookingHome> createState() => _BookingHomeState();
}

class _BookingHomeState extends ConsumerState<BookingHome> with RouteAware {
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  Map<String, String> _restaurantMap = {};
  Map<String, String> _managerMap = {};

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
      if (_selectedRange != null) {
        print("Called");
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
          for (var doc in userSnap.docs) doc.id: doc['email'] ?? 'N/A',
        };
      });

      await controller.loadAllBookings();
      if (_selectedRange != null) {
        controller.filterByDateRange(_selectedRange!);
      }
    });
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
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return Container(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Drag handle
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Admin Menu Title (not a tile)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    'Admin Menu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Divider
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE0E0E0),
                                ),

                                // Menu item(s)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                  ),
                                  title: const Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
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
                          );
                        },
                      );
                    },
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
                          _selectedRange == null
                              ? 'Overview of all bookings'
                              : _selectedRange!.start == _selectedRange!.end
                              ? 'Showing for ${DateFormat('d MMM yyyy').format(_selectedRange!.start)}'
                              : 'From ${DateFormat('d MMM').format(_selectedRange!.start)} to ${DateFormat('d MMM yyyy').format(_selectedRange!.end)}',
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
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE5EC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.calendar_month,
                                          color: Colors.black,
                                        ),
                                        onPressed: () {
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
                child: ElevatedButton(
                  onPressed: (_rangeStart != null && _rangeEnd != null)
                      ? () {
                          widget.onApply(
                            DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_rangeStart != null && _rangeEnd != null)
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
            ],
          ),
        ),
      ),
    );
  }
}
