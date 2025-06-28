import 'package:flutter/material.dart';
import 'package:booking_management_app/core/theme/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BookingHome(),
    Center(child: Text('Kitchen')),
    Center(child: Text('Managers')),
    Center(child: Text('More')),
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
              color: Colors.black.withOpacity(0.05), // light shadow
              blurRadius: 6,
              offset: const Offset(0, -1), // shadow appears above the navbar
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white, // match the container
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0, // shadow handled by container
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

class BookingHome extends StatelessWidget {
  const BookingHome({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Greeting
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Admin',
                style: textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Overview of all bookings',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        /// White panel with scrollable content
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Stat Boxes
                  Row(
                    children: [
                      _buildStatBox(title: 'Total', value: '140'),
                      const SizedBox(width: 8),
                      _buildStatBox(title: 'Open', value: '120'),
                      const SizedBox(width: 8),
                      _buildStatBox(title: 'Closed', value: '20'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Recent Bookings', style: textTheme.headlineSmall),
                  const SizedBox(height: 12),

                  /// Booking list
                  ListView.builder(
                    itemCount: _recentBookingData.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final booking = _recentBookingData[index];
                      return _buildBookingTile(
                        name: booking['name']!,
                        date: booking['date']!,
                        type: booking['type']!,
                      );
                    },
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
    return Expanded(
      child: Container(
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

/// ✅ Mock booking data
final List<Map<String, String>> _recentBookingData = [
  {
    'name': 'Grilmom, Giu Oliner',
    'date': '5.26 Apr',
    'type': 'Table + Catering',
  },
  {'name': 'Guicomart, Clare', 'date': '21 Apr', 'type': 'Dine 12 + Catering'},
  {'name': 'Might- Buestrone', 'date': '21 Apr', 'type': 'One + 13U03215'},
  {'name': 'Lino Grasse', 'date': '20 Apr', 'type': 'Catering Only'},
  {'name': 'Miguel Gusto', 'date': '19 Apr', 'type': 'Dine In'},
  {
    'name': 'Grilmom, Giu Oliner',
    'date': '5.26 Apr',
    'type': 'Table + Catering',
  },
  {'name': 'Guicomart, Clare', 'date': '21 Apr', 'type': 'Dine 12 + Catering'},
  {'name': 'Might- Buestrone', 'date': '21 Apr', 'type': 'One + 13U03215'},
  {'name': 'Lino Grasse', 'date': '20 Apr', 'type': 'Catering Only'},
  {'name': 'Miguel Gusto', 'date': '19 Apr', 'type': 'Dine In'},
];
