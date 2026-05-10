import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/vehicle_document_model.dart';
import '../../providers/vehicle_document_provider.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

class VehicleDocsScreen extends ConsumerStatefulWidget {
  const VehicleDocsScreen({super.key});

  @override
  ConsumerState<VehicleDocsScreen> createState() => _VehicleDocsScreenState();
}

class _VehicleDocsScreenState extends ConsumerState<VehicleDocsScreen> {
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
    final docsAsync    = ref.watch(vehicleDocsProvider);
    final summaryAsync = ref.watch(vehicleDocsSummaryProvider);

    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Vehicle Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(vehicleDocsProvider);
              ref.invalidate(vehicleDocsSummaryProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          summaryAsync.when(
            loading: () => Container(height: 110, color: AppColors.primary),
            error:   (e, st) => const SizedBox.shrink(),
            data:    (s) => _buildSummaryCards(s),
          ),
          _buildSearchBar(),
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error:   (e, _) => _buildError(e.toString()),
              data:    (docs) {
                var filtered = docs;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toUpperCase();
                  filtered = filtered.where((d) =>
                    d.vehicleNumber.contains(q) ||
                    (d.customerName ?? '').toUpperCase().contains(q) ||
                    d.vehicleModel.toUpperCase().contains(q)).toList();
                }
                if (_filterStatus != null) {
                  filtered = filtered.where((d) => d.overallStatus == _filterStatus).toList();
                }
                if (filtered.isEmpty) return _buildEmpty();
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(vehicleDocsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildVehicleCard(context, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
          );
          if (added == true) {
            ref.invalidate(vehicleDocsProvider);
            ref.invalidate(vehicleDocsSummaryProvider);
          }
        },
        backgroundColor: AppColors.primary,
        icon:  const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryCards(VehicleDocSummary s) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Row(children: [
            _chip('${s.total}',             'Total',         Colors.white, Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 6),
            _chip('${s.totalExpired}',      'Expired',       const Color(0xFFFFCDD2), const Color(0xFFB71C1C)),
            const SizedBox(width: 6),
            _chip('${s.totalExpiringSoon}', 'Expiring Soon', const Color(0xFFFFE0B2), const Color(0xFFE65100)),
            const SizedBox(width: 6),
            _chip('${s.totalValid}',        'Valid',         const Color(0xFFC8E6C9), const Color(0xFF2E7D32)),
          ]),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _docCard(LucideIcons.shield,    'Insurance', s.insuranceExpiring),
              _docCard(LucideIcons.leaf,      'PUC',       s.pucExpiring),
              _docCard(LucideIcons.creditCard,'RC',        s.rcExpiring),
              _docCard(LucideIcons.creditCard,'License',   s.licenseExpiring),
              _docCard(LucideIcons.fileCheck, 'Fitness',   s.fitnessExpiring),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _chip(String count, String label, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(count, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 17)),
          Text(label, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _docCard(IconData icon, String label, int count) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: count > 0 ? const Color(0xFFE65100) : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppThemeHelper.cardColor(context),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search vehicle no., model, customer…',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                    )
                  : null,
              filled: true,
              fillColor: AppThemeHelper.surfaceColor(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppThemeHelper.borderColor(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppThemeHelper.borderColor(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('All',           null,                AppColors.primary),
              _filterChip('Expired',       kStatusExpired,      const Color(0xFFB71C1C)),
              _filterChip('Expiring Soon', kStatusExpiringSoon, const Color(0xFFE65100)),
              _filterChip('Valid',         kStatusValid,        const Color(0xFF2E7D32)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? status, Color color) {
    final selected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = selected ? null : status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color:  selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : color)),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleDoc doc) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: doc.id)),
        );
        if (updated == true) {
          ref.invalidate(vehicleDocsProvider);
          ref.invalidate(vehicleDocsSummaryProvider);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppThemeHelper.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: doc.statusColor.withValues(alpha: 0.25)),
          boxShadow: AppThemeHelper.isDark(context) ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: doc.statusColor.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: doc.statusColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(_iconForType(doc.vehicleType), color: doc.statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(doc.vehicleNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppThemeHelper.textPrimary(context), letterSpacing: 1)),
                      Text('${doc.manufacturer} ${doc.vehicleModel}', style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context))),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: doc.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: doc.statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(doc.statusLabel, style: TextStyle(color: doc.statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Customer + doc badges
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                children: [
                  Row(children: [
                    Icon(LucideIcons.user, size: 13, color: AppThemeHelper.iconMuted(context)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(doc.customerName ?? 'No customer linked', style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context)))),
                    if (doc.customerMobile != null) ...[
                      Icon(LucideIcons.phone, size: 13, color: AppThemeHelper.iconMuted(context)),
                      const SizedBox(width: 4),
                      Text(doc.customerMobile!, style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context))),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _miniBadge('INS', doc.insurance),
                    const SizedBox(width: 5),
                    _miniBadge('PUC', doc.puc),
                    const SizedBox(width: 5),
                    _miniBadge('RC',  doc.rc),
                    const SizedBox(width: 5),
                    _miniBadge('DL',  doc.license),
                    const SizedBox(width: 5),
                    _miniBadge('FIT', doc.fitness),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String label, DocStatus status) {
    final color = status.isSet ? status.color : AppThemeHelper.iconMuted(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(LucideIcons.car, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty || _filterStatus != null ? 'No matching vehicles' : 'No Vehicles Added Yet',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppThemeHelper.textPrimary(context)),
        ),
        const SizedBox(height: 6),
        Text(
          _searchQuery.isNotEmpty || _filterStatus != null ? 'Try a different filter' : 'Tap + Add Vehicle to begin',
          style: TextStyle(color: AppThemeHelper.textSecondary(context), fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text('Failed to load', style: TextStyle(fontWeight: FontWeight.bold, color: AppThemeHelper.textPrimary(context))),
        const SizedBox(height: 4),
        Text(msg, style: const TextStyle(color: Colors.red, fontSize: 11)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => ref.invalidate(vehicleDocsProvider),
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'car':   return LucideIcons.car;
      case 'bike':  return Icons.two_wheeler;
      case 'truck': return Icons.local_shipping;
      case 'bus':   return Icons.directions_bus;
      default:      return LucideIcons.truck;
    }
  }
}
