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
  List<BookingModel> _allBookings = [];
  List<String>? _selectedRestaurantIds;
  List<String>? _selectedManagerIds;
  List<String>? _selectedTypes;
  List<String>? _selectedStatuses;

  BookingFilterController(this.ref) : super(const AsyncValue.loading()) {
    // loadAllBookings();
  }

  DateTimeRange? selectedRange;
  bool isFiltering = false;

  Future<void> loadAllBookings() async {
    state = const AsyncValue.loading();
    try {
      _allBookings = await BookingService().fetchBookings();
      state = AsyncValue.data(_allBookings);
      selectedRange = null;
      isFiltering = false;
    } catch (e, st) {
      print('[ERROR] Failed to fetch all bookings: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadUpcomingBookings() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _allBookings = await BookingService().fetchBookings();

      final upcoming = _allBookings.where((b) {
        final bookingDate = DateTime(b.date.year, b.date.month, b.date.day);
        return bookingDate.isAfter(today) ||
            bookingDate.isAtSameMomentAs(today);
      }).toList();

      state = AsyncValue.data(upcoming);
      selectedRange = null;
      isFiltering = false;
    } catch (e, st) {
      print('[ERROR] Failed to fetch upcoming bookings: $e');
      state = AsyncValue.error(e, st);
    }
  }

  void filterByDateRange(DateTimeRange range) {
    selectedRange = range;
    isFiltering = true;
    _applyCombinedFilters();
  }

  void applyCustomFilters({
    List<String>? restaurantIds,
    List<String>? managerIds,
    List<String>? types,
    List<String>? statuses,
  }) {
    _selectedRestaurantIds = restaurantIds;
    _selectedManagerIds = managerIds;
    _selectedTypes = types;
    _selectedStatuses = statuses;
    _applyCombinedFilters();
  }

  void _applyCombinedFilters() {
    if (_allBookings.isEmpty) return;

    final start = selectedRange != null
        ? DateTime(
            selectedRange!.start.year,
            selectedRange!.start.month,
            selectedRange!.start.day,
          )
        : null;

    final end = selectedRange != null
        ? DateTime(
            selectedRange!.end.year,
            selectedRange!.end.month,
            selectedRange!.end.day,
            23,
            59,
            59,
          )
        : null;

    print(_selectedTypes);
    print(_selectedStatuses);
    final normalizedTypes = _selectedTypes?.map((type) {
      switch (type.toLowerCase()) {
        case 'dinein':
          return 'dineIn';
        case 'catering':
          return 'catering';
        default:
          return type;
      }
    }).toList();

    final filtered = _allBookings.where((booking) {
      final bookingDate = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
      );

      final matchesDate =
          selectedRange == null ||
          bookingDate.isAtSameMomentAs(start!) ||
          bookingDate.isAtSameMomentAs(end!) ||
          (bookingDate.isAfter(start!) && bookingDate.isBefore(end!));

      final matchesRestaurant =
          _selectedRestaurantIds == null ||
          _selectedRestaurantIds!.isEmpty ||
          _selectedRestaurantIds!.contains(booking.restaurantId);

      final matchesManager =
          _selectedManagerIds == null ||
          _selectedManagerIds!.isEmpty ||
          _selectedManagerIds!.contains(booking.assignedManagerId);

      final matchesType =
          normalizedTypes == null ||
          normalizedTypes.isEmpty ||
          normalizedTypes.contains(booking.type.name);

      final matchesStatus =
          _selectedStatuses == null ||
          _selectedStatuses!.isEmpty ||
          _selectedStatuses!.contains(booking.isClosed ? 'closed' : 'open');

      return matchesDate &&
          matchesRestaurant &&
          matchesManager &&
          matchesType &&
          matchesStatus;
    }).toList();

    state = AsyncValue.data(filtered);
  }

  void resetFilters() {
    selectedRange = null;
    isFiltering = false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = _allBookings.where((b) {
      final bookingDate = DateTime(b.date.year, b.date.month, b.date.day);
      return bookingDate.isAfter(today) || bookingDate.isAtSameMomentAs(today);
    }).toList();

    state = AsyncValue.data(upcoming);
  }

  String getHeading() {
    if (!isFiltering || selectedRange == null) return "Total";
    final df = DateFormat('d MMM');
    return "Total from ${df.format(selectedRange!.start)} – ${df.format(selectedRange!.end)}";
  }

  int get count => state.value?.length ?? 0;
}
