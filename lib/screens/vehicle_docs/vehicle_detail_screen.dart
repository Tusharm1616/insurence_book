import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/lucide_compat.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/vehicle_document_model.dart';
import '../../providers/vehicle_document_provider.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final int vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  bool _sendingReminder = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(vehicleDocsProvider);
    return docsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error:   (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data:    (docs) {
        final doc = docs.where((d) => d.id == widget.vehicleId).firstOrNull;
        if (doc == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            body: const Center(child: Text('Vehicle not found')),
          );
        }
        return _buildScreen(context, doc);
      },
    );
  }

  Widget _buildScreen(BuildContext context, VehicleDoc doc) {
    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: Text(doc.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _deleting ? null : () => _confirmDelete(doc),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context, doc),
          const SizedBox(height: 16),
          _buildDocumentsCard(context, doc),
          const SizedBox(height: 16),
          _buildActionsCard(context, doc),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Vehicle Info Card ─────────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, VehicleDoc doc) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(_iconForType(doc.vehicleType), color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doc.vehicleNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2, color: AppThemeHelper.textPrimary(context))),
                  Text('${doc.manufacturer} ${doc.vehicleModel} • ${doc.fuelType}',
                    style: TextStyle(fontSize: 13, color: AppThemeHelper.textSecondary(context))),
                  if (doc.registrationYear != null)
                    Text('Registered: ${doc.registrationYear}', style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context))),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: doc.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: doc.statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(doc.statusLabel, style: TextStyle(color: doc.statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          if (doc.customerName != null || doc.customerMobile != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(LucideIcons.user, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (doc.customerName != null)
                    Text(doc.customerName!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppThemeHelper.textPrimary(context))),
                  if (doc.customerMobile != null)
                    Text(doc.customerMobile!, style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context))),
                ])),
                if (doc.customerMobile != null) ...[
                  IconButton(
                    onPressed: () => _callCustomer(doc.customerMobile!),
                    icon: const Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.1), shape: const CircleBorder()),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _openWhatsApp(doc.customerMobile!),
                    icon: const Icon(Icons.wechat, color: Color(0xFF25D366), size: 20),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1), shape: const CircleBorder()),
                  ),
                ],
              ]),
            ),
          if (doc.notes != null && doc.notes!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppThemeHelper.surfaceColor(context), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(LucideIcons.fileText, size: 14, color: AppThemeHelper.iconMuted(context)),
                const SizedBox(width: 8),
                Expanded(child: Text(doc.notes!, style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context)))),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Documents Status Card ─────────────────────────────────────────────
  Widget _buildDocumentsCard(BuildContext context, VehicleDoc doc) {
    final rows = [
      ('Vehicle Insurance', LucideIcons.shield,    doc.insurance, const Color(0xFFE65100)),
      ('PUC Certificate',   LucideIcons.leaf,      doc.puc,       const Color(0xFF9C27B0)),
      ('RC (Registration)', LucideIcons.creditCard,doc.rc,        const Color(0xFF1565C0)),
      ('Driving License',   LucideIcons.creditCard,    doc.license,   const Color(0xFF2E7D32)),
      ('Fitness Certificate',LucideIcons.fileCheck, doc.fitness,   const Color(0xFFF57F17)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(LucideIcons.fileText, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Document Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppThemeHelper.textPrimary(context))),
            ]),
          ),
          Divider(height: 1, color: AppThemeHelper.dividerColor(context)),
          ...rows.map((r) => _docRow(context, r.$1, r.$2, r.$3, r.$4, doc)),
        ],
      ),
    );
  }

  Widget _docRow(BuildContext context, String label, IconData icon, DocStatus status, Color accentColor, VehicleDoc doc) {
    final color = status.isSet ? status.color : AppThemeHelper.iconMuted(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withValues(alpha: 0.03),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: accentColor, size: 16),
        ),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppThemeHelper.textPrimary(context))),
        subtitle: Text(
          status.isSet ? '${_fmtDate(status.expiryDate!)}  •  ${status.daysLabel}' : 'Not set',
          style: TextStyle(fontSize: 11, color: AppThemeHelper.textSecondary(context)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status.label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        onTap: () => _showRenewalSheet(context, doc, label, status),
      ),
    );
  }

  // ── Actions Card ──────────────────────────────────────────────────────
  Widget _buildActionsCard(BuildContext context, VehicleDoc doc) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppThemeHelper.textPrimary(context))),
          ),
          Divider(height: 1, color: AppThemeHelper.dividerColor(context)),
          // WhatsApp Reminder
          ListTile(
            onTap: _sendingReminder ? null : () => _sendReminder(doc),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: _sendingReminder
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366)))
                  : const Icon(Icons.wechat, color: Color(0xFF25D366), size: 20),
            ),
            title: const Text('Send WhatsApp Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Notify customer about expiring docs', style: TextStyle(fontSize: 11, color: AppThemeHelper.textSecondary(context))),
            trailing: Icon(LucideIcons.chevronRight, size: 16, color: AppThemeHelper.iconMuted(context)),
          ),
          Divider(height: 1, color: AppThemeHelper.dividerColor(context), indent: 54),
          // Mark Renewed / Update
          ListTile(
            onTap: () => _showRenewalSheet(context, doc, 'All Documents', null),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(LucideIcons.calendarCheck, color: AppColors.primary, size: 20),
            ),
            title: const Text('Update Renewal Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Update a document\'s new expiry date', style: TextStyle(fontSize: 11, color: AppThemeHelper.textSecondary(context))),
            trailing: Icon(LucideIcons.chevronRight, size: 16, color: AppThemeHelper.iconMuted(context)),
          ),
          Divider(height: 1, color: AppThemeHelper.dividerColor(context), indent: 54),
          // Copy vehicle number
          ListTile(
            onTap: () {
              Clipboard.setData(ClipboardData(text: doc.vehicleNumber));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle number copied')));
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(LucideIcons.copy, color: Colors.blueGrey, size: 20),
            ),
            title: const Text('Copy Vehicle Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(doc.vehicleNumber, style: TextStyle(fontSize: 11, color: AppThemeHelper.textSecondary(context))),
            trailing: Icon(LucideIcons.chevronRight, size: 16, color: AppThemeHelper.iconMuted(context)),
          ),
        ],
      ),
    );
  }

  // ── Renewal Bottom Sheet ──────────────────────────────────────────────
  void _showRenewalSheet(BuildContext context, VehicleDoc doc, String label, DocStatus? current) {
    String? docType;
    DateTime? newDate;
    bool saving = false;

    final docTypes = ['insurance_expiry', 'puc_expiry', 'rc_expiry', 'license_expiry', 'fitness_expiry'];
    final docLabels = ['Insurance', 'PUC', 'RC', 'Driving License', 'Fitness'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeHelper.cardColor(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(LucideIcons.calendarCheck, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Update Renewal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppThemeHelper.textPrimary(ctx))),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(LucideIcons.x)),
                  ]),
                  const SizedBox(height: 16),

                  Text('Document Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppThemeHelper.textSecondary(ctx))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: docType,
                    hint: const Text('Select document type'),
                    items: List.generate(docTypes.length, (i) => DropdownMenuItem(value: docTypes[i], child: Text(docLabels[i]))).toList(),
                    onChanged: (v) => setSheetState(() => docType = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppThemeHelper.surfaceColor(ctx),
                      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppThemeHelper.borderColor(ctx))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppThemeHelper.borderColor(ctx))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    dropdownColor: AppThemeHelper.cardColor(ctx),
                  ),
                  const SizedBox(height: 14),

                  Text('New Expiry Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppThemeHelper.textSecondary(ctx))),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2040),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                          child: child!,
                        ),
                      );
                      if (d != null) setSheetState(() => newDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppThemeHelper.surfaceColor(ctx),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: newDate != null ? AppColors.primary : AppThemeHelper.borderColor(ctx)),
                      ),
                      child: Row(children: [
                        Icon(LucideIcons.calendarDays, color: newDate != null ? AppColors.primary : AppThemeHelper.iconMuted(ctx), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          newDate != null ? _fmtDate(newDate!) : 'Tap to select new expiry date',
                          style: TextStyle(color: newDate != null ? AppThemeHelper.textPrimary(ctx) : AppThemeHelper.textSecondary(ctx), fontSize: 14),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (docType == null || newDate == null || saving) ? null : () async {
                        setSheetState(() => saving = true);
                        final d = newDate!;
                        final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref.read(vehicleDocsProvider.notifier).updateVehicle(doc.id, {docType!: dateStr});
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(const SnackBar(content: Text('Renewal date updated!'), backgroundColor: AppColors.primary));
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        } finally {
                          setSheetState(() => saving = false);
                        }
                      },
                      icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.check, size: 16),
                      label: Text(saving ? 'Saving…' : 'Save Renewal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  Future<void> _sendReminder(VehicleDoc doc) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingReminder = true);
    try {
      final result = await ref.read(vehicleDocsProvider.notifier).sendReminder(doc.id);
      if (!mounted) return;
      final status = result['status'] as String;
      if (status == 'sent') {
        messenger.showSnackBar(
          const SnackBar(content: Text('✅ WhatsApp reminder sent!'), backgroundColor: AppColors.primary),
        );
      } else if (status == 'manual') {
        final msg = result['whatsapp_message'] as String? ?? '';
        final mobile = result['mobile'] as String? ?? '';
        _showManualReminderDialog(msg, mobile);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result['message'] as String? ?? 'No expiring documents'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _sendingReminder = false);
    }
  }

  void _showManualReminderDialog(String message, String mobile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeHelper.cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.wechat, color: Color(0xFF25D366)),
          const SizedBox(width: 8),
          const Text('Send Manually', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('WhatsApp API not configured. Copy and send this message manually to $mobile:', style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(ctx))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppThemeHelper.surfaceColor(ctx), borderRadius: BorderRadius.circular(8)),
            child: Text(message, style: TextStyle(fontSize: 12, color: AppThemeHelper.textPrimary(ctx))),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () { Clipboard.setData(ClipboardData(text: message)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied!'))); },
            child: const Text('Copy Message'),
          ),
          ElevatedButton.icon(
            onPressed: () { _openWhatsApp(mobile, message: message); Navigator.pop(ctx); },
            icon: const Icon(Icons.wechat, size: 16),
            label: const Text('Open WhatsApp'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(VehicleDoc doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeHelper.cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(LucideIcons.alertTriangle, color: Colors.red), SizedBox(width: 8), Text('Delete Vehicle', style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Text('Delete ${doc.vehicleNumber}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _deleting = true);
      try {
        await ref.read(vehicleDocsProvider.notifier).deleteVehicle(doc.id);
        if (mounted) navigator.pop(true);
      } catch (e) {
        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _deleting = false);
      }
    }
  }

  void _callCustomer(String mobile) async {
    final clean = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _openWhatsApp(String mobile, {String? message}) async {
    final clean = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final num   = clean.startsWith('91') ? clean : '91$clean';
    final msg   = Uri.encodeComponent(message ?? '');
    final url   = Uri.parse('whatsapp://send?phone=$num&text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
