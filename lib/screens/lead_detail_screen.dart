import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/lucide_compat.dart';
import '../core/theme.dart';
import '../providers/lead_provider.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  late Lead _lead;
  bool _isConverting = false;
  bool _isUpdating = false;
  late LeadStatus _currentStatus;
  DateTime? _followupDate;
  TimeOfDay? _followupTime;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _currentStatus = _lead.status;
    _followupDate = _lead.followupDate;
    if (_lead.followupDate != null) {
      _followupTime = TimeOfDay(hour: _lead.followupDate!.hour, minute: _lead.followupDate!.minute);
    }
  }

  void _showConvertDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.userCheck, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Convert to Customer', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          'Convert ${_lead.name} to a customer? Their lead details will be copied to a new customer profile.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _convertLead();
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  Future<void> _convertLead() async {
    setState(() => _isConverting = true);

    final result = await ref.read(leadProvider.notifier).convertLead(_lead.id);

    setState(() => _isConverting = false);

    if (result != null && mounted) {
      final customerId = result['customer_id'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_lead.name} converted to customer successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to the new customer's profile
      Navigator.pushReplacementNamed(
        context,
        '/customer_detail',
        arguments: {'customerId': customerId.toString()},
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to convert lead'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateStatus(LeadStatus newStatus) async {
    setState(() {
      _isUpdating = true;
      _currentStatus = newStatus;
    });

    final data = <String, dynamic>{'status': newStatus.apiValue};

    // If switching to follow-up scheduled and a date is set, include it
    if (newStatus == LeadStatus.followupScheduled && _followupDate != null) {
      final time = _followupTime ?? const TimeOfDay(hour: 9, minute: 0);
      final combined = DateTime(
        _followupDate!.year, _followupDate!.month, _followupDate!.day,
        time.hour, time.minute,
      );
      data['follow_up_date'] = combined.toIso8601String();
    }

    final success = await ref.read(leadProvider.notifier).updateLead(_lead.id, data);
    setState(() => _isUpdating = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${newStatus.label}'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _pickFollowupDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _followupDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _followupTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    setState(() {
      _followupDate = date;
      if (time != null) _followupTime = time;
    });

    // Auto-save the follow-up date
    final combined = DateTime(
      date.year, date.month, date.day,
      (time ?? const TimeOfDay(hour: 9, minute: 0)).hour,
      (time ?? const TimeOfDay(hour: 9, minute: 0)).minute,
    );

    await ref.read(leadProvider.notifier).updateLead(_lead.id, {
      'follow_up_date': combined.toIso8601String(),
      'status': LeadStatus.followupScheduled.apiValue,
    });

    if (mounted) {
      setState(() => _currentStatus = LeadStatus.followupScheduled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lead.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lead Info Card
            _buildInfoCard(context),
            const SizedBox(height: 16),

            // Status Update Section
            _buildStatusSection(context),
            const SizedBox(height: 16),

            // Follow-up section (if status is follow-up scheduled)
            if (_currentStatus == LeadStatus.followupScheduled)
              _buildFollowupSection(context),

            const SizedBox(height: 24),

            // Convert to Customer Button
            if (_currentStatus != LeadStatus.converted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isConverting ? null : _showConvertDialog,
                  icon: _isConverting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.userCheck),
                  label: const Text('Convert to Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),

            if (_currentStatus == LeadStatus.converted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lead Converted', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text('${_lead.name} is now a customer', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
        boxShadow: AppThemeHelper.isDark(context) ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _infoRow(LucideIcons.user, 'Name', _lead.name),
          _divider(),
          _infoRow(LucideIcons.phone, 'Mobile', _lead.mobile),
          if (_lead.email.isNotEmpty) ...[_divider(), _infoRow(LucideIcons.mail, 'Email', _lead.email)],
          _divider(),
          _infoRow(LucideIcons.briefcase, 'Insurance Type', _lead.insuranceType),
          _divider(),
          _infoRow(LucideIcons.globe, 'Source', _lead.source),
          if (_lead.notes.isNotEmpty) ...[_divider(), _infoRow(LucideIcons.fileText, 'Notes', _lead.notes)],
          _divider(),
          _infoRow(LucideIcons.calendar, 'Created', DateFormat('dd MMM yyyy').format(_lead.createdAt)),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppThemeHelper.textPrimary(context))),
          const SizedBox(height: 12),
          DropdownButtonFormField<LeadStatus>(
            initialValue: _currentStatus,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppThemeHelper.surfaceColor(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: LeadStatus.values
                .where((s) => s != LeadStatus.converted) // Can't manually set to converted
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: _isUpdating
                ? null
                : (v) {
                    if (v != null && v != _currentStatus) {
                      _updateStatus(v);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.calendarClock, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('Follow-up Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          if (_followupDate != null)
            Text(
              'Scheduled: ${DateFormat('dd MMM yyyy').format(_followupDate!)} at ${_followupTime?.format(context) ?? '09:00 AM'}',
              style: const TextStyle(fontSize: 14),
            )
          else
            const Text('No follow-up date set', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFollowupDateTime,
            icon: const Icon(LucideIcons.calendar, size: 16),
            label: Text(_followupDate == null ? 'Set Follow-up Date & Time' : 'Change Date & Time'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: const BorderSide(color: Colors.purple),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2));
}
