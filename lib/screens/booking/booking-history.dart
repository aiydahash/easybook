import 'package:easybook/main-page.dart';
import 'package:easybook/screens/notification-page.dart';
import 'package:easybook/screens/registration/profile-page.dart';
import 'package:easybook/screens/search-page.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF010A3D),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No bookings found.'));
            }

            final bookings = snapshot.data!.docs;

            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final doc = bookings[index];
                final data = doc.data() as Map<String, dynamic>;

                final status = (data['status'] ?? 'UPCOMING').toUpperCase();
                final statusColor = _getStatusColor(status);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: BookingCard(
                    bookingId: doc.id,
                    name: data['roomName'] ?? 'Unknown Room',
                    type: 'Study Room',
                    peopleCount: data['peopleCount'] ?? 0,
                    status: status,
                    statusColor: statusColor,
                    details: BookingDetails(
                      date: data['date'] ?? 'Unknown Date',
                      startTime: data['startTime'] ?? 'Unknown Time',
                      endTime: data['endTime'] ?? 'Unknown Time',
                    ),
                  ),
                );
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
    );
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
}

class BookingDetails {
  final String date;
  final String startTime;
  final String endTime;

  BookingDetails({
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

class BookingCard extends StatelessWidget {
  final String bookingId;
  final String name;
  final String type;
  final int peopleCount;
  final String status;
  final Color statusColor;
  final BookingDetails? details;

  const BookingCard({
    super.key,
    required this.bookingId,
    required this.name,
    required this.type,
    required this.peopleCount,
    required this.status,
    required this.statusColor,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(height: 10),
            Text(
              '$peopleCount people',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
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
                        color: Colors.black87,
                        fontSize: 14.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${details!.startTime} - ${details!.endTime}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
