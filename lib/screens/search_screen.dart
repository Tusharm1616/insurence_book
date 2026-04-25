import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/policy_model.dart';
import '../providers/policy_provider.dart';
import '../providers/customer_provider.dart';
import 'customer_policy_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _searchFilter = 'Client Name';
  final _searchCtrl = TextEditingController();
  List<Policy> _searchResults = [];
  bool _hasSearched = false;

  final List<String> _filterOptions = [
    'Client ID',
    'Mobile Number',
    'Policy No',
    'Vehicle Number',
    'Client Name',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch() {
    FocusScope.of(context).unfocus();
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    final allPolicies = ref.read(policyProvider);
    final allCustomers = ref.read(customerProvider).asData?.value ?? [];

    List<Policy> results = [];

    switch (_searchFilter) {
      case 'Client Name':
        // Find customers matching the name
        final matchingCustomers = allCustomers.where((c) => c.fullName.toLowerCase().contains(query)).map((c) => c.id).toSet();
        results = allPolicies.where((p) => matchingCustomers.contains(p.customerId)).toList();
        break;
      case 'Policy No':
        results = allPolicies.where((p) => p.policyNumber.toLowerCase().contains(query)).toList();
        break;
      case 'Vehicle Number':
        results = allPolicies.where((p) {
          final vehNo = p.extraData['Vehicle Registration No.'] ?? '';
          return vehNo.toLowerCase().contains(query);
        }).toList();
        break;
      case 'Client ID':
        final matchingCustomers = allCustomers.where((c) => c.generatedUsername?.toLowerCase().contains(query) ?? false).map((c) => c.id).toSet();
        results = allPolicies.where((p) => matchingCustomers.contains(p.customerId)).toList();
        break;
      case 'Mobile Number':
        final matchingCustomers = allCustomers.where((c) => c.mobileNumber.contains(query)).map((c) => c.id).toSet();
        results = allPolicies.where((p) => matchingCustomers.contains(p.customerId)).toList();
        break;
    }

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Text(
              'Search for policies using various criteria',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Search Filter'),
                  DropdownButtonFormField<String>(
                    initialValue: _searchFilter,
                    onChanged: (v) => setState(() => _searchFilter = v!),
                    items: _filterOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 16),

                  _label('Search Value'),
                  TextFormField(
                    controller: _searchCtrl,
                    decoration: _inputDecoration().copyWith(
                      hintText: 'Enter ${_searchFilter.toLowerCase()}',
                      prefixIcon: const Icon(LucideIcons.search, size: 20, color: Colors.blueGrey),
                    ),
                    onFieldSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),

                  _buildResults(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.search, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No search performed yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            const Text('Use the filters above to search for policies', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.fileSearch, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No Policies Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            Text('No match found for "$_searchFilter = ${_searchCtrl.text}"', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final policy = _searchResults[index];
        final customerName = ref.read(customerProvider).asData?.value.firstWhere(
          (c) => c.id == policy.customerId,
          orElse: () => throw Exception(),
        ).fullName ?? 'Unknown Customer';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () {
              // Navigate to customer policy screen, filtered by this customer
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CustomerPolicyScreen(
                  customerId: policy.customerId,
                  customerName: customerName,
                ),
              ));
            },
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(LucideIcons.shield, color: AppColors.primary),
            ),
            title: Text(policy.policyNumber.isNotEmpty ? policy.policyNumber : 'No Policy #', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$customerName • ${policy.policyType}'),
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
          ),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  );
}
