import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _notificationsStream = Stream.value([]); // Initialize with default value
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
    if (_currentUser == null || !UserManager.canAccessBookingFeatures()) {
      return Stream.value([]);
    }

    // Room bookings stream
    final roomBookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('matricID', isEqualTo: _currentUser!.matricID)
        .snapshots() // Fetch all bookings
        .map((snapshot) => _processBookingDocs(snapshot.docs, 'room'));

    // Facility bookings stream
    final facilityBookingsStream = FirebaseFirestore.instance
        .collection('facility_bookings')
        .where('matricID', isEqualTo: _currentUser!.matricID)
        .snapshots() // Fetch all bookings
        .map((snapshot) => _processBookingDocs(snapshot.docs, 'facility'));

    // Combine the streams manually
    return Stream<List<BookingNotification>>.multi((controller) {
      List<BookingNotification> roomNotifications = [];
      List<BookingNotification> facilityNotifications = [];

      void notifyListeners() {
        final allNotifications = [
          ...roomNotifications,
          ...facilityNotifications,
        ];
        // Sort notifications (optional)
        allNotifications.sort((a, b) {
          final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
          final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });
        controller.add(allNotifications);
      }

      final roomSubscription = roomBookingsStream.listen((notifications) {
        roomNotifications = notifications;
        notifyListeners();
      });

      final facilitySubscription = facilityBookingsStream.listen((notifications) {
        facilityNotifications = notifications;
        notifyListeners();
      });

      controller.onCancel = () {
        roomSubscription.cancel();
        facilitySubscription.cancel();
      };
    });
  }

  List<BookingNotification> _processBookingDocs(
      List<DocumentSnapshot> docs, String type) {
    final now = DateTime.now();
    final List<BookingNotification> notifications = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      try {
        final name = type == 'room'
            ? data['roomName'] ?? 'Unknown Room'
            : data['facilityName'] ?? 'Unknown Facility';
        final numberOfPeople = data['peopleCount'] ?? 0;
        final dateStr = data['date'] ?? '';
        final startTime = data['startTime'] ?? 'Unknown';
        final endTime = data['endTime'] ?? 'Unknown';
        final status = data['status'] ?? 'Unknown Status';

        final bookingDate = DateTime.tryParse(dateStr);
        if (bookingDate == null) {
          debugPrint('Invalid date format in document ${doc.id}: $dateStr');
          continue;
        }

        notifications.add(BookingNotification(
          roomName: name,
          numberOfPeople: numberOfPeople,
          date: dateStr,
          time: '$startTime - $endTime',
          status: status,
        ));
      } catch (e) {
        debugPrint('Error processing document ${doc.id}: $e');
      }
    }

    return notifications;
  }


  int _compareDates(String dateA, String dateB) {
    final parsedDateA = DateTime.tryParse(dateA) ?? DateTime(1970);
    final parsedDateB = DateTime.tryParse(dateB) ?? DateTime(1970);
    return parsedDateA.compareTo(parsedDateB);
  }

  @override
  Widget build(BuildContext context) {
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
              children: const [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
                        'No upcoming bookings within 24 hours.',
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
