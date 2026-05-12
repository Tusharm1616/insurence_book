import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'config/mobile_config.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InsureBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontSize: MobileConfig.getResponsiveFontSize(context, 16),
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: MobileConfig.getResponsiveFontSize(context, 14),
            color: Colors.black87,
          ),
        ),
      ),
      home: const MobileSplashScreen(),
    );
  }
}

class MobileSplashScreen extends StatefulWidget {
  const MobileSplashScreen({super.key});

  @override
  State<MobileSplashScreen> createState() => _MobileSplashScreenState();
}

class _MobileSplashScreenState extends State<MobileSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check internet connectivity
    await _checkConnectivity();

    // Navigate to main app after initialization
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MobileMainScreen()),
      );
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none) &&
          results.length == 1) {
        _showNoInternetDialog();
      }
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text(
            'Please check your internet connection and try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MobileConfig.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.security,
                size: 60,
                color: MobileConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 30),

            // App Name
            const Text(
              'InsureBook',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Tagline
            Text(
              'Your Insurance Partner',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),

            // Loading indicator
            const SizedBox(height: 20),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MobileDashboardScreen(),
    MobilePoliciesScreen(),
    MobileCustomersScreen(),
    MobileRemindersScreen(),
    MobileProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: MobileConfig.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.policy),
            label: 'Policies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens for mobile development
class MobileDashboardScreen extends StatelessWidget {
  const MobileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: MobileConfig.primaryColor,
      ),
      body: const Center(
        child: Text(
          'Dashboard - Mobile View',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class MobilePoliciesScreen extends StatelessWidget {
  const MobilePoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Policies'),
        backgroundColor: MobileConfig.primaryColor,
      ),
      body: const Center(
        child: Text(
          'Policies - Mobile View',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class MobileCustomersScreen extends StatelessWidget {
  const MobileCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: MobileConfig.primaryColor,
      ),
      body: const Center(
        child: Text(
          'Customers - Mobile View',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class MobileRemindersScreen extends StatelessWidget {
  const MobileRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: MobileConfig.primaryColor,
      ),
      body: const Center(
        child: Text(
          'Reminders - Mobile View',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class MobileProfileScreen extends StatelessWidget {
  const MobileProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: MobileConfig.primaryColor,
      ),
      body: const Center(
        child: Text(
          'Profile - Mobile View',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
