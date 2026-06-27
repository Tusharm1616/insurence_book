import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../utils/lucide_compat.dart';
import '../providers/reports_analytics_provider.dart';

class ReportsAnalyticsScreen extends ConsumerStatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  ConsumerState<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends ConsumerState<ReportsAnalyticsScreen> {
  late List<String> _months;

  @override
  void initState() {
    super.initState();
    _months = _generateLast12Months();
  }

  List<String> _generateLast12Months() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
  }

  String _formatMonthLabel(String yyyyMm) {
    final parts = yyyyMm.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMM yyyy').format(dt);
  }

  /// Format amount in Indian locale: ₹1,23,456
  String _formatIndianAmount(double amount) {
    if (amount == 0) return '₹0';
    final isNegative = amount < 0;
    final abs = amount.abs();
    final parts = abs.toStringAsFixed(0).split('.');
    final intPart = parts[0];

    if (intPart.length <= 3) {
      return '${isNegative ? '-' : ''}₹$intPart';
    }

    final last3 = intPart.substring(intPart.length - 3);
    var remaining = intPart.substring(0, intPart.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);

    return '${isNegative ? '-' : ''}₹${groups.join(',')},${last3}';
  }

  String _formatCompact(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  Future<void> _exportCsv() async {
    final policiesAsync = ref.read(reportsPoliciesProvider);
    List<ReportPolicy>? policies;
    policiesAsync.when(
      data: (d) => policies = d,
      loading: () {},
      error: (_, __) {},
    );
    if (policies == null || policies!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No policies to export'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final month = ref.read(selectedMonthProvider);
    final csv = StringBuffer();
    csv.writeln('Customer Name,Policy Number,Insurance Type,Company,Amount,Commission,Commission %,Payment Mode');
    for (final p in policies!) {
      csv.writeln(
        '"${p.customerName}","${p.policyNumber}","${p.insuranceType}","${p.insuranceCompany ?? ''}",${p.amount},${p.commission},${p.commissionPercent},"${p.paymentMode ?? ''}"',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/policies_report_$month.csv');
    await file.writeAsString(csv.toString());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'InsureBook Policies Report - $month'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final dashboardAsync = ref.watch(reportsDashboardProvider);
    final policiesAsync = ref.watch(reportsPoliciesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportCsv,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.share2, size: 20),
        label: const Text('Export'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reportsDashboardProvider);
            ref.invalidate(reportsPoliciesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Reports & Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppThemeHelper.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your business performance',
                  style: TextStyle(fontSize: 14, color: AppThemeHelper.textSecondary(context)),
                ),
                const SizedBox(height: 16),

                // Section 1: Month Selector
                _buildMonthSelector(selectedMonth),
                const SizedBox(height: 20),

                // Sections 2-6 depend on dashboard data
                dashboardAsync.when(
                  loading: () => _buildShimmerLoading(),
                  error: (err, _) => _buildError(err.toString()),
                  data: (dashboard) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 2: Summary Cards
                      _buildSummaryCards(dashboard),
                      const SizedBox(height: 20),

                      // Section 3: Sales Funnel
                      _buildSalesFunnel(dashboard),
                      const SizedBox(height: 20),

                      // Section 4: Business by Insurance Type
                      _buildInsuranceTypeChart(dashboard),
                      const SizedBox(height: 20),

                      // Section 5: 6-Month Trend
                      _buildTrendChart(dashboard),
                      const SizedBox(height: 20),

                      // Section 6: Policy List
                      _buildPolicyList(policiesAsync),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section 1: Month Selector ─────────────────────────────────────────────

  Widget _buildMonthSelector(String selected) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = _months[index];
          final isSelected = m == selected;
          return GestureDetector(
            onTap: () => ref.read(selectedMonthProvider.notifier).setMonth(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppThemeHelper.cardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppThemeHelper.borderColor(context),
                ),
              ),
              child: Text(
                _formatMonthLabel(m),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppThemeHelper.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section 2: Summary Cards ──────────────────────────────────────────────

  Widget _buildSummaryCards(ReportsDashboard data) {
    int conversionRate = 0;
    if (data.leadsTotal > 0) {
      conversionRate = ((data.saleComplete / data.leadsTotal) * 100).round();
      if (conversionRate > 100) conversionRate = 100; // Cap at 100%
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _summaryCard('Total Business', _formatIndianAmount(data.totalBusiness), LucideIcons.briefcase, AppColors.primary),
        _summaryCard('Total Income', _formatIndianAmount(data.totalIncome), LucideIcons.wallet, AppColors.info),
        _summaryCard('Policies Sold', data.policiesSold.toString(), LucideIcons.fileText, AppColors.amber),
        _summaryCard('Conversion Rate', '$conversionRate%', LucideIcons.trendingUp, AppColors.teal),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppThemeHelper.shadowColor(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  // ── Section 3: Sales Funnel ───────────────────────────────────────────────

  Widget _buildSalesFunnel(ReportsDashboard data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Funnel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _funnelItem('Leads', data.leadsTotal, AppColors.info),
              _funnelArrow(),
              _funnelItem('Converted', data.saleComplete, AppColors.primary),
              _funnelArrow(),
              _funnelItem('Pending', data.salePending, AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (data.saleComplete > 0)
                    Expanded(
                      flex: data.saleComplete,
                      child: Container(color: AppColors.primary),
                    ),
                  if (data.salePending > 0)
                    Expanded(
                      flex: data.salePending,
                      child: Container(color: AppColors.warning),
                    ),
                  if (data.saleComplete == 0 && data.salePending == 0)
                    Expanded(child: Container(color: Colors.grey.shade300)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppColors.primary, 'Complete: ${data.saleComplete}'),
              const SizedBox(width: 16),
              _legendDot(AppColors.warning, 'Pending: ${data.salePending}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _funnelItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: AppThemeHelper.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _funnelArrow() {
    return Icon(LucideIcons.chevronRight, size: 20, color: AppThemeHelper.textSecondary(context));
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppThemeHelper.textSecondary(context))),
      ],
    );
  }

  // ── Section 4: Insurance Type Bar Chart ───────────────────────────────────

  Widget _buildInsuranceTypeChart(ReportsDashboard data) {
    final types = data.byInsuranceType;
    if (types.isEmpty) {
      return _emptySection('Business by Type', 'No data for this month');
    }

    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.amber,
      AppColors.teal,
      AppColors.indigo,
      AppColors.danger,
      AppColors.warning,
    ];

    final maxAmount = types.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business by Insurance Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: types.length * 50.0 + 40,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${types[group.x.toInt()].type}\n${_formatCompact(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= types.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            types[idx].type.length > 6
                                ? '${types[idx].type.substring(0, 6)}..'
                                : types[idx].type,
                            style: TextStyle(fontSize: 10, color: AppThemeHelper.textSecondary(context)),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCompact(value),
                          style: TextStyle(fontSize: 9, color: AppThemeHelper.textSecondary(context)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAmount > 0 ? maxAmount / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppThemeHelper.borderColor(context),
                    strokeWidth: 0.5,
                  ),
                ),
                barGroups: List.generate(types.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: types[i].amount,
                        color: colors[i % colors.length],
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 5: 6-Month Trend Line Chart ───────────────────────────────────

  Widget _buildTrendChart(ReportsDashboard data) {
    final trend = data.monthlyTrend;
    if (trend.isEmpty) {
      return _emptySection('6-Month Trend', 'No trend data available');
    }

    final maxBusiness = trend.map((e) => e.business).fold(0.0, (a, b) => a > b ? a : b);
    final maxIncome = trend.map((e) => e.income).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = (maxBusiness > maxIncome ? maxBusiness : maxIncome) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6-Month Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppColors.primary, 'Business'),
              const SizedBox(width: 16),
              _legendDot(AppColors.info, 'Income'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                maxY: maxY > 0 ? maxY : 100,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final color = spot.barIndex == 0 ? AppColors.primary : AppColors.info;
                        final label = spot.barIndex == 0 ? 'Business' : 'Income';
                        return LineTooltipItem(
                          '$label: ${_formatCompact(spot.y)}',
                          TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppThemeHelper.borderColor(context),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= trend.length) return const SizedBox();
                        final parts = trend[idx].month.split('-');
                        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM').format(dt),
                            style: TextStyle(fontSize: 10, color: AppThemeHelper.textSecondary(context)),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCompact(value),
                          style: TextStyle(fontSize: 9, color: AppThemeHelper.textSecondary(context)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Business line (green)
                  LineChartBarData(
                    spots: List.generate(trend.length, (i) => FlSpot(i.toDouble(), trend[i].business)),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  // Income line (blue)
                  LineChartBarData(
                    spots: List.generate(trend.length, (i) => FlSpot(i.toDouble(), trend[i].income)),
                    isCurved: true,
                    color: AppColors.info,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.info.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 6: Policy List ────────────────────────────────────────────────

  Widget _buildPolicyList(AsyncValue<List<ReportPolicy>> policiesAsync) {
    return policiesAsync.when(
      loading: () => _shimmerList(),
      error: (err, _) => Text('Error loading policies: $err'),
      data: (policies) {
        if (policies.isEmpty) {
          return _emptySection('Policies', 'No policies for this month');
        }

        // Group by insurance type
        final grouped = <String, List<ReportPolicy>>{};
        for (final p in policies) {
          grouped.putIfAbsent(p.insuranceType, () => []).add(p);
        }

        return Container(
          decoration: BoxDecoration(
            color: AppThemeHelper.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Policies (${policies.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppThemeHelper.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatMonthLabel(ref.read(selectedMonthProvider)),
                      style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              ...grouped.entries.map((entry) => _buildTypeGroup(entry.key, entry.value)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeGroup(String type, List<ReportPolicy> policies) {
    return ExpansionTile(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${policies.length})',
            style: TextStyle(fontSize: 13, color: AppThemeHelper.textSecondary(context)),
          ),
        ],
      ),
      initiallyExpanded: true,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: policies.map((p) => _policyTile(p)).toList(),
    );
  }

  Widget _policyTile(ReportPolicy p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemeHelper.surfaceColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.customerName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppThemeHelper.textPrimary(context),
                    ),
                  ),
                ),
                Text(
                  _formatIndianAmount(p.amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  p.policyNumber,
                  style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context)),
                ),
                const Spacer(),
                Text(
                  'Commission: ${_formatIndianAmount(p.commission)}',
                  style: TextStyle(fontSize: 11, color: AppColors.info),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _emptySection(String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppThemeHelper.textPrimary(context))),
          const SizedBox(height: 12),
          Icon(LucideIcons.inbox, size: 40, color: AppThemeHelper.textSecondary(context)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13, color: AppThemeHelper.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(LucideIcons.wifiOff, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text('Failed to load reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppThemeHelper.textPrimary(context))),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context)), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(reportsDashboardProvider);
              ref.invalidate(reportsPoliciesProvider);
            },
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppThemeHelper.isDark(context) ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: AppThemeHelper.isDark(context) ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Column(
        children: [
          // Summary cards shimmer
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: List.generate(4, (_) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            )),
          ),
          const SizedBox(height: 20),
          // Funnel shimmer
          Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          const SizedBox(height: 20),
          // Chart shimmer
          Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          const SizedBox(height: 20),
          // Trend shimmer
          Container(height: 240, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
        ],
      ),
    );
  }

  Widget _shimmerList() {
    return Shimmer.fromColors(
      baseColor: AppThemeHelper.isDark(context) ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: AppThemeHelper.isDark(context) ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
        )),
      ),
    );
  }
}
