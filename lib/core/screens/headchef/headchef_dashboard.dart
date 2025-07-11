import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/screens/admin/controllers/booking_filter_controller.dart';
import 'package:booking_management_app/core/screens/auth/login_screen.dart';
import 'package:booking_management_app/core/screens/headchef/view_booking_screen.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:booking_management_app/core/utils/constants.dart';
import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HeadChefDashboard extends ConsumerStatefulWidget {
  final bool showLoginSuccess;
  const HeadChefDashboard({super.key, this.showLoginSuccess = false});

  @override
  ConsumerState<HeadChefDashboard> createState() => _HeadChefDashboardState();
}

class _HeadChefDashboardState extends ConsumerState<HeadChefDashboard>
    with RouteAware {
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  bool _loginSnackbarShown = false;

  Map<String, String> _restaurantMap = {};
  Map<String, String> _managerMap = {};

  DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return DateTimeRange(start: today, end: tomorrow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
    if (widget.showLoginSuccess && !_loginSnackbarShown) {
      _loginSnackbarShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.show(
          context,
          message: 'Login successful!',
          type: MessageType.success,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _selectedRange = _defaultRange();
      final controller = ref.read(bookingFilterControllerProvider.notifier);

      // Load all bookings (no restaurant filtering for headchef)
      await controller.loadAllBookings();
      controller.filterByDateRange(_selectedRange!);

      // Load restaurant and manager map
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
    });
  }

  Future<void> refreshBookings() async {
    final controller = ref.read(bookingFilterControllerProvider.notifier);
    await controller.loadAllBookings();
    if (_selectedRange != null) {
      controller.filterByDateRange(_selectedRange!);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingFilterControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.secondary,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.pinkThemed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          final result = await showModalBottomSheet<DateTimeRange>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => _DateRangeModal(
              initialRange: _selectedRange!,
              onApply: (range) {
                setState(() => _selectedRange = range);
                ref
                    .read(bookingFilterControllerProvider.notifier)
                    .filterByDateRange(range);
              },
            ),
          );
        },
        child: const Icon(Icons.calendar_month, color: Colors.black),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, Head Chef',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            _selectedRange == null
                                ? const SizedBox.shrink()
                                : Text(
                                    (_selectedRange!.start.year == 2000 &&
                                            _selectedRange!.end.year == 2100)
                                        ? 'Showing all bookings'
                                        : _selectedRange!.start ==
                                              _selectedRange!.end
                                        ? 'Showing for ${DateFormat('d MMM yyyy').format(_selectedRange!.start)}'
                                        : 'From ${DateFormat('d MMM yyyy').format(_selectedRange!.start)} to ${DateFormat('d MMM yyyy').format(_selectedRange!.end)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.white70),
                                  ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          onPressed: () async {
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refreshBookings,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: bookingsAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(child: Text('Error: $e')),
                              data: (bookings) {
                                final openBookings = bookings
                                    .where((b) => !b.isClosed)
                                    .toList();

                                return openBookings.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No open bookings available',
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(20),
                                        itemCount: openBookings.length,
                                        itemBuilder: (context, index) =>
                                            _buildBookingTile(
                                              openBookings[index],
                                            ),
                                      );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading) const Center(child: CustomLoader()),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTile(BookingModel booking) {
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
          refreshBookings();
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
                      weekdayStyle: TextStyle(fontSize: 12),
                      weekendStyle: TextStyle(fontSize: 12),
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
