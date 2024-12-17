import 'package:flutter/material.dart';
import 'main-page.dart';
import 'search-page.dart';
import 'booking-history.dart';
import 'profile-page.dart';
import 'notification-page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableStudyRoomPage extends StatelessWidget {
  const AvailableStudyRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    // List of facilities with their names and capacities
    final List<Map<String, String>> facilities = [
      {'name': 'Study Room 1', 'capacity': 'max 8 people'},
      {'name': 'Study Room 2', 'capacity': 'max 8 people'},
      {'name': 'Study Room 3', 'capacity': 'max 8 people'},
      {'name': 'Study Room 4', 'capacity': 'max 8 people'},
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
              MaterialPageRoute(builder: (context) => NotificationPage()),
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
                    onBookPressed: () async {
                      final facilityName = facility['name']!;
                      final bookingData = {
                        'roomName': facilityName,
                        'capacity': facility['capacity']!,
                        'peopleCount': 4, // Example value: you can modify this
                        'status': 'UPCOMING',
                        'date': '03/06/2024', // Example static date
                        'time':
                            '10:00 A.M. - 11:00 A.M.', // Example static time
                        'timestamp': FieldValue
                            .serverTimestamp(), // To track when it was booked
                      };

                      try {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .add(bookingData);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$facilityName booked successfully!'),
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
                    },
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
        type: BottomNavigationBarType.fixed, // Ensures consistent icon spacing
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
                MaterialPageRoute(builder: (context) => HomePage()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookingHistoryPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
              break;
          }
        },
      ),
    );
  }
}

// Widget for individual facility cards
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
