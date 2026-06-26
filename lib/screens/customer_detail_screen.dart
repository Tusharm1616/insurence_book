import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../providers/customer_detail_provider.dart';
import '../providers/customer_documents_provider.dart';
import '../services/policy_pdf_service.dart';
import 'document_viewer_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Customer name for PDF share text (cached from provider).
  String get _customerNameForPdf {
    final detail = ref.read(customerDetailProvider(widget.customerId));
    return detail.asData?.value.fullName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final customerDetailAsync = ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: customerDetailAsync.when(
          data: (customer) => Text(
            customer.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          loading: () => const Text(
            'Customer Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          error: (err, st) => const Text(
            'Error',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit_customer',
                arguments: {'customerId': widget.customerId},
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Policies'),
            Tab(text: 'Documents'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: customerDetailAsync.when(
        data: (customer) => TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, customer),
            _buildPoliciesTab(context, customer),
            _DocumentsTab(customerId: widget.customerId),
            _buildTimelineTab(context, customer),
          ],
        ),
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err.toString()),
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, CustomerDetail customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildPersonalInfoCard(context, customer),
    );
  }

  // ── Policies Tab ─────────────────────────────────────────────────────────────
  Widget _buildPoliciesTab(BuildContext context, CustomerDetail customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildPoliciesSection(context, customer),
    );
  }

  // ── Timeline Tab ─────────────────────────────────────────────────────────────
  Widget _buildTimelineTab(BuildContext context, CustomerDetail customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customer.createdAt.isNotEmpty)
            _buildTimelineItem(
              icon: Icons.person_add,
              color: AppColors.primary,
              title: 'Customer Created',
              subtitle: _formatDate(customer.createdAt),
            ),
          ...customer.policies.map((policy) => _buildTimelineItem(
            icon: Icons.policy,
            color: _getPolicyTypeColor(policy.policyType),
            title: 'Policy Added: ${policy.policyNumber}',
            subtitle: '${policy.insurerName} — ${_formatDate(policy.startDate)}',
          )),
          if (customer.policies.isEmpty && customer.createdAt.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No timeline events yet',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                        fontFamily: 'Poppins',
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

  Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, CustomerDetail customer) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppThemeHelper.textPrimary(context),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(context, 'Full Name', customer.fullName),
            _buildInfoRow(context, 'Phone', customer.phone.isNotEmpty ? customer.phone : 'N/A'),
            _buildInfoRow(context, 'Email', customer.email.isNotEmpty ? customer.email : 'N/A'),
            _buildInfoRow(context, 'Date of Birth', customer.dob.isNotEmpty ? _formatDate(customer.dob) : 'N/A'),
            _buildInfoRow(context, 'Anniversary', customer.anniversaryDate.isNotEmpty ? _formatDate(customer.anniversaryDate) : 'N/A'),
            _buildInfoRow(context, 'Address', customer.address.isNotEmpty ? customer.address : 'N/A'),
            _buildInfoRow(context, 'City', customer.city.isNotEmpty ? customer.city : 'N/A'),
            _buildInfoRow(context, 'State', customer.state.isNotEmpty ? customer.state : 'N/A'),
            _buildInfoRow(context, 'Pincode', customer.pincode.isNotEmpty ? customer.pincode : 'N/A'),
            _buildInfoRow(context, 'Ref By', customer.refBy.isNotEmpty ? customer.refBy : 'N/A'),

            const SizedBox(height: 16),

            // Status chip
            Row(
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppThemeHelper.textSecondary(context),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: customer.status == 'active'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.status == 'active' ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: customer.status == 'active' ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesSection(BuildContext context, CustomerDetail customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Policies (${customer.policies.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppThemeHelper.textPrimary(context),
                fontFamily: 'Poppins',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/add_policy',
                  arguments: {'customerId': widget.customerId},
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (customer.policies.isEmpty)
          _buildEmptyState('No policies added yet', Icons.policy_outlined)
        else
          ...customer.policies.map((policy) => _buildPolicyMiniCard(context, policy)),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyMiniCard(BuildContext context, PolicyDetail policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    policy.policyNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppThemeHelper.textPrimary(context),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPolicyTypeColor(policy.policyType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    policy.policyType,
                    style: TextStyle(
                      color: _getPolicyTypeColor(policy.policyType),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${policy.insurerName} — ${policy.planName}',
              style: TextStyle(
                fontSize: 14,
                color: AppThemeHelper.textSecondary(context),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sum Insured: ₹${_formatCurrency(policy.sumInsured)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppThemeHelper.textPrimary(context),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium: ₹${_formatCurrency(policy.premiumAmount)}/yr',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppThemeHelper.textPrimary(context),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Start: ${_formatDate(policy.startDate)} → End: ${_formatDate(policy.endDate)}',
              style: TextStyle(
                fontSize: 13,
                color: AppThemeHelper.textSecondary(context),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPolicyStatusColor(policy.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    policy.status,
                    style: TextStyle(
                      color: _getPolicyStatusColor(policy.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDaysRemainingColor(policy.endDate).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDaysRemainingText(policy.endDate),
                    style: TextStyle(
                      color: _getDaysRemainingColor(policy.endDate),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                // Share & Download PDF buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PolicyPdfActionButton(
                      icon: Icons.download,
                      tooltip: 'Download PDF',
                      policyId: policy.id,
                      policyNumber: policy.policyNumber,
                      isDownload: true,
                    ),
                    const SizedBox(width: 4),
                    _PolicyPdfActionButton(
                      icon: Icons.share,
                      tooltip: 'Share PDF',
                      policyId: policy.id,
                      policyNumber: policy.policyNumber,
                      customerName: _customerNameForPdf,
                      isDownload: false,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppThemeHelper.textSecondary(context),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppThemeHelper.textPrimary(context),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(customerDetailProvider(widget.customerId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+$)'),
      (match) => '${match[1]}${match[2] != null ? ',' : ''}${match[2] ?? ''}',
    );
  }

  Color _getPolicyTypeColor(String policyType) {
    switch (policyType.toLowerCase()) {
      case 'motor':
        return Colors.blue;
      case 'health':
        return Colors.green;
      case 'life':
        return Colors.purple;
      case 'term':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPolicyStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'lapsed':
        return Colors.orange;
      case 'paidup':
        return Colors.purple;
      case 'matured':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getDaysRemainingColor(String endDate) {
    if (endDate.isEmpty) return Colors.grey;
    try {
      final date = DateTime.parse(endDate);
      final now = DateTime.now();
      final daysDifference = date.difference(now).inDays;
      if (daysDifference < 0) return Colors.red;
      if (daysDifference <= 30) return Colors.orange;
      if (daysDifference <= 60) return Colors.amber;
      return Colors.green;
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getDaysRemainingText(String endDate) {
    if (endDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(endDate);
      final now = DateTime.now();
      final daysDifference = date.difference(now).inDays;
      if (daysDifference < 0) return 'Expired ${daysDifference.abs()} days ago';
      if (daysDifference == 0) return 'Expires Today';
      return '$daysDifference days left';
    } catch (e) {
      return 'N/A';
    }
  }
}

// ── Documents Tab (Separate StatefulWidget for its own state) ────────────────

class _DocumentsTab extends ConsumerStatefulWidget {
  final String customerId;
  const _DocumentsTab({required this.customerId});

  @override
  ConsumerState<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<_DocumentsTab> {
  static const List<String> _documentTypes = [
    'Aadhaar',
    'PAN',
    'Driving Licence',
    'RC Book',
    'Other',
  ];

  IconData _getDocTypeIcon(String type) {
    switch (type) {
      case 'Aadhaar':
        return Icons.credit_card;
      case 'PAN':
        return Icons.badge;
      case 'Driving Licence':
        return Icons.directions_car;
      case 'RC Book':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocTypeColor(String type) {
    switch (type) {
      case 'Aadhaar':
        return Colors.blue;
      case 'PAN':
        return Colors.indigo;
      case 'Driving Licence':
        return Colors.orange;
      case 'RC Book':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickAndUpload(String documentType) async {
    final picker = ImagePicker();

    // Show bottom sheet to choose source
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload $documentType',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    XFile? pickedFile;
    if (source == 'camera') {
      pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    } else {
      pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    }

    if (pickedFile == null) return;

    final success = await uploadCustomerDocument(
      customerId: widget.customerId,
      documentType: documentType,
      filePath: pickedFile.path,
      fileName: pickedFile.name,
      ref: ref,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Document uploaded successfully' : 'Upload failed'),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(CustomerDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document', style: TextStyle(fontFamily: 'Poppins')),
        content: Text(
          'Are you sure you want to delete "${doc.documentName}"?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await deleteCustomerDocument(
        customerId: widget.customerId,
        documentId: doc.id,
        ref: ref,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Document deleted' : 'Delete failed'),
            backgroundColor: success ? AppColors.primary : AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _viewDocument(CustomerDocument doc) {
    // Build full URL for viewing
    String fullUrl = doc.fileUrl;
    if (fullUrl.startsWith('/')) {
      // Local file — prepend base URL
      fullUrl = 'https://insurence-book.onrender.com${doc.fileUrl}';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          documentName: doc.documentName,
          fileUrl: fullUrl,
          isPdf: doc.isPdf,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customerId.isEmpty) {
      return const Center(
        child: Text('No customer selected', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
      );
    }
    final docsAsync = ref.watch(customerDocumentsProvider(widget.customerId));
    final uploadProgress = ref.watch(uploadProgressProvider);

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('Failed to load documents', style: TextStyle(color: Colors.grey[600], fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(customerDocumentsProvider(widget.customerId)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (documents) {
        // Group documents by type
        final Map<String, List<CustomerDocument>> grouped = {};
        for (final type in _documentTypes) {
          final docs = documents.where((d) => d.documentType == type).toList();
          if (docs.isNotEmpty) {
            grouped[type] = docs;
          }
        }

        if (grouped.isEmpty && uploadProgress == null) {
          // Empty state
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No documents uploaded yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showDocTypeChooser(),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Show sections for each type that has documents
                for (final type in _documentTypes) ...[
                  if (grouped.containsKey(type)) ...[
                    _buildSectionHeader(type),
                    ...grouped[type]!.map((doc) => _buildDocumentCard(doc)),
                    _buildAddButton(type),
                    const SizedBox(height: 16),
                  ],
                ],
                // Show add buttons for types that don't have docs yet
                ..._documentTypes
                    .where((t) => !grouped.containsKey(t))
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildAddButton(t),
                        )),
              ],
            ),
            // Upload progress overlay
            if (uploadProgress != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: uploadProgress > 0 ? uploadProgress : null,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Uploading... ${(uploadProgress * 100).toInt()}%',
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDocTypeChooser() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Document Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),
              ..._documentTypes.map((type) => ListTile(
                    leading: Icon(_getDocTypeIcon(type), color: _getDocTypeColor(type)),
                    title: Text(type, style: const TextStyle(fontFamily: 'Poppins')),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUpload(type);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(_getDocTypeIcon(type), size: 20, color: _getDocTypeColor(type)),
          const SizedBox(width: 8),
          Text(
            type,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(CustomerDocument doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getDocTypeColor(doc.documentType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                doc.isPdf ? Icons.picture_as_pdf : Icons.image,
                color: doc.isPdf ? Colors.red : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.documentName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppThemeHelper.textPrimary(context),
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatUploadDate(doc.uploadedAt)} • ${doc.fileSizeFormatted}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeHelper.textSecondary(context),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              color: AppColors.primary,
              tooltip: 'View',
              onPressed: () => _viewDocument(doc),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.danger,
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(doc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String type) {
    return TextButton.icon(
      onPressed: () => _pickAndUpload(type),
      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
      label: Text(
        '+ Add $type',
        style: const TextStyle(
          color: AppColors.primary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  String _formatUploadDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

// ── Policy PDF Action Button (share or download) ─────────────────────────────

class _PolicyPdfActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final String policyId;
  final String policyNumber;
  final String? customerName;
  final bool isDownload;

  const _PolicyPdfActionButton({
    required this.icon,
    required this.tooltip,
    required this.policyId,
    required this.policyNumber,
    this.customerName,
    required this.isDownload,
  });

  @override
  State<_PolicyPdfActionButton> createState() => _PolicyPdfActionButtonState();
}

class _PolicyPdfActionButtonState extends State<_PolicyPdfActionButton> {
  bool _isLoading = false;

  Future<void> _onPressed() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isDownload) {
        final path = await PolicyPdfService.downloadPolicyPdf(
          context: context,
          policyId: widget.policyId,
          policyNumber: widget.policyNumber,
        );
        if (path != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved: ${path.split('/').last}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await PolicyPdfService.sharePolicyPdf(
          context: context,
          policyId: widget.policyId,
          policyNumber: widget.policyNumber,
          customerName: widget.customerName,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(4),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(widget.icon, size: 18, color: AppColors.primary),
              tooltip: widget.tooltip,
              onPressed: _onPressed,
            ),
    );
  }
}
