import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../core/app_theme.dart';
import '../providers/policies_provider.dart';
import '../widgets/shimmer_widget.dart';

class PolicyListScreen extends ConsumerStatefulWidget {
  const PolicyListScreen({super.key});

  @override
  ConsumerState<PolicyListScreen> createState() => _PolicyListScreenState();
}

class _PolicyListScreenState extends ConsumerState<PolicyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch policies when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final filter = args?['filter'] as String? ?? 'all';
      ref.read(policiesProvider.notifier).setFilter(filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final policiesAsync = ref.watch(policiesProvider);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final filter = args?['filter'] as String? ?? 'all';
    final title = args?['title'] as String? ?? 'All Policies';
    
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: _SearchDelegate(ref));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(policiesProvider.notifier).refreshPolicies();
        },
        child: policiesAsync.when(
          data: (response) => _buildPolicyList(context, response.data, filter),
          loading: () => _buildLoadingState(),
          error: (error) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildPolicyList(BuildContext context, List<dynamic> policies, String filter) {
    if (policies.isEmpty) {
      return _buildEmptyState(context, filter);
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: policies.length,
      itemBuilder: (context, index) {
        final policy = policies[index];
        return _buildPolicyCard(context, policy);
      },
    );
  }

  Widget _buildPolicyCard(BuildContext context, dynamic policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: policy number and type chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    policy['policy_number'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1C),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPolicyTypeColor(policy['policy_type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    policy['policy_type'] ?? '',
                    style: TextStyle(
                      color: _getPolicyTypeColor(policy['policy_type']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Customer info
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 8),
                Text(
                  policy['customer']['full_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.phone,
                  size: 16,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 8),
                Text(
                  policy['customer']['phone'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Insurer and plan
            Text(
              '${policy['insurer_name'] ?? ''} — ${policy['plan_name'] ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Sum insured and premium
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sum Insured: ₹${_formatCurrency(policy['sum_insured'])}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1C1C1C),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium: ₹${_formatCurrency(policy['premium_amount'])}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1C1C1C),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Period
            Text(
              'Period: ${_formatDate(policy['start_date'])} → ${_formatDate(policy['end_date'])}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Bottom row: status and days badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPolicyStatusColor(policy['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    policy['status'] ?? '',
                    style: TextStyle(
                      color: _getPolicyStatusColor(policy['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                
                // Days badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDaysRemainingColor(policy['days_remaining']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDaysRemainingText(policy['days_remaining']),
                    style: TextStyle(
                      color: _getDaysRemainingColor(policy['days_remaining']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    String emptyMessage;
    IconData emptyIcon;
    
    switch (filter) {
      case 'expired':
        emptyMessage = 'No expired policies';
        emptyIcon = Icons.warning_amber_outlined;
        break;
      case 'expiring_1m':
        emptyMessage = 'No policies expiring this month';
        emptyIcon = Icons.calendar_month_outlined;
        break;
      case 'expiring_2m':
        emptyMessage = 'No policies expiring in 2 months';
        emptyIcon = Icons.calendar_today_outlined;
        break;
      case 'active':
        emptyMessage = 'No active policies';
        emptyIcon = Icons.shield_outlined;
        break;
      case 'all':
      default:
        emptyMessage = 'No policies added yet';
        emptyIcon = Icons.shield_outlined;
        break;
    }
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 64,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
                fontFamily: 'Poppins',
              ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const ShimmerWidget();
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.dangerColor,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.dangerColor,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(policiesProvider.notifier).refreshPolicies();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+$'),
      (match) => '${match[1]}${match[2] != null ? ',' : ''}${match[2] ?? ''}',
    );
  }

  Color _getPolicyTypeColor(String? policyType) {
    if (policyType == null) return Colors.grey;
    
    switch (policyType.toLowerCase()) {
      case 'motor':
        return Colors.blue;
      case 'health':
        return Colors.green;
      case 'life':
        return Colors.purple;
      case 'term':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPolicyStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'lapsed':
        return Colors.orange;
      case 'paidup':
        return Colors.purple;
      case 'matured':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getDaysRemainingColor(int? daysRemaining) {
    if (daysRemaining == null) return Colors.grey;
    
    if (daysRemaining < 0) {
      return Colors.red; // Expired
    } else if (daysRemaining <= 30) {
      return Colors.orange; // Expiring within 30 days
    } else if (daysRemaining <= 60) {
      return Colors.amber; // Expiring within 60 days
    } else {
      return Colors.green; // More than 60 days
    }
  }

  String _getDaysRemainingText(int? daysRemaining) {
    if (daysRemaining == null) return 'N/A';
    
    if (daysRemaining < 0) {
      return 'Expired ${daysRemaining.abs()} days ago';
    } else if (daysRemaining == 0) {
      return 'Expires Today';
    } else {
      return '${daysRemaining} days left';
    }
  }
}

class _SearchDelegate extends SearchDelegate<String> {
  final Ref ref;

  _SearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          close(context, null);
        },
        tooltip: 'Clear search',
      ),
    ];
  }

  @override
  Widget buildResults(BuildContext context, List<String> suggestions) {
    return Container();
  }

  @override
  Widget buildLeading(BuildContext context) {
    return const Icon(Icons.search);
  }

  @override
  Widget buildSuggestions(BuildContext context, TextEditingController controller) {
    return Container();
  }
}
