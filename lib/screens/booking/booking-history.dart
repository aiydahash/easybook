import 'package:easybook/providers/user_manager.dart';
import 'package:flutter/material.dart';
import '../../main-page.dart';
import '../notification-page.dart';
import '../search-page.dart';
import '../registration/profile-page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user can access booking features (only Student and UMPSA Staff)
    if (!UserManager.canAccessBookingFeatures()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Access denied. Only Students and UMPSA Staff can view booking history.'),
          ),
        );
      });
      return const SizedBox.shrink();
    }

    // Get current user
    final currentUser = UserManager.getCurrentUser();
    if (currentUser == null || currentUser.role == 'Library Staff') {
      return Scaffold(
        body: Center(
          child: Text(
            currentUser == null
                ? 'Please log in to view booking history'
                : 'Library Staff cannot access booking history',
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 10, 61),
        leading: IconButton(
          icon: const Icon(Icons.notifications_active_outlined,
              color: Colors.white),
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
            icon: const Icon(Icons.arrow_circle_left_outlined,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List<BookingItem>>(
          future: _fetchBookings(currentUser.matricID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading bookings'));
            }

            final allBookings = snapshot.data ?? [];

            if (allBookings.isEmpty) {
              return const Center(
                child: Text(
                  'No bookings available.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              itemCount: allBookings.length,
              itemBuilder: (context, index) {
                final booking = allBookings[index];
                return BookingCard(booking: booking);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 1, 10, 61),
        selectedItemColor: Colors.white70,
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
      backgroundColor: const Color(0xFF010A3D),
    );
  }

  Future<List<BookingItem>> _fetchBookings(String matricID) async {
    final List<BookingItem> allBookings = [];

    try {
      // Fetch room bookings
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('matricID', isEqualTo: matricID)
          .orderBy('timestamp', descending: true)
          .get();
      for (var doc in roomSnapshot.docs) {
        final data = doc.data();
        allBookings.add(
          BookingItem(
            id: doc.id,
            name: data['roomName'] ?? 'Unknown Room',
            type: 'Study Room',
            peopleCount: data['peopleCount'] ?? 0,
            status: data['status'] ?? 'UPCOMING',
            timestamp: data['timestamp'] ?? Timestamp.now(),
            date: data['date'] ?? 'Unknown Date',
            startTime: data['startTime'] ?? 'Unknown Time',
            endTime: data['endTime'] ?? 'Unknown Time',
          ),
        );
      }

      // Fetch facility bookings
      final facilitySnapshot = await FirebaseFirestore.instance
          .collection('facility_bookings')
          .where('matricID', isEqualTo: matricID)
          .orderBy('timestamp', descending: true)
          .get();
      for (var doc in facilitySnapshot.docs) {
        final data = doc.data();
        allBookings.add(
          BookingItem(
            id: doc.id,
            name: data['facilityName'] ?? 'Unknown Facility',
            type: 'Facility',
            peopleCount: data['peopleCount'] ?? 0,
            status: data['status'] ?? 'UPCOMING',
            timestamp: data['timestamp'] ?? Timestamp.now(),
            date: data['date'] ?? 'Unknown Date',
            startTime: data['startTime'] ?? 'Unknown Time',
            endTime: data['endTime'] ?? 'Unknown Time',
          ),
        );
      }

      // Sort all bookings by timestamp
      allBookings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error fetching bookings: $e');
    }

    return allBookings;
  }
}

class BookingItem {
  final String id;
  final String name;
  final String type;
  final int peopleCount;
  final String status;
  final Timestamp timestamp;
  final String date;
  final String startTime;
  final String endTime;

  BookingItem({
    required this.id,
    required this.name,
    required this.type,
    required this.peopleCount,
    required this.status,
    required this.timestamp,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

class BookingCard extends StatelessWidget {
  final BookingItem booking;

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(booking.name),
        subtitle: Text('${booking.type}\n${booking.date}'),
      ),
    );
  }
}
