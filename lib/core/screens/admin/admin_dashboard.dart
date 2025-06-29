import 'package:booking_management_app/core/screens/admin/controllers/booking_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BookingHome(),
    const Center(child: Text('Kitchen')),
    const Center(child: Text('Managers')),
    const Center(child: Text('More')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _screens[_currentIndex],
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
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _customBarItem(Icons.event_note_outlined, 'Booking', 0),
            _customBarItem(Icons.restaurant_menu_outlined, 'Kitchen', 1),
            _customBarItem(Icons.people_outline, 'Managers', 2),
            _customBarItem(Icons.settings_outlined, 'More', 3),
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

class _BookingHomeState extends ConsumerState<BookingHome> {
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedRange = DateTimeRange(start: today, end: today);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bookingFilterControllerProvider.notifier)
          .filterByDateRange(_selectedRange!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(bookingFilterControllerProvider.notifier);
    final bookingsAsync = ref.watch(bookingFilterControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, Admin',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedRange == null
                          ? 'Overview of all bookings'
                          : _selectedRange!.start == _selectedRange!.end
                          ? 'Showing for ${DateFormat('d MMM yyyy').format(_selectedRange!.start)}'
                          : 'From ${DateFormat('d MMM').format(_selectedRange!.start)} to ${DateFormat('d MMM yyyy').format(_selectedRange!.end)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              // 👈 Entire panel scrollable
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
                            border: Border.all(color: AppColors.border),
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
                                builder: (_) => _DateRangeModal(
                                  initialRange: _selectedRange!,
                                  onApply: (range) {
                                    setState(() => _selectedRange = range);
                                    controller.filterByDateRange(range);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  bookingsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (bookings) => bookings.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No bookings available')),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: bookings.length,
                            itemBuilder: (_, i) => _buildBookingTile(
                              name: bookings[i].guideName,
                              date: DateFormat(
                                'd MMM',
                              ).format(bookings[i].date),
                              type: bookings[i].type.name,
                            ),
                          ),
                  ),
                ],
              ),
            ),
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

  Widget _buildBookingTile({
    required String name,
    required String date,
    required String type,
  }) {
    return Container(
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
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $type',
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
                      todayDecoration: const BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      rangeHighlightColor: Colors.pink.shade100,
                      rangeStartDecoration: BoxDecoration(
                        color: Colors.pink.shade400,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: BoxDecoration(
                        color: Colors.pink.shade400,
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
                        ? Colors.pink.shade400
                        : Colors.grey,
                    foregroundColor: Colors.white,
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
