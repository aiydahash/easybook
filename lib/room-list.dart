import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking-history.dart';
import 'main-page.dart';
import 'notification-page.dart';
import 'profile-page.dart';
import 'room-detail.dart';
import 'search-page.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final _roomNameController = TextEditingController();
  final _capacityController = TextEditingController();

  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomNameController,
              decoration: const InputDecoration(labelText: 'Room Name'),
            ),
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addRoom();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRoom() async {
    try {
      await FirebaseFirestore.instance.collection('rooms').add({
        'name': _roomNameController.text,
        'capacity': _capacityController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _roomNameController.clear();
      _capacityController.clear();
    } catch (e) {
      print('Error adding room: $e');
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationPage()),
          ),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8),
            Text('Easy',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 18)),
            Text('Book',
                style: TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontSize: 18)),
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Room List',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF020B45)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('rooms').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No rooms available'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final room = snapshot.data!.docs[index];
                    return RoomCard(
                      roomId: room.id,
                      name: room['name'],
                      capacity: room['capacity'],
                      onUpdate: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RoomDetailsPage()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        backgroundColor: const Color(0xFF020B45),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 1, 10, 61),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded), label: 'Booking History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined), label: 'Profile'),
        ],
        onTap: (index) {
          final routes = [
            const HomePage(),
            SearchPage(),
            const BookingHistoryPage(),
            const ProfilePage(),
          ];
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => routes[index]));
        },
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final String roomId;
  final String name;
  final String capacity;
  final VoidCallback onUpdate;

  const RoomCard({
    super.key,
    required this.roomId,
    required this.name,
    required this.capacity,
    required this.onUpdate,
  });

  Future<void> _deleteRoom(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting room: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF020B45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        title: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("max $capacity people",
            style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          onPressed: () => _deleteRoom(context),
        ),
      ),
    );
  }
}
