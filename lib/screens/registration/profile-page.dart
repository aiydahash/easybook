import 'package:flutter/material.dart';
import 'edit-profile-page.dart';
import '../notification-page.dart';
import '../search-page.dart';
import '../booking/booking-history.dart';
import '../../main.dart';
import '../../providers/user_manager.dart';
import '../../main-page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Common fields
  late String fullName = '';
  late String matricId = '';
  late String email = '';
  late String role = '';

  // Role-specific fields
  late String course = '';
  late String semester = '';
  late String department = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final currentUser = UserManager.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        // Common fields
        fullName = currentUser.name;
        matricId = currentUser.matricID;
        email = currentUser.email;
        role = currentUser.role;

        // Role-specific fields
        switch (role) {
          case 'Student':
            course = currentUser.additionalInfo?['course'] ?? "Not set";
            semester = currentUser.additionalInfo?['semester'] ?? "Not set";
            break;
          case 'Staff':
            department = currentUser.additionalInfo?['department'] ?? "Not set";
            break;
        }
      });
    }
  }

  void _updateProfile(Map<String, String> updatedData) async {
    setState(() {
      fullName = updatedData['fullName'] ?? fullName;
      matricId = updatedData['matricId'] ?? matricId;
      email = updatedData['email'] ?? email;

      // Update role-specific fields
      switch (role) {
        case 'Student':
          course = updatedData['course'] ?? course;
          semester = updatedData['semester'] ?? semester;
          break;
        case 'Staff':
          department = updatedData['department'] ?? department;
          break;
      }
    });

    await UserManager.updateUserProfile(
      matricId,
      name: fullName,
      additionalInfo: {
        'course': course,
        'semester': semester,
        'department': department,
      },
    );
  }

  void _handleLogout() async {
    await UserManager.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
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
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF010A3D),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                '$role Profile',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 60.0,
                  color: Color(0xFF010A3D),
                ),
              ),
              const SizedBox(height: 30),

              // Common fields for all roles
              ProfileDetail(label: 'Full Name', value: fullName),
              ProfileDetail(label: 'Matric ID', value: matricId),
              ProfileDetail(label: 'Email', value: email),
              ProfileDetail(label: 'Role', value: role),

              // Role-specific fields
              if (role == 'Student') ...[
                ProfileDetail(label: 'Course', value: course),
                ProfileDetail(label: 'Semester', value: semester),
              ] else if (role == 'Staff') ...[
                ProfileDetail(label: 'Department', value: department),
              ],

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final updatedData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        fullName: fullName,
                        matricId: matricId,
                        email: email,
                        role: role,
                        course: course,
                        semester: semester,
                        department: department,
                      ),
                    ),
                  );
                  if (updatedData != null) {
                    _updateProfile(updatedData);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF010A3D),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
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
                MaterialPageRoute(
                  builder: (context) => const BookingHistoryPage(),
                ),
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

class ProfileDetail extends StatelessWidget {
  final String label;
  final String value;

  const ProfileDetail({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
