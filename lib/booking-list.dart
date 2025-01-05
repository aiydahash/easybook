import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking-history.dart';
import 'main-page.dart';
import 'notification-page.dart';
import 'profile-page.dart';
import 'search-page.dart';

class BookingListPage extends StatelessWidget {
  const BookingListPage({super.key});

  // Helper method to format timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
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

  // Helper method to fetch user details
  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return {
          'name': userDoc.data()?['name'] ?? 'Unknown User',
          'role': userDoc.data()?['role'] ?? 'User',
          'matricId': userDoc.data()?['matricID'] ?? 'N/A',
        };
      }
      return {
        'name': 'Unknown User',
        'role': 'User',
        'matricId': 'N/A',
      };
    } catch (e) {
      print('Error fetching user details: $e');
      return {
        'name': 'Unknown User',
        'role': 'User',
        'matricId': 'N/A',
      };
    }
  }

  // Helper method to process bookings
  Future<List<Map<String, dynamic>>> _processBookings(
    QuerySnapshot? roomSnapshot,
    QuerySnapshot? facilitySnapshot,
  ) async {
    List<Map<String, dynamic>> allBookings = [];

    // Process room bookings
    if (roomSnapshot != null) {
      for (var doc in roomSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] ?? '';

        Map<String, dynamic> userDetails;
        if (userId.isNotEmpty) {
          userDetails = await _getUserDetails(userId);
        } else {
          userDetails = {
            'name': data['userName'] ?? 'Unknown User',
            'role': data['userRole'] ?? 'User',
            'matricId': data['userMatricId'] ?? 'N/A',
          };
        }

        allBookings.add({
          ...data,
          'bookingType': 'room',
          'roomName': data['roomName'],
          'userName': userDetails['name'],
          'userRole': userDetails['role'],
          'userMatricId': userDetails['matricId'],
        });
      }
    }

    // Process facility bookings
    if (facilitySnapshot != null) {
      for (var doc in facilitySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] ?? '';

        Map<String, dynamic> userDetails;
        if (userId.isNotEmpty) {
          userDetails = await _getUserDetails(userId);
        } else {
          userDetails = {
            'name': data['userName'] ?? 'Unknown User',
            'role': data['userRole'] ?? 'User',
            'matricId': data['userMatricId'] ?? 'N/A',
          };
        }

        allBookings.add({
          ...data,
          'bookingType': 'facility',
          'roomName': data['facilityName'],
          'userName': userDetails['name'],
          'userRole': userDetails['role'],
          'userMatricId': userDetails['matricId'],
        });
      }
    }

    // Sort bookings by timestamp
    allBookings.sort((a, b) =>
        (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

    return allBookings;
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
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF020B45),
                        ),
                      );
                    }

                    if (roomSnapshot.hasError || facilitySnapshot.hasError) {
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
                              'Error: ${roomSnapshot.error ?? facilitySnapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _processBookings(
                        roomSnapshot.data,
                        facilitySnapshot.data,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                                  'Error processing bookings: ${snapshot.error}',
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
                              name: booking['userName'],
                              role: booking['userRole'],
                              matricId: booking['userMatricId'],
                              roomName: booking['roomName'],
                              bookingDate:
                                  _formatTimestamp(booking['timestamp']),
                              bookingTime: booking['time'] ?? 'Not specified',
                              status: booking['status'] ?? 'UPCOMING',
                              statusColor: _getStatusColor(
                                  booking['status'] ?? 'UPCOMING'),
                            );
                          },
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
  final String matricId;
  final String roomName;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final Color statusColor;

  const BookingCard({
    super.key,
    required this.name,
    required this.role,
    required this.matricId,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "$role (ID: $matricId)",
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
            const SizedBox(height: 10),
            Text(
              "Room: $roomName",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 5),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 15),
                const Icon(
                  Icons.access_time,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  bookingTime,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
