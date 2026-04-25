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
import 'screens/add_policy_type_screen.dart';
import 'screens/customer_policy_screen.dart';
import 'screens/add_lead_screen.dart';
import 'screens/lead_list_screen.dart';
import 'providers/lead_provider.dart';

import 'screens/bank_details_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/banner_screen.dart';
import 'screens/generic_placeholder_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: InsureBookApp(),
    ),
  );
}

class InsureBookApp extends StatelessWidget {
  const InsureBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InsureBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
        '/motor_calculator': (context) => const MotorCalculatorScreen(),
        '/add_lead':         (context) => const AddLeadScreen(),
        '/bank_details':     (context) => const BankDetailsScreen(),
        '/contact_us':       (context) => const ContactUsScreen(),
        '/banner_settings':  (context) => const BannerScreen(),
        '/change_password':  (context) => const GenericPlaceholderScreen(title: 'Change Password'),
        '/terms':            (context) => const GenericPlaceholderScreen(title: 'Terms & Conditions'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/all_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: 'All Leads', filterProvider: leadProvider));
        if (settings.name == '/unassigned_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: 'Unassigned Leads', filterProvider: unassignedLeadsProvider));
        if (settings.name == '/followup_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: "Today's Follow-ups", filterProvider: todayFollowupsProvider));
        if (settings.name == '/overdue_leads') return MaterialPageRoute(builder: (_) => LeadListScreen(title: 'Overdue Follow-ups', filterProvider: overdueFollowupsProvider));
        return null;
      },
    );
  }
}

class MotorCalculatorScreen extends StatelessWidget {
  const MotorCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Motor Calculator')));
  }
}
