import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../providers/life_policy_list_provider.dart';

class LifePolicyListScreen extends ConsumerStatefulWidget {
  final String filter;
  final String title;
  final Color themeColor;

  const LifePolicyListScreen({
    super.key,
    required this.filter,
    required this.title,
    required this.themeColor,
  });

  @override
  ConsumerState<LifePolicyListScreen> createState() => _LifePolicyListScreenState();
}

class _LifePolicyListScreenState extends ConsumerState<LifePolicyListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(lifePoliciesListProvider(widget.filter).notifier).fetchMore();
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
    final state = ref.watch(lifePoliciesListProvider(widget.filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => ref.read(lifePoliciesListProvider(widget.filter).notifier).fetchInitial(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(LifePoliciesState state) {
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
              onPressed: () => ref.read(lifePoliciesListProvider(widget.filter).notifier).fetchInitial(),
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
            Icon(LucideIcons.fileMinus, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No policies found in this category.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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

  Widget _buildPolicyCard(LifePolicy policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: widget.themeColor, width: 6)),
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
                      color: widget.themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      policy.status.toUpperCase(),
                      style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 10),
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
              if (policy.maturityDate != null) ...[
                const SizedBox(height: 4),
                Text('Maturity: ${policy.maturityDate}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
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
                  Container(width: 60, height: 20, color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }
}
