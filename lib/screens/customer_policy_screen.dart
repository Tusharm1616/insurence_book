import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/policy_model.dart';
import '../providers/policy_provider.dart';

// ── Status badge config ───────────────────────────────────────────────────
const _statusConfig = {
  'active':        {'label': 'ACTIVE',        'color': 0xFF2E7D32, 'icon': Icons.check_circle},
  'expiring_soon': {'label': 'EXPIRING SOON', 'color': 0xFFE65100, 'icon': Icons.timer_outlined},
  'expired':       {'label': 'EXPIRED',       'color': 0xFFB71C1C, 'icon': Icons.cancel},
  'premium_due':   {'label': 'PREMIUM DUE',   'color': 0xFFF57F17, 'icon': Icons.payment},
  'overdue':       {'label': 'OVERDUE',       'color': 0xFFD32F2F, 'icon': Icons.warning_amber},
  'lapsed':        {'label': 'LAPSED',        'color': 0xFF616161, 'icon': Icons.remove_circle_outline},
  'matured':       {'label': 'MATURED',       'color': 0xFF00695C, 'icon': Icons.verified},
  'renewed':       {'label': 'RENEWED',       'color': 0xFF1565C0, 'icon': Icons.autorenew},
  'cancelled':     {'label': 'CANCELLED',     'color': 0xFF4E342E, 'icon': Icons.block},
  'pending':       {'label': 'PENDING',       'color': 0xFF37474F, 'icon': Icons.hourglass_empty},
};

Map<String, dynamic> _configFor(String status) =>
    _statusConfig[status.toLowerCase()] ??
    {'label': status.toUpperCase(), 'color': 0xFF37474F, 'icon': Icons.info_outline};

class CustomerPolicyScreen extends ConsumerStatefulWidget {
  final int? customerId;
  final String? customerName;

  const CustomerPolicyScreen({super.key, this.customerId, this.customerName});

  @override
  ConsumerState<CustomerPolicyScreen> createState() =>
      _CustomerPolicyScreenState();
}

class _CustomerPolicyScreenState extends ConsumerState<CustomerPolicyScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPolicies = ref.watch(policyProvider);
    var policies = widget.customerId != null
        ? allPolicies.where((p) => p.customerId == widget.customerId).toList()
        : allPolicies;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      policies = policies.where((p) {
        return p.policyNumber.toLowerCase().contains(q) ||
            p.policyType.toLowerCase().contains(q) ||
            p.insuranceCompany.toLowerCase().contains(q) ||
            (p.customerName ?? '').toLowerCase().contains(q) ||
            p.statusLabel.toLowerCase().contains(q);
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != null) {
      policies = policies
          .where((p) => p.resolvedStatus == _filterStatus)
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          widget.customerName != null
              ? '${widget.customerName!}\'s Policies'
              : 'All Policies',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Policy count badge
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${policies.length} ${policies.length == 1 ? 'Policy' : 'Policies'}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(allPolicies),
          Expanded(
            child: policies.isEmpty
                ? _buildEmpty(context)
                : RefreshIndicator(
                    color: const Color(0xFF1B5E20),
                    onRefresh: () async {
                      ref.invalidate(policyProvider);
                      await Future.delayed(const Duration(milliseconds: 400));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: policies.length,
                      itemBuilder: (context, index) =>
                          _buildPolicyCard(context, policies[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_policy'),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Search + Filter bar ─────────────────────────────────────────────────
  Widget _buildSearchAndFilter(List<Policy> allPolicies) {
    final statusCounts = <String, int>{};
    for (final p in allPolicies) {
      statusCounts[p.resolvedStatus] =
          (statusCounts[p.resolvedStatus] ?? 0) + 1;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search policy no., company, type…',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Status filter chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All', null, statusCounts.values.fold(0, (a, b) => a + b)),
                ...( statusCounts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .map((e) => _filterChip(e.key, e.key, e.value)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? status, int count) {
    final selected = _filterStatus == status;
    final cfg = status != null ? _configFor(status) : null;
    final color = cfg != null ? Color(cfg['color'] as int) : const Color(0xFF1B5E20);
    final displayLabel = cfg != null ? (cfg['label'] as String) : 'ALL';

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = selected ? null : status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.shieldOff, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != null
                ? 'No matching policies found'
                : 'No Policies Yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != null
                ? 'Try adjusting your search or filter'
                : 'Add your first policy using the button below',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          if (_searchQuery.isEmpty && _filterStatus == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add_policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add First Policy', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Policy Card ─────────────────────────────────────────────────────────
  Widget _buildPolicyCard(BuildContext context, Policy policy) {
    final resolvedStatus = policy.resolvedStatus;
    final cfg = _configFor(resolvedStatus);
    final statusColor = Color(cfg['color'] as int);
    final statusLabel = cfg['label'] as String;
    final statusIcon = cfg['icon'] as IconData;
    final policyIcon = _iconForType(policy.policyType);
    final policyColor = _colorForType(policy.policyType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: policyColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: policyColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(policyIcon, color: policyColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.policyType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        policy.policyNumber.isNotEmpty
                            ? policy.policyNumber
                            : 'No Policy Number',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Details ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Company row
                _detailRow(
                  LucideIcons.building2,
                  'Insurance Company',
                  policy.insuranceCompany.isNotEmpty
                      ? policy.insuranceCompany
                      : '—',
                ),
                const SizedBox(height: 10),

                // Sum insured + premium
                Row(
                  children: [
                    Expanded(
                      child: _amountBox(
                        icon: LucideIcons.indianRupee,
                        label: 'Sum Insured',
                        amount: policy.sumInsured,
                        color: policyColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _amountBox(
                        icon: LucideIcons.creditCard,
                        label: 'Premium/yr',
                        amount: policy.premium,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),

                // Dates row
                Row(
                  children: [
                    Expanded(child: _dateBox('Start Date', policy.startDate, Colors.blue.shade700)),
                    const SizedBox(width: 10),
                    Expanded(child: _dateBox('Expiry Date', policy.expiryDate, statusColor)),
                  ],
                ),

                // Nominee row (only when present)
                if (policy.hasNominee) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.users, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Nominee: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            policy.effectiveNomineeName +
                                (policy.effectiveNomineeRelation.isNotEmpty
                                    ? ' (${policy.effectiveNomineeRelation})'
                                    : ''),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Alert banners
                if (resolvedStatus == 'expired') ...[
                  const SizedBox(height: 10),
                  _alertBanner(
                    icon: LucideIcons.alertTriangle,
                    color: const Color(0xFFB71C1C),
                    bgColor: const Color(0xFFFFEBEE),
                    borderColor: const Color(0xFFEF9A9A),
                    text: 'Expired ${policy.daysToExpiry.abs()} day(s) ago — Please renew!',
                  ),
                ] else if (resolvedStatus == 'expiring_soon') ...[
                  const SizedBox(height: 10),
                  _alertBanner(
                    icon: LucideIcons.clock,
                    color: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                    borderColor: const Color(0xFFFFCC80),
                    text: 'Expiring in ${policy.daysToExpiry} day(s) — Renewal due soon!',
                  ),
                ] else if (resolvedStatus == 'premium_due') ...[
                  const SizedBox(height: 10),
                  _alertBanner(
                    icon: LucideIcons.alertCircle,
                    color: const Color(0xFFF57F17),
                    bgColor: const Color(0xFFFFFDE7),
                    borderColor: const Color(0xFFFFE082),
                    text: 'Premium payment is due — Please pay immediately!',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertBanner({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: [
              Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountBox({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: color)),
                Text(
                  amount > 0 ? '₹${_formatAmount(amount)}' : '—',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: amount > 0 ? Colors.black87 : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, DateTime date, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  IconData _iconForType(String type) {
    if (type.contains('Health')) return LucideIcons.activity;
    if (type.contains('Motor')) return LucideIcons.car;
    if (type.contains('Life')) return LucideIcons.heart;
    if (type.contains('Travel')) return LucideIcons.plane;
    if (type.contains('Home')) return LucideIcons.home;
    if (type.contains('Business')) return LucideIcons.building;
    if (type.contains('Shop') || type.contains('Commercial')) return LucideIcons.store;
    if (type.contains('Two Wheeler') || type.contains('Wheeler')) return Icons.two_wheeler;
    if (type.contains('Accident')) return Icons.local_hospital;
    if (type.contains('Term')) return LucideIcons.shieldCheck;
    if (type.contains('WC')) return LucideIcons.briefcase;
    return LucideIcons.shield;
  }

  Color _colorForType(String type) {
    if (type.contains('Health')) return Colors.green;
    if (type.contains('Motor')) return Colors.orange;
    if (type.contains('Life')) return Colors.pink;
    if (type.contains('Travel')) return Colors.blue;
    if (type.contains('Home')) return Colors.amber.shade700;
    if (type.contains('Business')) return Colors.indigo;
    if (type.contains('Shop') || type.contains('Commercial')) return Colors.deepOrange;
    if (type.contains('Two Wheeler') || type.contains('Wheeler')) return Colors.purple;
    if (type.contains('Accident')) return Colors.redAccent;
    if (type.contains('Term')) return Colors.teal;
    if (type.contains('WC')) return Colors.purple.shade700;
    return Colors.blueGrey;
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
