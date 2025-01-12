import 'package:flutter/material.dart';
import '../main-page.dart';
import 'booking/booking-history.dart';
import 'notification-page.dart';
import 'registration/profile-page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_room/available-study-room.dart.dart';
import 'booking_facility/available-facility.dart';

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
  List<Map<String, dynamic>> availableRooms = [];

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    try {
      final roomSnapshot =
          await FirebaseFirestore.instance.collection('rooms').get();
      final facilitySnapshot =
          await FirebaseFirestore.instance.collection('facilities').get();

      final Set<String> types = {};
      for (var doc in roomSnapshot.docs) {
        final data = doc.data();
        types.add(data['name'] ?? 'Unknown Room');
      }
      for (var doc in facilitySnapshot.docs) {
        final data = doc.data();
        types.add(data['name'] ?? 'Unknown Facility');
      }

      setState(() {
        roomTypes = types.toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading room types: $e')),
        );
      }
    }
  }

  bool _isTimeConflict(
      String startTime1, String endTime1, String startTime2, String endTime2) {
    // Convert time strings to comparable values (minutes since midnight)
    int getMinutes(String time) {
      final parts = time.split(':');
      if (parts.length != 2) return 0;
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1].split(' ')[0]) ?? 0;
      final isPM = time.toLowerCase().contains('pm');
      return (hours + (isPM && hours != 12 ? 12 : 0)) * 60 + minutes;
    }

    final start1 = getMinutes(startTime1);
    final end1 = getMinutes(endTime1);
    final start2 = getMinutes(startTime2);
    final end2 = getMinutes(endTime2);

    return (start1 < end2) && (end1 > start2);
  }

  void _searchRooms() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    try {
      // Get all rooms and facilities
      final roomsSnapshot =
          await FirebaseFirestore.instance.collection('rooms').get();
      final facilitiesSnapshot =
          await FirebaseFirestore.instance.collection('facilities').get();

      // Get existing bookings for the selected date
      final bookingDate =
          '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
      final roomBookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('date', isEqualTo: bookingDate)
          .get();

      final facilityBookingsSnapshot = await FirebaseFirestore.instance
          .collection('facility_bookings')
          .where('date', isEqualTo: bookingDate)
          .get();

      // Create maps of existing bookings
      final Map<String, List<Map<String, String>>> existingBookings = {};

      for (var doc in roomBookingsSnapshot.docs) {
        final data = doc.data();
        final roomName = data['roomName'] as String;
        existingBookings[roomName] ??= [];
        existingBookings[roomName]!.add({
          'startTime': data['startTime'] as String,
          'endTime': data['endTime'] as String,
        });
      }

      for (var doc in facilityBookingsSnapshot.docs) {
        final data = doc.data();
        final facilityName = data['facilityName'] as String;
        existingBookings[facilityName] ??= [];
        existingBookings[facilityName]!.add({
          'startTime': data['startTime'] as String,
          'endTime': data['endTime'] as String,
        });
      }

      // Check availability for each room and facility
      final List<Map<String, dynamic>> available = [];

      // Function to check if a space is available
      bool isSpaceAvailable(String spaceName, String proposedStartTime) {
        if (!existingBookings.containsKey(spaceName)) return true;

        // Assume booking duration is 1 hour
        final proposedEndTime = TimeOfDay(
          hour: (selectedTime!.hour + 1) % 24,
          minute: selectedTime!.minute,
        ).format(context);

        return !existingBookings[spaceName]!.any((booking) => _isTimeConflict(
              proposedStartTime,
              proposedEndTime,
              booking['startTime']!,
              booking['endTime']!,
            ));
      }

      // Check rooms
      for (var doc in roomsSnapshot.docs) {
        final data = doc.data();
        final roomName = data['name'] as String;

        if (selectedRoomType == null || selectedRoomType == roomName) {
          if (isSpaceAvailable(roomName, selectedTime!.format(context))) {
            available.add({
              'name': roomName,
              'type': 'Study Room',
              'capacity': data['capacity'],
            });
          }
        }
      }

      // Check facilities
      for (var doc in facilitiesSnapshot.docs) {
        final data = doc.data();
        final facilityName = data['name'] as String;

        if (selectedRoomType == null || selectedRoomType == facilityName) {
          if (isSpaceAvailable(facilityName, selectedTime!.format(context))) {
            available.add({
              'name': facilityName,
              'type': 'Facility',
              'capacity': data['capacity'],
            });
          }
        }
      }

      setState(() {
        availableRooms = available;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for rooms: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 10, 61),
        leading: IconButton(
          icon: const Icon(Icons.notifications_active_outlined,
              color: Colors.white),
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
            icon: const Icon(Icons.arrow_circle_left_outlined,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
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
              onChanged: (value) => setState(() => selectedRoomType = value),
              hint: const Text('Select room type'),
            ),
            const SizedBox(height: 20),
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
                  setState(() => selectedDate = date);
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
                  setState(() => selectedTime = time);
                }
              },
              readOnly: true,
              controller: TextEditingController(
                text: selectedTime != null ? selectedTime!.format(context) : '',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _searchRooms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 10, 61),
                padding: const EdgeInsets.symmetric(
                    horizontal: 50.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0)),
              ),
              child: const Text('SEARCH',
                  style: TextStyle(fontSize: 16.0, color: Colors.white)),
            ),
            const SizedBox(height: 30),
            if (availableRooms.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = availableRooms[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(room['name']),
                        subtitle: Text(
                            '${room['type']} - Capacity: ${room['capacity']} people'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Navigate to booking page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    room['type'] == 'Study Room'
                                        ? const AvailableStudyRoomPage()
                                        : const AvailableFacilityPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 10, 61),
                          ),
                          child: const Text('Book',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (availableRooms.isEmpty &&
                selectedDate != null &&
                selectedTime != null)
              const Text('No rooms available for the selected criteria.'),
          ],
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
}
