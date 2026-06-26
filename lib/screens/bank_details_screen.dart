import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme.dart';
import '../models/bank_details.dart';
import '../providers/bank_details_provider.dart';
import '../utils/lucide_compat.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _showEditSheet(BankDetails? current) {
    final upiCtrl = TextEditingController(text: current?.upiId ?? '');
    final bankCtrl = TextEditingController(text: current?.bankName ?? '');
    final accCtrl = TextEditingController(text: current?.accountNumber ?? '');
    final ifscCtrl = TextEditingController(text: current?.ifscCode ?? '');
    final branchCtrl = TextEditingController(text: current?.branchName ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeHelper.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Bank Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppThemeHelper.textPrimary(ctx),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: AppThemeHelper.textSecondary(ctx)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _editField('UPI ID', upiCtrl, ctx),
              _editField('Bank Name', bankCtrl, ctx),
              _editField('Account Number', accCtrl, ctx, isNumber: true),
              _editField('IFSC Code', ifscCtrl, ctx),
              _editField('Branch Name', branchCtrl, ctx),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final details = BankDetails(
                      upiId: upiCtrl.text.isEmpty ? null : upiCtrl.text,
                      bankName: bankCtrl.text.isEmpty ? null : bankCtrl.text,
                      accountNumber: accCtrl.text.isEmpty ? null : accCtrl.text,
                      ifscCode: ifscCtrl.text.isEmpty ? null : ifscCtrl.text,
                      branchName: branchCtrl.text.isEmpty ? null : branchCtrl.text,
                    );
                    final success = await ref
                        .read(bankDetailsProvider.notifier)
                        .updateDetails(details);
                    if (!mounted) return;
                    if (success) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bank details updated successfully'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update bank details'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _editField(String label, TextEditingController ctrl, BuildContext ctx,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: AppThemeHelper.textPrimary(ctx)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppThemeHelper.textSecondary(ctx), fontSize: 13),
          filled: true,
          fillColor: AppThemeHelper.surfaceColor(ctx),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppThemeHelper.borderColor(ctx)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppThemeHelper.borderColor(ctx)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  String _maskAccount(String? acc) {
    if (acc == null || acc.length < 5) return acc ?? '-';
    return 'XXXX XXXX ${acc.substring(acc.length - 4)}';
  }

  Future<void> _shareQr(String? qrCodeUrl) async {
    if (qrCodeUrl == null || qrCodeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a UPI ID first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Strip the data URL prefix
      final b64String = qrCodeUrl.split(',').last;
      final Uint8List bytes = base64Decode(b64String);

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/upi_qr_code.png');
      await file.writeAsBytes(bytes);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'UPI QR Code'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildShimmer() {
    final isDark = AppThemeHelper.isDark(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
        highlightColor: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppThemeHelper.cardColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: AppThemeHelper.cardColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppThemeHelper.cardColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppThemeHelper.cardColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 64, color: AppThemeHelper.textSecondary(context)),
            const SizedBox(height: 16),
            Text(
              'Failed to load bank details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppThemeHelper.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppThemeHelper.textSecondary(context), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(bankDetailsProvider.notifier).refresh(),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrImage(String? qrCodeUrl) {
    if (qrCodeUrl == null || qrCodeUrl.isEmpty) {
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: AppThemeHelper.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemeHelper.borderColor(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.qrCode, size: 64, color: AppThemeHelper.textSecondary(context)),
              const SizedBox(height: 8),
              Text(
                'No QR Code',
                style: TextStyle(
                  color: AppThemeHelper.textSecondary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final b64String = qrCodeUrl.split(',').last;
      final bytes = base64Decode(b64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 160,
          height: 160,
          fit: BoxFit.contain,
        ),
      );
    } catch (_) {
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: AppThemeHelper.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemeHelper.borderColor(context)),
        ),
        child: Center(
          child: Icon(LucideIcons.qrCode, size: 64, color: AppThemeHelper.textSecondary(context)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankDetailsAsync = ref.watch(bankDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agent Bank Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3),
            onPressed: () => _showEditSheet(
              bankDetailsAsync.hasValue ? bankDetailsAsync.value : null,
            ),
          ),
        ],
      ),
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      body: bankDetailsAsync.when(
        loading: () => _buildShimmer(),
        error: (error, _) => _buildError(error),
        data: (details) => _buildContent(details),
      ),
    );
  }

  Widget _buildContent(BankDetails? details) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // QR Code Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppThemeHelper.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeHelper.borderColor(context)),
            ),
            child: Column(
              children: [
                _buildQrImage(details?.qrCodeUrl),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareQr(details?.qrCodeUrl),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareQr(details?.qrCodeUrl),
                        icon: const Icon(LucideIcons.share2, size: 18),
                        label: const Text('Share QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // UPI ID Card
          _infoCard(
            icon: LucideIcons.wallet,
            color: Colors.orange,
            title: 'UPI Payment Details',
            fields: [
              _copyableField('UPI ID', details?.upiId ?? '-'),
            ],
          ),
          const SizedBox(height: 16),

          // Bank Information Card
          _infoCard(
            icon: LucideIcons.landmark,
            color: Colors.blue,
            title: 'Bank Information',
            fields: [
              _copyableField('Bank Name', details?.bankName ?? '-'),
              Divider(height: 24, color: AppThemeHelper.dividerColor(context)),
              _copyableField(
                'Account Number',
                _maskAccount(details?.accountNumber),
                rawValue: details?.accountNumber,
              ),
              Divider(height: 24, color: AppThemeHelper.dividerColor(context)),
              _copyableField('IFSC Code', details?.ifscCode ?? '-'),
              Divider(height: 24, color: AppThemeHelper.dividerColor(context)),
              _copyableField('Branch Name', details?.branchName ?? '-'),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> fields,
  }) {
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppThemeHelper.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemeHelper.surfaceColor(context),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields,
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyableField(String label, String displayValue, {String? rawValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppThemeHelper.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppThemeHelper.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
        if (displayValue != '-')
          IconButton(
            onPressed: () => _copyToClipboard(rawValue ?? displayValue),
            icon: Icon(LucideIcons.copy, color: AppThemeHelper.textSecondary(context), size: 18),
            tooltip: 'Copy $label',
            style: IconButton.styleFrom(
              backgroundColor: AppThemeHelper.cardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppThemeHelper.borderColor(context)),
              ),
            ),
          ),
      ],
    );
  }
}
