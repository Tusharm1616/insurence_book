import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/lucide_compat.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

// ── Search Result Models ─────────────────────────────────────────────────────

class SearchCustomer {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String status;

  SearchCustomer({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.status,
  });

  factory SearchCustomer.fromJson(Map<String, dynamic> j) => SearchCustomer(
        id: j['id']?.toString() ?? '',
        fullName: j['full_name'] ?? '',
        phone: j['phone'] ?? '',
        email: j['email'] ?? '',
        city: j['city'] ?? '',
        status: j['status'] ?? 'active',
      );
}

class SearchPolicy {
  final String id;
  final String policyNumber;
  final String policyType;
  final String insurerName;
  final double premiumAmount;
  final String status;
  final String customerName;
  final String customerId;

  SearchPolicy({
    required this.id,
    required this.policyNumber,
    required this.policyType,
    required this.insurerName,
    required this.premiumAmount,
    required this.status,
    required this.customerName,
    required this.customerId,
  });

  factory SearchPolicy.fromJson(Map<String, dynamic> j) => SearchPolicy(
        id: j['id']?.toString() ?? '',
        policyNumber: j['policy_number'] ?? '',
        policyType: j['policy_type'] ?? '',
        insurerName: j['insurer_name'] ?? '',
        premiumAmount: (j['premium_amount'] ?? 0).toDouble(),
        status: j['status'] ?? '',
        customerName: j['customer_name'] ?? 'Unknown',
        customerId: j['customer_id']?.toString() ?? '',
      );
}

class SearchLead {
  final String id;
  final String name;
  final String phone;
  final String status;

  SearchLead({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
  });

  factory SearchLead.fromJson(Map<String, dynamic> j) => SearchLead(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        phone: j['phone'] ?? j['mobile'] ?? '',
        status: j['status'] ?? '',
      );
}

class SearchResults {
  final List<SearchCustomer> customers;
  final List<SearchPolicy> policies;
  final List<SearchLead> leads;

  const SearchResults({
    this.customers = const [],
    this.policies = const [],
    this.leads = const [],
  });

  bool get isEmpty => customers.isEmpty && policies.isEmpty && leads.isEmpty;
  int get totalCount => customers.length + policies.length + leads.length;
}

// ── Search Screen ────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  SearchResults? _results;
  bool _isLoading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = null;
        _isLoading = false;
        _error = null;
        _lastQuery = '';
      });
      return;
    }

    if (trimmed == _lastQuery) return;
    _lastQuery = trimmed;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await apiService.dio.get(
        '/api/search',
        queryParameters: {'q': trimmed},
      );

      final data = response.data;
      final results = SearchResults(
        customers: (data['customers'] as List? ?? [])
            .map((e) => SearchCustomer.fromJson(e as Map<String, dynamic>))
            .toList(),
        policies: (data['policies'] as List? ?? [])
            .map((e) => SearchPolicy.fromJson(e as Map<String, dynamic>))
            .toList(),
        leads: (data['leads'] as List? ?? [])
            .map((e) => SearchLead.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      if (mounted && trimmed == _lastQuery) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppThemeHelper.cardColor(context),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: TextStyle(
                fontSize: 15,
                color: AppThemeHelper.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Search customers, policies, leads...',
                hintStyle: TextStyle(
                  color: AppThemeHelper.textSecondary(context),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: AppThemeHelper.textSecondary(context),
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: AppThemeHelper.textSecondary(context),
                          size: 18,
                        ),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = null;
                            _isLoading = false;
                            _error = null;
                            _lastQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppThemeHelper.surfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppThemeHelper.borderColor(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppThemeHelper.borderColor(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Results area
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(context);
    }

    if (_results == null || _controller.text.trim().length < 2) {
      return _buildEmptyState(context);
    }

    if (_results!.isEmpty) {
      return _buildNoResults(context);
    }

    return _buildResults(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.search,
              size: 56,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Search InsureBook',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by customer name, phone number,\npolicy number, or lead name',
            style: TextStyle(
              fontSize: 13,
              color: AppThemeHelper.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.fileSearch,
              size: 56,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No matches for "${_controller.text.trim()}"',
            style: TextStyle(
              fontSize: 13,
              color: AppThemeHelper.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            'Search failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemeHelper.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: TextStyle(
              fontSize: 12,
              color: AppThemeHelper.textSecondary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _performSearch(_controller.text),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final results = _results!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Customers section
        if (results.customers.isNotEmpty) ...[
          _sectionHeader(context, LucideIcons.users, 'Customers', results.customers.length),
          ...results.customers.map((c) => _customerTile(context, c)),
          const SizedBox(height: 16),
        ],

        // Policies section
        if (results.policies.isNotEmpty) ...[
          _sectionHeader(context, LucideIcons.shield, 'Policies', results.policies.length),
          ...results.policies.map((p) => _policyTile(context, p)),
          const SizedBox(height: 16),
        ],

        // Leads section
        if (results.leads.isNotEmpty) ...[
          _sectionHeader(context, LucideIcons.target, 'Leads', results.leads.length),
          ...results.leads.map((l) => _leadTile(context, l)),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerTile(BuildContext context, SearchCustomer customer) {
    final initials = customer.fullName.trim().isEmpty
        ? 'C'
        : customer.fullName
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppThemeHelper.borderColor(context)),
      ),
      color: AppThemeHelper.cardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.info.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.info,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          customer.fullName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppThemeHelper.textPrimary(context),
          ),
        ),
        subtitle: Text(
          customer.phone.isNotEmpty ? customer.phone : customer.email,
          style: TextStyle(
            fontSize: 12,
            color: AppThemeHelper.textSecondary(context),
          ),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: AppThemeHelper.textSecondary(context),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/customer_detail',
            arguments: {'customerId': customer.id},
          );
        },
      ),
    );
  }

  Widget _policyTile(BuildContext context, SearchPolicy policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppThemeHelper.borderColor(context)),
      ),
      color: AppThemeHelper.cardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.shield, color: AppColors.primary, size: 20),
        ),
        title: Text(
          policy.policyNumber.isNotEmpty ? policy.policyNumber : 'No Policy #',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppThemeHelper.textPrimary(context),
          ),
        ),
        subtitle: Text(
          '${policy.customerName} • ${policy.policyType}',
          style: TextStyle(
            fontSize: 12,
            color: AppThemeHelper.textSecondary(context),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(policy.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                policy.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(policy.status),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: AppThemeHelper.textSecondary(context),
            ),
          ],
        ),
        onTap: () {
          if (policy.customerId.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/customer_detail',
              arguments: {'customerId': policy.customerId},
            );
          }
        },
      ),
    );
  }

  Widget _leadTile(BuildContext context, SearchLead lead) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppThemeHelper.borderColor(context)),
      ),
      color: AppThemeHelper.cardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.target, color: AppColors.warning, size: 20),
        ),
        title: Text(
          lead.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppThemeHelper.textPrimary(context),
          ),
        ),
        subtitle: Text(
          lead.phone,
          style: TextStyle(
            fontSize: 12,
            color: AppThemeHelper.textSecondary(context),
          ),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: AppThemeHelper.textSecondary(context),
        ),
        onTap: () {
          // Navigate to lead detail when available
          Navigator.pushNamed(context, '/all_leads');
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'live':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'lapsed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
