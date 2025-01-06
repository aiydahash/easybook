import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main-page.dart';
import 'search-page.dart';
import 'booking-history.dart';
import 'profile-page.dart';
import 'notification-page.dart';

class AvailableStudyRoomPage extends StatelessWidget {
  const AvailableStudyRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> facilities = [
      {'name': 'Study Room 1', 'capacity': '8 people'},
      {'name': 'Study Room 2', 'capacity': '8 people'},
      {'name': 'Study Room 3', 'capacity': '8 people'},
      {'name': 'Study Room 4', 'capacity': '8 people'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 10, 61),
        leading: IconButton(
          icon: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8),
            Text(
              'Easy',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
            ),
            Text(
              'Book',
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_circle_left_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Available Study Room',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: facilities.length,
                itemBuilder: (context, index) {
                  final facility = facilities[index];
                  return FacilityCard(
                    name: facility['name']!,
                    capacity: facility['capacity']!,
                    onBookPressed: () => showDateTimePicker(context, facility),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 1, 10, 61),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BookingHistoryPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              break;
          }
        },
      ),
    );
  }

  void showDateTimePicker(
      BuildContext context, Map<String, String> facility) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      final TimeOfDay? startTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (startTime != null) {
        final TimeOfDay? endTime = await showTimePicker(
          context: context,
          initialTime: startTime,
        );

        if (endTime != null) {
          // Ensure end time is after start time
          if (endTime.hour < startTime.hour ||
              (endTime.hour == startTime.hour &&
                  endTime.minute <= startTime.minute)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End time must be after start time'),
              ),
            );
            return;
          }

          final bookingDate =
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
          final startBookingTime = startTime.format(context);
          final endBookingTime = endTime.format(context);

          final bookingData = {
            'roomName': facility['name']!,
            'capacity': facility['capacity']!,
            'peopleCount': 4, // Example value, can be modified
            'date': bookingDate, // Add this line
            'status': 'UPCOMING',
            'startTime': startBookingTime,
            'endTime': endBookingTime,
            'timestamp': FieldValue.serverTimestamp(),
          };

          try {
            await FirebaseFirestore.instance
                .collection('bookings')
                .add(bookingData);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${facility['name']} booked successfully for $bookingDate from $startBookingTime to $endBookingTime!',
                ),
              ),
            );
          } catch (e) {
            print('Error saving booking: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to book the study room'),
              ),
            );
          }
        }
      }
    }
  }
}

class FacilityCard extends StatelessWidget {
  final String name;
  final String capacity;
  final VoidCallback onBookPressed;

  const FacilityCard({
    super.key,
    required this.name,
    required this.capacity,
    required this.onBookPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          capacity,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: ElevatedButton(
          onPressed: onBookPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 1, 10, 61),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text(
            'Book',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
