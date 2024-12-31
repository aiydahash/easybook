import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking-history.dart';
import 'main-page.dart';
import 'notification-page.dart';
import 'profile-page.dart';
import 'search-page.dart';

class BookingListPage extends StatelessWidget {
  const BookingListPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Booking List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF020B45),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, roomSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('facility_bookings')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, facilitySnapshot) {
                    if (roomSnapshot.connectionState == ConnectionState.waiting ||
                        facilitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (roomSnapshot.hasError || facilitySnapshot.hasError) {
                      return const Center(child: Text('Error loading bookings'));
                    }

                    final List<Map<String, dynamic>> allBookings = [];

                    // Add room bookings
                    if (roomSnapshot.hasData) {
                      for (var doc in roomSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        allBookings.add({
                          ...data,
                          'bookingType': 'room',
                          'roomName': data['roomName'],
                        });
                      }
                    }

                    // Add facility bookings
                    if (facilitySnapshot.hasData) {
                      for (var doc in facilitySnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        allBookings.add({
                          ...data,
                          'bookingType': 'facility',
                          'roomName': data['facilityName'],
                        });
                      }
                    }

                    // Sort bookings by timestamp
                    allBookings.sort((a, b) => (b['timestamp'] as Timestamp)
                        .compareTo(a['timestamp'] as Timestamp));

                    if (allBookings.isEmpty) {
                      return const Center(child: Text('No bookings available'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: allBookings.length,
                      itemBuilder: (context, index) {
                        final booking = allBookings[index];
                        return BookingCard(
                          name: booking['userName'] ?? 'Unknown User',
                          role: booking['userRole'] ?? 'User',
                          roomName: booking['roomName'] ?? 'Unknown Room',
                          bookingDate: booking['date'] ?? '',
                          bookingTime: booking['time'] ?? '',
                          status: booking['status'] ?? 'UPCOMING',
                          statusColor: booking['status'] == 'PAST'
                              ? Colors.yellow
                              : Colors.blue,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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
            label: 'Booking History',
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
                MaterialPageRoute(builder: (context) => SearchPage()),
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
}

class BookingCard extends StatelessWidget {
  final String name;
  final String role;
  final String roomName;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final Color statusColor;

  const BookingCard({
    super.key,
    required this.name,
    required this.role,
    required this.roomName,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF020B45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$name - $role",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Room: $roomName",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              "Date: $bookingDate",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              "Time: $bookingTime",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}