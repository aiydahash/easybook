import 'package:flutter/material.dart';
import 'main-page.dart';
import 'notification-page.dart';
import 'search-page.dart';
import 'profile-page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

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
          children: [
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
                      if (roomSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          facilitySnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (roomSnapshot.hasError || facilitySnapshot.hasError) {
                        return const Center(
                            child: Text('Error loading bookings'));
                      }

                      final List<BookingItem> allBookings = [];

                      if (roomSnapshot.hasData) {
                        for (var doc in roomSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          allBookings.add(
                            BookingItem(
                              id: doc.id, // Add the document ID
                              name: data['roomName'] ?? 'Unknown Room',
                              type: 'Study Room',
                              peopleCount: data['peopleCount'] ?? 0,
                              status: data['status'] ?? 'UPCOMING',
                              timestamp: data['timestamp'] as Timestamp,
                              date: data['date'] ?? 'Unknown Date',
                              time: data['time'] ?? 'Unknown Time',
                            ),
                          );
                        }
                      }

                      if (facilitySnapshot.hasData) {
                        for (var doc in facilitySnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          allBookings.add(
                            BookingItem(
                              id: doc.id, // Add the document ID
                              name: data['facilityName'] ?? 'Unknown Facility',
                              type: 'Facility',
                              peopleCount: data['peopleCount'] ?? 0,
                              status: data['status'] ?? 'UPCOMING',
                              timestamp: data['timestamp'] as Timestamp,
                              date: data['date'] ?? 'Unknown Date',
                              time: data['time'] ?? 'Unknown Time',
                            ),
                          );
                        }
                      }

                      allBookings
                          .sort((a, b) => b.timestamp.compareTo(a.timestamp));

                      if (allBookings.isEmpty) {
                        return const Center(
                            child: Text('No bookings available.'));
                      }

                      return ListView.builder(
                        itemCount: allBookings.length,
                        itemBuilder: (context, index) {
                          final booking = allBookings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: BookingCard(
                              bookingId: booking.id, // Pass the booking ID
                              name: booking.name,
                              type: booking.type,
                              peopleCount: booking.peopleCount,
                              status: booking.status,
                              statusColor: booking.status == 'PAST'
                                  ? Colors.yellow
                                  : Colors.black,
                              details: BookingDetails(
                                date: booking.date,
                                time: booking.time,
                              ),
                            ),
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
                MaterialPageRoute(
                    builder: (context) => const BookingHistoryPage()),
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
      backgroundColor: const Color(0xFF010A3D),
    );
  }
}

// Data class to hold booking information
class BookingItem {
  final String id; // Added ID field for Firebase document ID
  final String name;
  final String type;
  final int peopleCount;
  final String status;
  final Timestamp timestamp;
  final String date;
  final String time;

  BookingItem({
    required this.id,
    required this.name,
    required this.type,
    required this.peopleCount,
    required this.status,
    required this.timestamp,
    required this.date,
    required this.time,
  });
}

class BookingCard extends StatelessWidget {
  final String bookingId; // New booking ID field
  final String name;
  final String type;
  final int peopleCount;
  final String status;
  final Color statusColor;
  final BookingDetails? details;

  const BookingCard({
    super.key,
    required this.bookingId, // Initialize bookingId
    required this.name,
    required this.type,
    required this.peopleCount,
    required this.status,
    required this.statusColor,
    this.details,
  });

  // Function to delete the booking
  Future<void> _deleteBooking(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();
      await FirebaseFirestore.instance
          .collection('facility_bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '$peopleCount people',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
              ),
            ),
            if (details != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${details!.date}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                      ),
                      Text(
                        'Time: ${details!.time}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _deleteBooking(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookingDetails {
  final String date;
  final String time;

  BookingDetails({required this.date, required this.time});
}
