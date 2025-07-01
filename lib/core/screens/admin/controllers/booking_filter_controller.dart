// ignore_for_file: avoid_print, unused_local_variable

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
      final today = DateTime(now.year, now.month, now.day);
      final allBookings = await BookingService().fetchBookings();
      final upcoming = allBookings.where((b) {
        final bookingDate = DateTime(b.date.year, b.date.month, b.date.day);
        return bookingDate.isAfter(today) ||
            bookingDate.isAtSameMomentAs(today);
      }).toList();
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
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );

      final allBookings = await BookingService().fetchBookings();
      final filtered = allBookings.where((b) {
        final bookingDate = DateTime(b.date.year, b.date.month, b.date.day);
        return (bookingDate.isAtSameMomentAs(start) ||
            bookingDate.isAtSameMomentAs(end) ||
            (bookingDate.isAfter(start) && bookingDate.isBefore(end)));
      }).toList();

      print('[DEBUG] Filtered bookings count: ${filtered.length}');
      state = AsyncValue.data(filtered);
      selectedRange = range;
      isFiltering = true;
    } catch (e, st) {
      print('[ERROR] Filtering failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  void resetFilter() => loadUpcomingBookings();

  String getHeading() {
    if (!isFiltering || selectedRange == null) return "Total";
    final df = DateFormat('d MMM');
    return "Total from ${df.format(selectedRange!.start)} – ${df.format(selectedRange!.end)}";
  }

  int get count => state.value?.length ?? 0;
}
