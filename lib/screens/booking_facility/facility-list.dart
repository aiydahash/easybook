import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../booking/booking-history.dart';
import 'facility-detail.dart';
import '../../main-page.dart';
import '../notification-page.dart';
import '../registration/profile-page.dart';
import '../search-page.dart';

class FacilityListPage extends StatefulWidget {
  const FacilityListPage({super.key});

  @override
  State<FacilityListPage> createState() => _FacilityListPageState();
}

class _FacilityListPageState extends State<FacilityListPage> {
  final _facilityNameController = TextEditingController();
  final _capacityController = TextEditingController();

  void _showAddFacilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Facility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _facilityNameController,
              decoration: const InputDecoration(labelText: 'Facility Name'),
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
              _addFacility();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFacility() async {
    try {
      await FirebaseFirestore.instance.collection('facilities').add({
        'name': _facilityNameController.text,
        'capacity': _capacityController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _facilityNameController.clear();
      _capacityController.clear();
    } catch (e) {
      print('Error adding facility: $e');
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
              'Facility List',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF020B45)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('facilities')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No facilities available'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final facility = snapshot.data!.docs[index];
                    return FacilityCard(
                      facilityId: facility.id,
                      name: facility['name'],
                      capacity: facility['capacity'],
                      onUpdate: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FacilityDetailsPage()),
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
        onPressed: _showAddFacilityDialog,
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

class FacilityCard extends StatelessWidget {
  final String facilityId;
  final String name;
  final String capacity;
  final VoidCallback onUpdate;

  const FacilityCard({
    super.key,
    required this.facilityId,
    required this.name,
    required this.capacity,
    required this.onUpdate,
  });

  Future<void> _deleteFacility(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('facilities')
          .doc(facilityId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facility deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting facility: $e')),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: () => _deleteFacility(context),
            ),
          ],
        ),
      ),
    );
  }
}
