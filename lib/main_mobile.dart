import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'config/mobile_config.dart';
import 'services/notification_service.dart';
import 'utils/auth_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService().init();
  
  // Request permissions for mobile
  await _requestMobilePermissions();
  
  runApp(MyApp());
}

Future<void> _requestMobilePermissions() async {
  // Request notification permissions
  await PermissionHandler.requestPermissions([
    Permission.notification,
    Permission.phone,
    Permission.camera,
    Permission.storage,
  ]);
  
  // Request notification permission on Android
  if (Theme.of(context).platform == TargetPlatform.android) {
    await PermissionHandler.requestPermissions([
      Permission.notification,
    ]);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      home: MobileSplashScreen(),
    );
  }
}

class MobileSplashScreen extends StatefulWidget {
  const MobileSplashScreen({Key? key}) : super(key: key);

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
    
    // Initialize Firebase messaging
    await _setupFirebaseMessaging();
    
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
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.none) {
        _showNoInternetDialog();
      }
    } catch (e) {
      print('Connectivity check failed: $e');
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Request notification permissions
      final settings = await FirebaseMessaging.instance.requestPermission();
      
      // Get FCM token
      final token = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $token');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Handle notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      print('Firebase messaging setup failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    // Show in-app notification or update UI
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Received background message: ${message.messageId}');
    // Handle background notifications
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Navigate to specific screen based on notification
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text('Please check your internet connection and try again.'),
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
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.security,
                size: 60.sp,
                color: MobileConfig.primaryColor,
              ),
            ),
            SizedBox(height: 30.h),
            
            // App Name
            Text(
              'InsureBook',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10.h),
            
            // Tagline
            Text(
              'Your Insurance Partner',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            
            // Loading indicator
            SizedBox(height: 20.h),
            SizedBox(
              width: 30.w,
              height: 4.h,
              child: const CircularProgressIndicator(
                valueColor: Colors.white,
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
  const MobileMainScreen({Key? key}) : super(key: key);

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const MobileDashboardScreen(),
    const MobilePoliciesScreen(),
    const MobileCustomersScreen(),
    const MobileRemindersScreen(),
    const MobileProfileScreen(),
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
  const MobileDashboardScreen({Key? key}) : super(key: key);

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
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }
}

class MobilePoliciesScreen extends StatelessWidget {
  const MobilePoliciesScreen({Key? key}) : super(key: key);

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
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }
}

class MobileCustomersScreen extends StatelessWidget {
  const MobileCustomersScreen({Key? key}) : super(key: key);

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
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }
}

class MobileRemindersScreen extends StatelessWidget {
  const MobileRemindersScreen({Key? key}) : super(key: key);

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
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }
}

class MobileProfileScreen extends StatelessWidget {
  const MobileProfileScreen({Key? key}) : super(key: key);

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
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }
}
