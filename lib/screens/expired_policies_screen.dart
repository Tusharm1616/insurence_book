import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/expired_policies_provider.dart';

class ExpiredPoliciesScreen extends ConsumerStatefulWidget {
  const ExpiredPoliciesScreen({super.key});

  @override
  ConsumerState<ExpiredPoliciesScreen> createState() => _ExpiredPoliciesScreenState();
}

class _ExpiredPoliciesScreenState extends ConsumerState<ExpiredPoliciesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(expiredPoliciesListProvider.notifier).fetchInitial());

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(expiredPoliciesListProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expiredPoliciesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expired Policies', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => ref.read(expiredPoliciesListProvider.notifier).fetchInitial(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ExpiredPoliciesState state) {
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
              onPressed: () => ref.read(expiredPoliciesListProvider.notifier).fetchInitial(),
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
            Icon(LucideIcons.shieldCheck, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'No expired policies!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All your policies are currently active.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
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

  Widget _buildPolicyCard(ExpiredPolicy policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: const Border(left: BorderSide(color: Colors.red, width: 6)),
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
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Expired ${policy.daysOverdue}d ago',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.shield, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(policy.policyType, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.hash, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      policy.policyNumber,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Insurer: ${policy.insurerName ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    'Premium: ₹${policy.premiumAmount?.toStringAsFixed(0) ?? '0'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.calendarX, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Expired on: ${policy.expiryDate ?? 'N/A'}',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
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
                  Container(width: 100, height: 24, color: Colors.white),
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
              Container(width: 160, height: 30, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
