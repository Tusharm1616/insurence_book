import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import 'dashboard_screen.dart';
import 'lead_screen.dart';
import 'search_screen.dart';
import 'setting_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const LeadScreen(),
    const SearchScreen(),
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutGrid), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.barChart2), label: 'Lead'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}
