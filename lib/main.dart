import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'core/theme.dart';
import 'screens/create_customer_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/new_customer_list_screen.dart';
import 'screens/customer_detail_screen.dart';
import 'screens/edit_customer_screen.dart';
import 'screens/policy_list_screen.dart';

import 'screens/main_navigation_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/add_policy_type_screen.dart';
import 'screens/customer_policy_screen.dart';
import 'screens/add_lead_screen.dart';
import 'screens/lead_list_screen.dart';
import 'screens/lead_detail_screen.dart';
import 'providers/lead_provider.dart';

import 'screens/bank_details_screen.dart';
import 'screens/contact_us_screen.dart';

import 'screens/expiring_policies_screen.dart';
import 'screens/expired_policies_screen.dart';
import 'screens/life_policy_list_screen.dart';
import 'screens/reminders_screen.dart';
import 'services/notification_service.dart';
import 'screens/vehicle_docs/vehicle_docs_screen.dart';
import 'screens/motor_calculator_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/pdf_intake_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Holds a pending shared PDF file path (set before app finishes loading)
SharedMediaFile? pendingSharedPdf;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.scheduleDailyReminder();

  // Check for shared PDF files on cold start
  final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
  if (initialMedia.isNotEmpty) {
    final pdfFile = initialMedia.firstWhere(
      (f) {
        final path = f.path.toLowerCase();
        final mime = f.mimeType?.toLowerCase() ?? '';
        return path.endsWith('.pdf') || mime.contains('pdf');
      },
      orElse: () => initialMedia.first.type == SharedMediaType.file 
          ? initialMedia.first 
          : SharedMediaFile(path: '', type: SharedMediaType.file, mimeType: ''),
    );
    if (pdfFile.path.isNotEmpty) {
      pendingSharedPdf = pdfFile;
    }
  }

  runApp(
    const ProviderScope(
      child: InsureBookApp(),
    ),
  );
}

class InsureBookApp extends ConsumerStatefulWidget {
  const InsureBookApp({super.key});

  @override
  ConsumerState<InsureBookApp> createState() => _InsureBookAppState();
}

class _InsureBookAppState extends ConsumerState<InsureBookApp> {
  late StreamSubscription _shareIntentSub;

  @override
  void initState() {
    super.initState();
    // Listen for shared files while app is already running
    _shareIntentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isEmpty) return;
        final pdfFile = files.firstWhere(
          (f) {
            final path = f.path.toLowerCase();
            final mime = f.mimeType?.toLowerCase() ?? '';
            return path.endsWith('.pdf') || mime.contains('pdf');
          },
          orElse: () => files.first.type == SharedMediaType.file 
              ? files.first 
              : SharedMediaFile(path: '', type: SharedMediaType.file, mimeType: ''),
        );
        if (pdfFile.path.isNotEmpty) {
          _navigateToPdfIntake(pdfFile);
        }
      },
    );
  }

  @override
  void dispose() {
    _shareIntentSub.cancel();
    super.dispose();
  }

  void _navigateToPdfIntake(SharedMediaFile pdfFile) {
    final file = File(pdfFile.path);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    final fileName = pdfFile.path.split('/').last.split('\\').last;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PdfIntakeScreen(
          filePath: pdfFile.path,
          fileName: fileName,
          fileSize: fileSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'InsureBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/':                 (context) => const SplashScreen(),
        '/login':            (context) => const LoginScreen(),
        '/register':         (context) => const RegisterScreen(),
        '/forgot-password':  (context) => const ForgotPasswordScreen(),
        '/dashboard':        (context) => const MainNavigationScreen(),
        '/customers':        (context) => const CustomerListScreen(),
        '/policies':         (context) => const PolicyListScreen(),
        '/create_customer':  (context) => const CreateCustomerScreen(),
        '/add_policy':       (context) => const AddPolicyTypeScreen(),
        '/all_policies':     (context) => const CustomerPolicyScreen(),
        '/vehicle_document': (context) => const VehicleDocsScreen(),
        '/motor_calculator': (context) => const MotorCalculatorScreen(),
        '/add_lead':         (context) => const AddLeadScreen(),
        '/bank_details':     (context) => const BankDetailsScreen(),
        '/contact_us':       (context) => const ContactUsScreen(),
        '/change_password':  (context) => const ChangePasswordScreen(),
        '/terms':            (context) => const TermsConditionsScreen(),
        '/expired_policies': (context) => const ExpiredPoliciesScreen(),
        '/pdf_intake':       (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PdfIntakeScreen(
            filePath: args['filePath'] as String,
            fileName: args['fileName'] as String,
            fileSize: args['fileSize'] as int,
          );
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/customer_list') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => NewCustomerListScreen(
              filter: args['filter'] as String? ?? 'all',
              title: args['title'] as String? ?? 'All Customers',
            ),
          );
        }
        if (settings.name == '/policy_list') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => PolicyListScreen(
              filter: args['filter'] as String? ?? 'all',
              title: args['title'] as String? ?? 'All Policies',
            ),
          );
        }
        if (settings.name == '/customer_detail') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(
              customerId: int.tryParse(args['customerId'].toString()) ?? 0,
            ),
          );
        }
        if (settings.name == '/edit_customer') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => EditCustomerScreen(
              customerId: args['customerId']?.toString() ?? '',
            ),
          );
        }
        if (settings.name == '/expiring_policies') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ExpiringPoliciesScreen(
              days: args['days'] as int,
              title: args['title'] as String,
            ),
          );
        }
        if (settings.name == '/life_policies') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => LifePolicyListScreen(
              filter: args['filter'] as String,
              title: args['title'] as String,
              themeColor: args['color'] as Color,
            ),
          );
        }
        if (settings.name == '/reminders') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => RemindersScreen(
              type: args['type'] as String,
            ),
          );
        }
        if (settings.name == '/all_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: 'All Leads', filterProvider: leadProvider));
        if (settings.name == '/unassigned_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: 'Unassigned Leads', filterProvider: unassignedLeadsProvider));
        if (settings.name == '/followup_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: "Today's Follow-ups", filterProvider: todayFollowupsProvider));
        if (settings.name == '/overdue_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: 'Overdue Follow-ups', filterProvider: overdueFollowupsProvider));
        if (settings.name == '/lead_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => LeadDetailScreen(lead: args['lead'] as Lead),
          );
        }
        return null;
      },
    );
  }
}

