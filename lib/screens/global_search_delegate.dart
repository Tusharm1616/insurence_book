import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../providers/policy_provider.dart';
import '../providers/customer_provider.dart';
import 'customer_policy_screen.dart';

class GlobalSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  GlobalSearchDelegate(this.ref) : super(searchFieldLabel: 'Search policies, customers, mobile...');

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.search, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Search CRM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              const Text('Search by Policy No, Name, Mobile, or Vehicle No.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final allPolicies = ref.read(policyProvider);
    final allCustomers = ref.read(customerProvider).asData?.value ?? [];

    final q = query.toLowerCase();

    // Find matching customers by Name or Mobile
    final matchingCustomers = allCustomers.where((c) => 
      c.fullName.toLowerCase().contains(q) || 
      c.mobileNumber.contains(q) ||
      (c.generatedUsername != null && c.generatedUsername!.toLowerCase().contains(q))
    ).toList();

    final matchingCustomerIds = matchingCustomers.map((c) => c.id).toSet();

    // Find matching policies by Policy No, Vehicle No, or belonging to a matching customer
    final results = allPolicies.where((p) {
      final vehNo = p.extraData['Vehicle Registration No.']?.toString().toLowerCase() ?? '';
      final isPolicyMatch = p.policyNumber.toLowerCase().contains(q);
      final isVehMatch = vehNo.contains(q);
      final isCustMatch = matchingCustomerIds.contains(p.customerId);
      return isPolicyMatch || isVehMatch || isCustMatch;
    }).toList();

    if (results.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.fileSearch, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('No Results Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              Text('No matches for "$query"', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final policy = results[index];
          final customerName = allCustomers.firstWhere(
            (c) => c.id == policy.customerId,
            orElse: () => throw Exception(),
          ).fullName;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CustomerPolicyScreen(
                    customerId: policy.customerId,
                    customerName: customerName,
                  ),
                ));
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.shield, color: AppColors.primary, size: 24),
              ),
              title: Text(policy.policyNumber.isNotEmpty ? policy.policyNumber : 'No Policy #', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('$customerName • ${policy.policyType}', style: const TextStyle(fontSize: 13)),
              ),
              trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
