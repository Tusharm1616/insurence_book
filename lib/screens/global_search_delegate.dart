import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

// ── Search result models ──────────────────────────────────────────────────────

class _CustomerResult {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String status;
  final int totalPolicies;

  _CustomerResult({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.status,
    required this.totalPolicies,
  });

  factory _CustomerResult.fromJson(Map<String, dynamic> j) => _CustomerResult(
        id: j['id']?.toString() ?? '',
        fullName: j['full_name'] ?? '',
        phone: j['phone'] ?? '',
        email: j['email'] ?? '',
        city: j['city'] ?? '',
        status: j['status'] ?? 'active',
        totalPolicies: j['total_policies'] ?? 0,
      );
}

class _PolicyResult {
  final String id;
  final String policyNumber;
  final String policyType;
  final String insurerName;
  final String planName;
  final double sumInsured;
  final double premiumAmount;
  final String startDate;
  final String endDate;
  final String status;
  final int daysRemaining;
  final String customerName;
  final String customerPhone;
  final String customerId;

  _PolicyResult({
    required this.id,
    required this.policyNumber,
    required this.policyType,
    required this.insurerName,
    required this.planName,
    required this.sumInsured,
    required this.premiumAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.daysRemaining,
    required this.customerName,
    required this.customerPhone,
    required this.customerId,
  });

  factory _PolicyResult.fromJson(Map<String, dynamic> j) => _PolicyResult(
        id: j['id']?.toString() ?? '',
        policyNumber: j['policy_number'] ?? '',
        policyType: j['policy_type'] ?? '',
        insurerName: j['insurer_name'] ?? '',
        planName: j['plan_name'] ?? '',
        sumInsured: (j['sum_assured'] ?? j['sum_insured'] ?? 0.0).toDouble(),
        premiumAmount: (j['premium_amount'] ?? 0.0).toDouble(),
        startDate: j['start_date'] ?? j['issue_date'] ?? '',
        endDate: j['end_date'] ?? j['expiry_date'] ?? '',
        status: j['status'] ?? '',
        daysRemaining: j['days_remaining'] ?? 0,
        customerName: j['customer']?['full_name'] ?? 'Unknown',
        customerPhone: j['customer']?['phone'] ?? '',
        customerId: j['customer']?['id']?.toString() ?? '',
      );
}

// ── Search provider ───────────────────────────────────────────────────────────

class _SearchState {
  final List<_CustomerResult> customers;
  final List<_PolicyResult> policies;
  final String? error;

  const _SearchState({
    this.customers = const [],
    this.policies = const [],
    this.error,
  });
}

final _searchResultsProvider =
    FutureProvider.family<_SearchState, String>((ref, query) async {
  if (query.trim().length < 2) return const _SearchState();

  try {
    final q = query.trim();

    // Fetch customers and policies in parallel
    final results = await Future.wait([
      apiService.dio.get('/api/customers/', queryParameters: {
        'search': q,
        'limit': 20,
        'page': 1,
      }),
      apiService.dio.get('/api/policies/', queryParameters: {
        'search': q,
        'limit': 20,
        'page': 1,
        'filter': 'all',
      }),
    ]);

    final customers = (results[0].data['data'] as List? ?? [])
        .map((e) => _CustomerResult.fromJson(e as Map<String, dynamic>))
        .toList();

    final policies = (results[1].data['data'] as List? ?? [])
        .map((e) => _PolicyResult.fromJson(e as Map<String, dynamic>))
        .toList();

    return _SearchState(customers: customers, policies: policies);
  } catch (e) {
    return _SearchState(error: e.toString());
  }
});

// ── Delegate ──────────────────────────────────────────────────────────────────

class GlobalSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  GlobalSearchDelegate(this.ref)
      : super(searchFieldLabel: 'Search by name, policy no, phone…');

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
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
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: Colors.white),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white),
            onPressed: () {
              query = '';
              showSuggestions(context);
            },
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    if (query.trim().length < 2) {
      return _emptyPrompt();
    }
    final async = ref.watch(_searchResultsProvider(query.trim()));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _noResults(query),
      data: (state) {
        if (state.customers.isEmpty && state.policies.isEmpty) {
          return _noResults(query);
        }
        return _results(context, state);
      },
    );
  }

  Widget _emptyPrompt() {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Search CRM',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            const Text('Search by name, policy no, phone or vehicle no.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _noResults(String q) {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileSearch, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No Results Found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            Text('No matches for "$q"',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context, _SearchState state) {
    return Container(
      color: Colors.grey.shade50,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Customers section ──────────────────────────────────────────
          if (state.customers.isNotEmpty) ...[
            _sectionHeader(
                context, LucideIcons.users, 'Customers', state.customers.length),
            ...state.customers.map((c) => _customerCard(context, c)),
            const SizedBox(height: 8),
          ],

          // ── Policies section ───────────────────────────────────────────
          if (state.policies.isNotEmpty) ...[
            _sectionHeader(
                context, LucideIcons.shield, 'Policies', state.policies.length),
            ...state.policies.map((p) => _policyCard(context, p)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, IconData icon, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Customer card ─────────────────────────────────────────────────────────
  Widget _customerCard(BuildContext context, _CustomerResult c) {
    final initials = c.fullName.trim().isEmpty
        ? 'C'
        : c.fullName
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          close(context, '');
          Navigator.pushNamed(context, '/customer_detail',
              arguments: {'customerId': c.id});
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.info.withValues(alpha: 0.15),
                child: Text(initials,
                    style: const TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    if (c.phone.isNotEmpty)
                      Text(c.phone,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    if (c.email.isNotEmpty)
                      Text(c.email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _chip(
                          c.status == 'active' ? 'Active' : 'Inactive',
                          c.status == 'active' ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        _chip('${c.totalPolicies} Policies', AppColors.info),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ── Policy card ───────────────────────────────────────────────────────────
  Widget _policyCard(BuildContext context, _PolicyResult p) {
    final statusColor = _statusColor(p.status, p.daysRemaining);
    final daysText = _daysText(p.daysRemaining);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          close(context, '');
          if (p.customerId.isNotEmpty) {
            Navigator.pushNamed(context, '/customer_detail',
                arguments: {'customerId': p.customerId});
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.shield,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.policyNumber.isNotEmpty
                              ? p.policyNumber
                              : 'No Policy #',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${p.customerName}  •  ${p.policyType}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _chip(p.policyType, _typeColor(p.policyType)),
                ],
              ),
              const SizedBox(height: 10),
              // Details row
              Row(
                children: [
                  Expanded(
                    child: _detailItem(
                        'Insurer', p.insurerName.isNotEmpty ? p.insurerName : 'N/A'),
                  ),
                  Expanded(
                    child: _detailItem(
                        'Premium', '₹${_fmt(p.premiumAmount)}'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _detailItem(
                        'Sum Insured', '₹${_fmt(p.sumInsured)}'),
                  ),
                  Expanded(
                    child: _detailItem(
                        'Expiry', _fmtDate(p.endDate)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Status + days
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _chip(p.status.toUpperCase(), statusColor),
                  _chip(daysText, statusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _statusColor(String status, int days) {
    if (days < 0) return Colors.red;
    if (days <= 30) return Colors.orange;
    if (days <= 60) return Colors.amber.shade700;
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

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'motor':
        return Colors.blue;
      case 'health':
        return Colors.green;
      case 'life':
        return Colors.purple;
      case 'term':
        return Colors.orange;
      case 'travel':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _daysText(int days) {
    if (days < 0) return 'Expired ${days.abs()}d ago';
    if (days == 0) return 'Expires Today';
    return '$days days left';
  }

  String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]},');

  String _fmtDate(String d) {
    if (d.isEmpty) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }
}
