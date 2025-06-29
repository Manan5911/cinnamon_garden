import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/services/booking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final bookingFilterControllerProvider =
    StateNotifierProvider<
      BookingFilterController,
      AsyncValue<List<BookingModel>>
    >((ref) => BookingFilterController(ref));

class BookingFilterController
    extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final Ref ref;
  BookingFilterController(this.ref) : super(const AsyncValue.loading()) {
    loadUpcomingBookings();
  }

  DateTimeRange? selectedRange;
  bool isFiltering = false;

  Future<void> loadUpcomingBookings() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final allBookings = await BookingService().fetchBookings();
      final upcoming = allBookings.where((b) => b.date.isAfter(now)).toList();
      print('[DEBUG] Fetched ${upcoming.length} upcoming bookings');
      state = AsyncValue.data(upcoming);
      selectedRange = null;
      isFiltering = false;
    } catch (e, st) {
      print('[ERROR] Failed to fetch upcoming bookings: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> filterByDateRange(DateTimeRange range) async {
    state = const AsyncValue.loading();
    try {
      final allBookings = await BookingService().fetchBookings();
      final filtered = allBookings.where((b) {
        return b.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
            b.date.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();
      print('[DEBUG] Fetched ${filtered.length} filtered bookings');
      state = AsyncValue.data(filtered);
      selectedRange = range;
      isFiltering = true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void resetFilter() => loadUpcomingBookings();

  String getHeading() {
    if (!isFiltering || selectedRange == null) return "Upcoming Bookings";
    final df = DateFormat('d MMM');
    return "Bookings from ${df.format(selectedRange!.start)} – ${df.format(selectedRange!.end)}";
  }

  int get count => state.value?.length ?? 0;
}
