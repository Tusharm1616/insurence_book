import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/life_policy_list_provider.dart';
import 'life_policy_detail_screen.dart';

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
    Future.microtask(() => ref.read(lifePoliciesListProvider.notifier).fetchInitial(widget.filter));
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(lifePoliciesListProvider.notifier).fetchMore(widget.filter);
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
    final state = ref.watch(lifePoliciesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => ref.read(lifePoliciesListProvider.notifier).fetchInitial(widget.filter),
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
              onPressed: () => ref.read(lifePoliciesListProvider.notifier).fetchInitial(widget.filter),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Text('${state.policies.length} policies found', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard(LifePolicy policy) {
    int daysUntilExpiry = 0;
    bool isExpiringSoon = false;
    
    if (policy.premiumDueDate != null) {
      try {
        final dueDate = DateTime.parse(policy.premiumDueDate!);
        daysUntilExpiry = dueDate.difference(DateTime.now()).inDays;
        isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
      } catch (e) {
        // format error
      }
    }

    String sumAssuredStr = policy.sumAssured != null ? '₹${(policy.sumAssured! / 100000).toStringAsFixed(0)}L' : 'N/A';
    String premiumStr = policy.premiumAmount != null ? '₹${policy.premiumAmount!.toStringAsFixed(0)}/yr' : 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LifePolicyDetailScreen(policy: policy)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: widget.themeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(LucideIcons.heart, color: widget.themeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(policy.policyNumber, style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(policy.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: widget.themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(policy.status, style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(height: 4),
                      const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 18),
                    ],
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              
              // Details Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(LucideIcons.shield, policy.insurerName ?? 'N/A'),
                        const SizedBox(height: 8),
                        _detailRow(LucideIcons.calendar, 'Due: ${policy.premiumDueDate ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        _detailRow(LucideIcons.award, 'Sum Assured: $sumAssuredStr'),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(LucideIcons.phone, policy.customerPhone),
                        const SizedBox(height: 8),
                        _detailRow(LucideIcons.dollarSign, premiumStr),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Alert Banner
              if (isExpiringSoon || policy.status.toLowerCase() == 'lapsed') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        policy.status.toLowerCase() == 'lapsed' 
                          ? 'Policy has lapsed — Action needed'
                          : 'Expires in $daysUntilExpiry days — Renewal needed',
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13))),
      ],
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
