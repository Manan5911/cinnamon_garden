import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final _bookingCollection = FirebaseFirestore.instance.collection('bookings');

  /// 🔹 Create new booking
  Future<void> createBooking(BookingModel booking) async {
    final docRef = _bookingCollection.doc(); // Generate doc ID
    final bookingWithId = BookingModel(
      id: docRef.id,
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
      menuItems: booking.menuItems,
      ratePerPerson: booking.ratePerPerson,
      isClosed: booking.isClosed,
    );

    await docRef.set(bookingWithId.toMap());
  }

  /// 🔹 Update existing booking
  Future<void> updateBooking(BookingModel booking) async {
    await _bookingCollection.doc(booking.id).update(booking.toMap());
  }

  /// 🔹 Delete a booking
  Future<void> deleteBooking(String bookingId) async {
    await _bookingCollection.doc(bookingId).delete();
  }

  /// 🔹 Get a booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _bookingCollection.doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromMap(doc.data()!, doc.id);
  }

  /// 🔹 Bookings for a specific restaurant
  Future<List<BookingModel>> getBookingsForRestaurant(
    String restaurantId,
  ) async {
    final query = await _bookingCollection
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('date', descending: true)
        .get();

    return query.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// 🔹 Bookings assigned to a manager
  Future<List<BookingModel>> getBookingsAssignedToManager(
    String managerId,
  ) async {
    final query = await _bookingCollection
        .where('assignedManagerId', isEqualTo: managerId)
        .orderBy('date', descending: true)
        .get();

    return query.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// 🔹 Assign manager to booking
  Future<void> assignManagerToBooking(
    String bookingId,
    String managerId,
  ) async {
    await _bookingCollection.doc(bookingId).update({
      'assignedManagerId': managerId,
    });
  }

  /// 🔹 Close a booking
  Future<void> closeBooking(String bookingId) async {
    await _bookingCollection.doc(bookingId).update({'isClosed': true});
  }

  /// 🔹 Fetch all bookings (default sorted by date ascending)
  Future<List<BookingModel>> fetchBookings() async {
    final query = await _bookingCollection
        .orderBy('date', descending: false)
        .get();

    return query.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
