import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewBookingScreen extends StatelessWidget {
  final BookingModel booking;
  final String restaurantName;
  final String managerEmail;

  const ViewBookingScreen({
    super.key,
    required this.booking,
    required this.restaurantName,
    required this.managerEmail,
  });

  String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader("Guide Information"),
                      const SizedBox(height: 15),
                      _infoGrid([
                        _infoTile("Name", booking.guideName),
                        _infoTile("Mobile", booking.guideMobile),
                        if (booking.companyName?.isNotEmpty ?? false)
                          _infoTile("Company", booking.companyName!),
                      ]),
                      const SizedBox(height: 15),

                      _sectionHeader("Booking Metadata"),
                      const SizedBox(height: 15),
                      _infoGrid([
                        _infoTile("Date", formatDate(booking.date)),
                        _infoTile("Restaurant", restaurantName),
                        _infoTile("Members", booking.members.toString()),
                        if (booking.tableNumber?.isNotEmpty ?? false)
                          _infoTile("Table", booking.tableNumber!),
                        if (booking.extraDetails?.isNotEmpty ?? false)
                          _infoTile("Notes", booking.extraDetails!),
                        if (booking.assignedManagerId?.isNotEmpty ?? false)
                          _infoTile("Manager", managerEmail),
                        if (booking.type == BookingType.catering &&
                            booking.ratePerPerson != null)
                          _infoTile(
                            "Rate/Person",
                            "${booking.ratePerPerson!.toStringAsFixed(2)} CHF",
                          ),
                      ]),
                      const SizedBox(height: 15),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _chip(
                            "Type: ${booking.type.name}",
                            AppColors.pinkThemed,
                          ),
                          _chip(
                            "Status: ${booking.isClosed ? 'Closed' : 'Open'}",
                            booking.isClosed
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      _sectionHeader("Menu Items"),
                      const SizedBox(height: 15),
                      ...booking.menuItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (booking.type == BookingType.dineIn)
                                Text(
                                  '${item.quantity} × ${item.price?.toStringAsFixed(2)} CHF',
                                ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 30),
                      _actionButton(
                        context: context,
                        label: "Edit Booking",
                        color: booking.isClosed
                            ? Colors.grey.shade300
                            : AppColors.primary,
                        textColor: booking.isClosed
                            ? Colors.black54
                            : Colors.white,
                        onPressed: booking.isClosed ? null : () {},
                      ),
                      const SizedBox(height: 14),
                      _actionButton(
                        context: context,
                        label: booking.isClosed
                            ? "Reopen Booking"
                            : "Close Booking",
                        color: booking.isClosed
                            ? Colors.orange.shade100
                            : Colors.lightBlue.shade100,
                        textColor: Colors.black87,
                        onPressed: () {
                          // TODO: Handle toggle
                        },
                      ),
                      const SizedBox(height: 14),
                      _actionButton(
                        context: context,
                        label: "Generate Bill",
                        color: AppColors.pinkThemed,
                        textColor: Colors.black,
                        onPressed: () {
                          // TODO: Generate bill
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1.2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ),
        const Expanded(child: Divider(thickness: 1.2)),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _infoGrid(List<Widget> tiles) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: tiles,
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
