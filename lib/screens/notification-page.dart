import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search-page.dart';
import 'booking/booking-history.dart';
import 'registration/profile-page.dart';
import '../main-page.dart';
import '../providers/user_manager.dart';
import '../domain/user_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Stream<List<BookingNotification>> _notificationsStream;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final user = UserManager.getCurrentUser();
    setState(() {
      _currentUser = user;
      _notificationsStream = _getNotifications();
    });
  }

  Stream<List<BookingNotification>> _getNotifications() {
    // Return empty stream if user is not logged in or is Library Staff
    if (_currentUser == null || !UserManager.canAccessBookingFeatures()) {
      return Stream.value([]);
    }

    final now = DateTime.now();

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('matricID',
            isEqualTo: _currentUser!.matricID) // Use matricID from AppUser
        .where('status', isEqualTo: 'UPCOMING')
        .snapshots()
        .map((bookingsSnapshot) {
      final List<BookingNotification> notifications = [];

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        debugPrint('Document data: $data');

        try {
          final roomName = data['roomName'] as String? ?? 'Unknown Room';
          final numberOfPeople = data['peopleCount'] as int? ?? 0;
          final dateStr = data['date'] as String?;
          final startTime = data['startTime'] as String? ?? 'Unknown';
          final endTime = data['endTime'] as String? ?? 'Unknown';
          final status = data['status'] as String? ?? 'Unknown Status';

          if (dateStr == null) {
            debugPrint('Missing "date" field in document ${doc.id}');
            continue;
          }

          final bookingDate = DateTime.tryParse(dateStr);
          if (bookingDate == null) {
            debugPrint('Invalid date format in document ${doc.id}: $dateStr');
            continue;
          }

          // Add notification if within 24 hours
          if (bookingDate.difference(now).inHours <= 24) {
            notifications.add(
              BookingNotification(
                roomName: roomName,
                numberOfPeople: numberOfPeople,
                date: dateStr,
                time: '$startTime - $endTime',
                status: status,
              ),
            );
          }
        } catch (e, stackTrace) {
          debugPrint('Error processing document ${doc.id}: $e');
          debugPrint('StackTrace: $stackTrace');
        }
      }

      notifications.sort((a, b) {
        final timestampA = DateTime.tryParse(a.date) ?? DateTime(1970);
        final timestampB = DateTime.tryParse(b.date) ?? DateTime(1970);
        return timestampB.compareTo(timestampA);
      });

      return notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show restricted access message for Library Staff
    if (_currentUser != null && !UserManager.canAccessBookingFeatures()) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 1, 10, 61),
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
        body: const Center(
          child: Text(
            'Notifications are not available for Library Staff',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    // Regular notification page for Students and UMPSA Staff
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 10, 61),
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
            Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<BookingNotification>>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  if (_currentUser == null) {
                    return const Center(
                      child: Text(
                        'Please log in to view notifications',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
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
