import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search-page.dart';
import 'booking/booking-history.dart';
import 'registration/profile-page.dart';
import '../main-page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Stream<List<BookingNotification>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _getNotifications();
  }

  Stream<List<BookingNotification>> _getNotifications() {
    // Combine both room and facility bookings
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'UPCOMING')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((bookingsSnapshot) async {
      final List<BookingNotification> notifications = [];

      // Process room bookings
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        // Check if the booking is within 24 hours
        final bookingDate = DateTime.parse(data['date']);
        final now = DateTime.now();
        if (bookingDate.difference(now).inHours <= 24) {
          notifications.add(
            BookingNotification(
              roomName: data['roomName'] ?? 'Unknown Room',
              numberOfPeople: data['peopleCount'] ?? 0,
              date: data['date'] ?? 'Unknown Date',
              time: '${data['startTime']} - ${data['endTime']}',
              status: data['status'] ?? 'UPCOMING',
            ),
          );
        }
      }

      // Also fetch facility bookings
      final facilitySnapshot = await FirebaseFirestore.instance
          .collection('facility_bookings')
          .where('status', isEqualTo: 'UPCOMING')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in facilitySnapshot.docs) {
        final data = doc.data();
        // Check if the booking is within 24 hours
        final bookingDate = DateTime.parse(data['date']);
        final now = DateTime.now();
        if (bookingDate.difference(now).inHours <= 24) {
          notifications.add(
            BookingNotification(
              roomName: data['facilityName'] ?? 'Unknown Facility',
              numberOfPeople: data['peopleCount'] ?? 0,
              date: data['date'] ?? 'Unknown Date',
              time: '${data['startTime']} - ${data['endTime']}',
              status: data['status'] ?? 'UPCOMING',
            ),
          );
        }
      }

      return notifications;
    });
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF010A3D),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<BookingNotification>>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading notifications: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'No upcoming bookings',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: NotificationCard(
                          roomName: notification.roomName,
                          numberOfPeople: notification.numberOfPeople,
                          date: notification.date,
                          time: notification.time,
                          status: notification.status,
                        ),
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
                MaterialPageRoute(builder: (context) => const BookingHistoryPage()),
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

class BookingNotification {
  final String roomName;
  final int numberOfPeople;
  final String date;
  final String time;
  final String status;

  BookingNotification({
    required this.roomName,
    required this.numberOfPeople,
    required this.date,
    required this.time,
    required this.status,
  });
}

class NotificationCard extends StatelessWidget {
  final String roomName;
  final int numberOfPeople;
  final String date;
  final String time;
  final String status;

  const NotificationCard({
    super.key,
    required this.roomName,
    required this.numberOfPeople,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF102A68),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF010A3D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$numberOfPeople people',
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details:',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A68),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Date: $date',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Color(0xFF102A68),
                    ),
                  ),
                  Text(
                    'Time: $time',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Color(0xFF102A68),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}