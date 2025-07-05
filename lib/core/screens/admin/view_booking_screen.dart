import 'package:booking_management_app/core/models/booking_model.dart';
import 'package:booking_management_app/core/screens/admin/edit_booking_screen.dart';
import 'package:booking_management_app/core/services/booking_service.dart';
import 'package:booking_management_app/core/utils/snackbar_helper.dart';
import 'package:booking_management_app/core/utils/custom_loader.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewBookingScreen extends StatefulWidget {
  final BookingModel booking;
  final String restaurantName;
  final String managerEmail;

  const ViewBookingScreen({
    super.key,
    required this.booking,
    required this.restaurantName,
    required this.managerEmail,
  });

  @override
  State<ViewBookingScreen> createState() => _ViewBookingScreenState();
}

class _ViewBookingScreenState extends State<ViewBookingScreen> {
  bool _isLoading = false;

  String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _formatBookingType(BookingType type) {
    switch (type) {
      case BookingType.catering:
        return "Catering";
      case BookingType.dineIn:
        return "Dine In";
      default:
        return type.name; // fallback just in case
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
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
                          fontSize: 20,
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader("Guide Information"),
                          const SizedBox(height: 15),
                          _infoGrid([
                            _infoTile("Name", widget.booking.guideName),
                            _infoTile("Mobile", widget.booking.guideMobile),
                            if (widget.booking.companyName?.isNotEmpty ?? false)
                              _infoTile("Company", widget.booking.companyName!),
                          ]),
                          const SizedBox(height: 15),

                          _sectionHeader("Booking Metadata"),
                          const SizedBox(height: 15),
                          _infoGrid([
                            _infoTile("Date", formatDate(widget.booking.date)),
                            _infoTile("Restaurant", widget.restaurantName),
                            _infoTile(
                              "Members",
                              widget.booking.members.toString(),
                            ),
                            if (widget.booking.tableNumber?.isNotEmpty ?? false)
                              _infoTile("Table", widget.booking.tableNumber!),
                            if (widget.booking.assignedManagerId?.isNotEmpty ??
                                false)
                              _infoTile("Manager", widget.managerEmail),
                            if (widget.booking.type == BookingType.catering &&
                                widget.booking.ratePerPerson != null)
                              _infoTile(
                                "Rate/Person",
                                "${widget.booking.ratePerPerson!.toStringAsFixed(2)} CHF",
                              ),
                          ]),

                          const SizedBox(height: 15),

                          if (widget.booking.extraDetails?.isNotEmpty ?? false)
                            _buildNotesTile(widget.booking.extraDetails!),

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _chip(
                                "Type: ${_formatBookingType(widget.booking.type)}",
                                AppColors.pinkThemed,
                              ),
                              _chip(
                                "Status: ${widget.booking.isClosed ? 'Closed' : 'Open'}",
                                widget.booking.isClosed
                                    ? Colors.lightBlue.shade100
                                    : Colors.green.shade100,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          _sectionHeader("Menu Items"),
                          const SizedBox(height: 15),
                          ...widget.booking.menuItems.map((item) {
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (widget.booking.type == BookingType.dineIn)
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
                            color: widget.booking.isClosed
                                ? Colors.grey.shade300
                                : AppColors.primary,
                            textColor: widget.booking.isClosed
                                ? Colors.black54
                                : Colors.white,
                            onPressed: () async {
                              if (widget.booking.isClosed) {
                                SnackbarHelper.show(
                                  context,
                                  message: "Booking must be reopened to edit.",
                                  type: MessageType.warning,
                                );
                                return;
                              }

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditBookingPage(booking: widget.booking),
                                ),
                              );

                              if (result == true) {
                                Navigator.pop(
                                  context,
                                  true,
                                ); // return to refresh
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _actionButton(
                            context: context,
                            label: widget.booking.isClosed
                                ? "Reopen Booking"
                                : "Close Booking",
                            color: widget.booking.isClosed
                                ? Colors.orange.shade100
                                : Colors.lightBlue.shade100,
                            textColor: Colors.black87,
                            onPressed: () async {
                              setState(() => _isLoading = true);

                              final updated = widget.booking.copyWith(
                                isClosed: !widget.booking.isClosed,
                              );

                              try {
                                await BookingService().updateBooking(updated);
                                SnackbarHelper.show(
                                  context,
                                  message:
                                      'Booking ${updated.isClosed ? "closed" : "reopened"} successfully',
                                  type: MessageType.success,
                                );
                                Navigator.pop(context, true);
                              } catch (e) {
                                SnackbarHelper.show(
                                  context,
                                  message: 'Failed to update status.',
                                  type: MessageType.error,
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _actionButton(
                            context: context,
                            label: "Delete Booking",
                            color: Colors.red.shade400,
                            textColor: Colors.black,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Confirm Deletion"),
                                  backgroundColor: Colors.white,
                                  content: const Text(
                                    "Are you sure you want to delete this booking?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context); // close dialog
                                        setState(() => _isLoading = true);

                                        try {
                                          await BookingService().deleteBooking(
                                            widget.booking.id,
                                          );
                                          SnackbarHelper.show(
                                            context,
                                            message: "Booking deleted",
                                            type: MessageType.success,
                                          );
                                          Navigator.pop(
                                            context,
                                            true,
                                          ); // go back
                                        } catch (e) {
                                          SnackbarHelper.show(
                                            context,
                                            message: "Failed to delete booking",
                                            type: MessageType.error,
                                          );
                                        } finally {
                                          if (mounted)
                                            setState(() => _isLoading = false);
                                        }
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );
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
          if (_isLoading) const CustomLoader(),
        ],
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
            style: const TextStyle(
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

  Widget _buildNotesTile(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXTRA DETAILS',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            notes,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.start,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, {Key? key}) {
    return Container(
      key: key,
      child: Column(
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
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(List<Widget> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tiles.map((tile) {
            if (tile.key == const Key('notes')) {
              return SizedBox(width: constraints.maxWidth, child: tile);
            }
            return SizedBox(width: tileWidth, child: tile);
          }).toList(),
        );
      },
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
