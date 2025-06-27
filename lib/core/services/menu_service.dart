import '../models/booking_model.dart';
import '../models/menu_item_model.dart';
import 'booking_service.dart';

class MenuService {
  final BookingService _bookingService = BookingService();

  /// 🔹 Bulk add/replace menu for a booking
  Future<void> bulkAddMenu({
    required String bookingId,
    required List<MenuItemModel> newMenu,
    double? ratePerPerson, // For catering
  }) async {
    final booking = await _bookingService.getBookingById(bookingId);
    if (booking == null) throw Exception('Booking not found');

    final updatedBooking = BookingModel(
      id: booking.id,
      type: booking.type,
      date: booking.date,
      members: booking.members,
      restaurantId: booking.restaurantId,
      tableNumber: booking.tableNumber,
      extraDetails: booking.extraDetails,
      guideName: booking.guideName,
      guideMobile: booking.guideMobile,
      companyName: booking.companyName,
      assignedManagerId: booking.assignedManagerId,
      menuItems: newMenu,
      ratePerPerson: ratePerPerson,
      isClosed: booking.isClosed,
    );

    await _bookingService.updateBooking(updatedBooking);
  }

  /// 🔹 Get menu for a booking
  Future<List<MenuItemModel>> getMenuForBooking(String bookingId) async {
    final booking = await _bookingService.getBookingById(bookingId);
    if (booking == null) throw Exception('Booking not found');
    return booking.menuItems;
  }
}
