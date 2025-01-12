import 'package:easybook/screens/booking/booking-history.dart';
import 'package:easybook/screens/notification-page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main-page.dart';
import '../search-page.dart';
import '../registration/profile-page.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    try {
      final roomSnapshots = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('timestamp', descending: true)
          .get();

      final facilitySnapshots = await FirebaseFirestore.instance
          .collection('facility_bookings')
          .orderBy('timestamp', descending: true)
          .get();

      return _processBookings(roomSnapshots, facilitySnapshots);
    } catch (e) {
      print('Error fetching bookings: $e');
      return []; // Return an empty list on error
    }
  }

  Future<List<Map<String, dynamic>>> _processBookings(
    QuerySnapshot<Map<String, dynamic>> roomSnapshot,
    QuerySnapshot<Map<String, dynamic>> facilitySnapshot,
  ) async {
    List<Map<String, dynamic>> allBookings = [];

    try {
      for (var doc in roomSnapshot.docs) {
        final data = doc.data();
        allBookings.add({
          'roomName': data['roomName'] ?? 'Unknown Room',
          'formattedDate': _formatTimestamp(data['date']),
          'startTime': data['startTime'] ?? 'Not specified',
          'endTime': data['endTime'] ?? 'Not specified',
          'status': data['status'] ?? 'UPCOMING',
        });
      }

      for (var doc in facilitySnapshot.docs) {
        final data = doc.data();
        allBookings.add({
          'roomName': data['facilityName'] ?? 'Unknown Facility',
          'formattedDate': _formatTimestamp(data['date']),
          'startTime': data['startTime'] ?? 'Not specified',
          'endTime': data['endTime'] ?? 'Not specified',
          'status': data['status'] ?? 'UPCOMING',
        });
      }

      allBookings.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp?;
        final timestampB = b['timestamp'] as Timestamp?;
        if (timestampA == null || timestampB == null) return 0;
        return timestampB.compareTo(timestampA);
      });
    } catch (e) {
      print('Error processing bookings: $e');
    }

    return allBookings;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else if (timestamp is String) {
      return timestamp;
    }
    return 'Unknown Date';
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PAST':
        return Colors.yellow;
      case 'UPCOMING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

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
            onPressed: () => Navigator.pop(context),
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF020B45),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error fetching bookings: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                final allBookings = snapshot.data ?? [];

                if (allBookings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Color(0xFF020B45),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No bookings available',
                          style: TextStyle(
                            color: Color(0xFF020B45),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: allBookings.length,
                  itemBuilder: (context, index) {
                    final booking = allBookings[index];
                    return BookingCard(
                      roomName: booking['roomName'],
                      bookingDate: booking['formattedDate'],
                      startTime: booking['startTime'],
                      endTime: booking['endTime'],
                      status: booking['status'],
                      statusColor: _getStatusColor(booking['status']),
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
    );
  }
}

class BookingCard extends StatelessWidget {
  final String roomName;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final Color statusColor;

  const BookingCard({
    super.key,
    required this.roomName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
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
        child: Stack(
          children: [
            // Main content of the card
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room: $roomName",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      bookingDate,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "$startTime - $endTime",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            // Positioned status label at the top-right
            Positioned(
              top: 1,
              right: 2,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
