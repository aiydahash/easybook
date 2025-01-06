import 'package:flutter/material.dart';
import 'main-page.dart';
import 'booking-history.dart';
import 'notification-page.dart';
import 'profile-page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EasyBook',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? selectedRoomType;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  List<String> roomTypes = [];
  List<Map<String, dynamic>> filteredBookings = [];

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    try {
      final roomSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();
      final facilitySnapshot = await FirebaseFirestore.instance
          .collection('facility_bookings')
          .get();

      final Set<String> types = {};
      for (var doc in roomSnapshot.docs) {
        final data = doc.data();
        types.add(data['roomName'] ?? 'Unknown Room');
      }
      for (var doc in facilitySnapshot.docs) {
        final data = doc.data();
        types.add(data['facilityName'] ?? 'Unknown Facility');
      }

      setState(() {
        roomTypes = types.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading room types: $e')),
      );
    }
  }

  void _searchRooms() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    try {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('timestamp', descending: true)
          .get();

      final facilitySnapshot = await FirebaseFirestore.instance
          .collection('facility_bookings')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> allBookings = [];

      for (var doc in roomSnapshot.docs) {
        final data = doc.data();
        allBookings.add({
          'roomType': data['roomName'] ?? 'Unknown Room',
          'date': data['date'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
        });
      }

      for (var doc in facilitySnapshot.docs) {
        final data = doc.data();
        allBookings.add({
          'roomType': data['facilityName'] ?? 'Unknown Facility',
          'date': data['date'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
        });
      }

      setState(() {
        filteredBookings = allBookings.where((booking) {
          final bookingDate = booking['date'];
          final bookingStartTime = TimeOfDay(
            hour: int.parse(booking['startTime'].split(':')[0]),
            minute: int.parse(booking['startTime'].split(':')[1]),
          );
          return bookingDate == '${selectedDate!.toLocal()}'.split(' ')[0] &&
              bookingStartTime == selectedTime &&
              (selectedRoomType == null ||
                  booking['roomType'] == selectedRoomType);
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving bookings: $e')),
      );
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Search Available Rooms',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Room Type Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0)),
                hintText: 'Room Type',
              ),
              items: roomTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRoomType = value;
                });
              },
              hint: const Text('Select room type'),
            ),
            const SizedBox(height: 20),
            // Date Picker
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_today),
                hintText: 'Select date',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0)),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
              readOnly: true,
              controller: TextEditingController(
                text: selectedDate != null
                    ? '${selectedDate!.toLocal()}'.split(' ')[0]
                    : '',
              ),
            ),
            const SizedBox(height: 20),
            // Time Picker
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.access_time),
                hintText: 'Select time',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0)),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
              readOnly: true,
              controller: TextEditingController(
                text: selectedTime != null ? selectedTime!.format(context) : '',
              ),
            ),
            const SizedBox(height: 30),
            // Search Button
            ElevatedButton(
              onPressed: _searchRooms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 10, 61),
                padding: const EdgeInsets.symmetric(
                    horizontal: 50.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0)),
              ),
              child: const Text(
                'SEARCH',
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            // Search Results
            if (filteredBookings.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return ListTile(
                      title: Text(booking['roomType']),
                      subtitle: Text(
                          'Date: ${booking['date']} | Start Time: ${booking['startTime']} | End Time: ${booking['endTime']}'),
                    );
                  },
                ),
              )
            else if (filteredBookings.isEmpty &&
                selectedDate != null &&
                selectedTime != null)
              const Text('No rooms available for the selected criteria.'),
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
                MaterialPageRoute(builder: (context) => const SearchPage()),
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
