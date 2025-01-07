import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/registration/registration-screen.dart';
import 'main-page.dart';
import 'providers/user_manager.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures proper Flutter initialization

  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyALyzGbq0R6wWpSF8dRfHMeW3w7SMYQYwc",
          authDomain: "easybook-database.firebaseapp.com",
          projectId: "easybook-database",
          storageBucket: "easybook-database.firebasestorage.app",
          messagingSenderId: "140407769855",
          appId: "1:140407769855:web:0ac9ccbcf126645d3e5aca",
        ),
      );
      print('Firebase initialized successfully');
    } else {
      print('Firebase already initialized');
    }

    // Initialize UserManager
    await UserManager.initialize();
    print('UserManager initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _matricIDController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  String _selectedRole = 'Student'; // Default role

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 2, 21, 54),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 2, 21, 54),
                ),
              ),
              const SizedBox(height: 40),

              // Matric ID TextField
              TextField(
                controller: _matricIDController,
                decoration: InputDecoration(
                  labelText: 'Matric ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Password TextField
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['Library Staff', 'Staff', 'Student'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF010A3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Register Button to Navigate to Registration Screen
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Don’t have an account? Register',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_matricIDController.text.isEmpty || _passwordController.text.isEmpty) {
      showSnackbar(context, 'Please enter both Matric ID and Password!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await UserManager.loginUser(
        _matricIDController.text,
        _passwordController.text,
        _selectedRole,
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        showSnackbar(context, 'Invalid credentials or role!');
      }
    } catch (e) {
      showSnackbar(context, 'Login failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
