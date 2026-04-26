import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../providers/expiring_policies_provider.dart';

class ExpiringPoliciesScreen extends ConsumerStatefulWidget {
  final int days;
  final String title;

  const ExpiringPoliciesScreen({
    super.key,
    required this.days,
    required this.title,
  });

  @override
  ConsumerState<ExpiringPoliciesScreen> createState() => _ExpiringPoliciesScreenState();
}

class _ExpiringPoliciesScreenState extends ConsumerState<ExpiringPoliciesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(expiringPoliciesProvider.notifier).fetchInitial(widget.days));
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(expiringPoliciesProvider.notifier).fetchMore(widget.days);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getBorderColor(int daysRemaining) {
    if (daysRemaining <= 7) return const Color(0xFFF44336); // Red
    if (daysRemaining <= 30) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFFFC107); // Amber
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expiringPoliciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => ref.read(expiringPoliciesProvider.notifier).fetchInitial(widget.days),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ExpiringPoliciesState state) {
    if (state.isLoading && state.policies.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (state.error != null && state.policies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(expiringPoliciesProvider.notifier).fetchInitial(widget.days),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.policies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No expiring policies found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.policies.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.policies.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final policy = state.policies[index];
        return _buildPolicyCard(policy);
      },
    );
  }

  Widget _buildPolicyCard(ExpiringPolicy policy) {
    final borderColor = _getBorderColor(policy.daysRemaining);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 6)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      policy.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${policy.daysRemaining} days left',
                      style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Policy No: ${policy.policyNumber}', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Insurer: ${policy.insurerName ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  Text('Premium: ₹${policy.premiumAmount ?? 0}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Expiry: ${policy.expiryDate ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 150, height: 16, color: Colors.white),
                  Container(width: 80, height: 24, color: Colors.white),
                ],
              ),
              const SizedBox(height: 12),
              Container(width: 200, height: 14, color: Colors.white),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 120, height: 14, color: Colors.white),
                  Container(width: 80, height: 14, color: Colors.white),
                ],
              ),
              const SizedBox(height: 8),
              Container(width: 100, height: 14, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
