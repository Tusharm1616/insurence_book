import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/create_customer_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/add_policy_type_screen.dart';
import 'screens/customer_policy_screen.dart';
import 'screens/add_lead_screen.dart';
import 'screens/lead_list_screen.dart';
import 'providers/lead_provider.dart';

import 'screens/bank_details_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/banner_screen.dart';

import 'screens/expiring_policies_screen.dart';
import 'screens/expired_policies_screen.dart';
import 'screens/life_policy_list_screen.dart';
import 'screens/reminders_screen.dart';
import 'services/notification_service.dart';
import 'screens/vehicle_docs/vehicle_docs_screen.dart';
import 'screens/motor_calculator_screen.dart';
import 'screens/terms_conditions_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.scheduleDailyReminder();

  runApp(
    const ProviderScope(
      child: InsureBookApp(),
    ),
  );
}

class InsureBookApp extends ConsumerWidget {
  const InsureBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        '/create_customer':  (context) => const CreateCustomerScreen(),
        '/add_policy':       (context) => const AddPolicyTypeScreen(),
        '/all_policies':     (context) => const CustomerPolicyScreen(),
        '/vehicle_document': (context) => const VehicleDocsScreen(),
        '/motor_calculator': (context) => const MotorCalculatorScreen(),
        '/add_lead':         (context) => const AddLeadScreen(),
        '/bank_details':     (context) => const BankDetailsScreen(),
        '/contact_us':       (context) => const ContactUsScreen(),
        '/banner_settings':  (context) => const BannerScreen(),
        '/change_password':  (context) => const ChangePasswordScreen(),
        '/terms':            (context) => const TermsConditionsScreen(),
        '/expired_policies': (context) => const ExpiredPoliciesScreen(),
      },
      onGenerateRoute: (settings) {
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
        return null;
      },
    );
  }
}

