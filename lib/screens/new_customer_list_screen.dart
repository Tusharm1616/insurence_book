import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../providers/customers_provider.dart';
import '../widgets/shimmer_widget.dart';
import 'customer_detail_screen.dart';

class NewCustomerListScreen extends ConsumerStatefulWidget {
  final String filter;
  final String title;

  const NewCustomerListScreen({
    super.key,
    required this.filter,
    required this.title,
  });

  @override
  ConsumerState<NewCustomerListScreen> createState() =>
      _NewCustomerListScreenState();
}

class _NewCustomerListScreenState
    extends ConsumerState<NewCustomerListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier)
        ..setFilter(widget.filter)
        ..fetchCustomers(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await ref.read(customersProvider.notifier).loadMoreCustomers();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(customersProvider.notifier)
                    .fetchCustomers(refresh: true);
              },
              child: customersAsync.when(
                data: (response) => response.data.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomerList(response),
                loading: () => _buildLoadingState(),
                error: (err, _) => _buildErrorState(err.toString()),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create_customer'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Customer',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or phone…',
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          ref.read(customersProvider.notifier).setSearchQuery(val);
        },
      ),
    );
  }

  Widget _buildCustomerList(CustomerListResponse response) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: response.data.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == response.data.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildCustomerCard(response.data[index]);
      },
    );
  }

  Widget _buildCustomerCard(CustomerData customer) {
    final initials = customer.fullName.trim().isEmpty
        ? 'C'
        : customer.fullName
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join();

    final expiryColor = _getExpiryColor(customer.latestPolicyEndDate);
    final expiryText = _getExpiryText(customer.latestPolicyEndDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CustomerDetailScreen(customerId: customer.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppColors.info.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1C),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (customer.phone.isNotEmpty)
                          Text(
                            customer.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        if (customer.email.isNotEmpty)
                          Text(
                            customer.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        if (customer.city.isNotEmpty)
                          Text(
                            customer.city,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Poppins',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(
                    customer.status == 'active' ? 'Active' : 'Inactive',
                    customer.status == 'active' ? Colors.green : Colors.grey,
                  ),
                  _chip(
                    '${customer.totalPolicies} Policies',
                    AppColors.info,
                  ),
                  if (customer.activePolicies > 0)
                    _chip(
                      '${customer.activePolicies} Active',
                      AppColors.primary,
                    ),
                ],
              ),
              if (expiryText != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Policy expires: $expiryText',
                  style: TextStyle(
                    fontSize: 12,
                    color: expiryColor,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Color _getExpiryColor(String latestEndDate) {
    if (latestEndDate.isEmpty) return Colors.grey;
    try {
      final date = DateTime.parse(latestEndDate);
      final diff = date.difference(DateTime.now()).inDays;
      if (diff < 0) return Colors.red;
      if (diff <= 30) return Colors.orange;
      if (diff <= 60) return Colors.amber.shade700;
      return Colors.green;
    } catch (_) {
      return Colors.grey;
    }
  }

  String? _getExpiryText(String latestEndDate) {
    if (latestEndDate.isEmpty) return null;
    try {
      final date = DateTime.parse(latestEndDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return null;
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerWidget(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.danger,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () =>
                ref.read(customersProvider.notifier).fetchCustomers(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
