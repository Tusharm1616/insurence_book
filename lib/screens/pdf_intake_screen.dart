import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../providers/customer_documents_provider.dart';

/// PDF Intake Screen — shown when user shares a PDF from another app (WhatsApp, etc.)
class PdfIntakeScreen extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;
  final int fileSize;

  const PdfIntakeScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });

  @override
  ConsumerState<PdfIntakeScreen> createState() => _PdfIntakeScreenState();
}

class _PdfIntakeScreenState extends ConsumerState<PdfIntakeScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String _documentType = 'New Policy';
  bool _isSearching = false;
  bool _isSaving = false;
  List<_CustomerSearchResult> _searchResults = [];

  static const _documentTypes = [
    'New Policy',
    'Renewal Policy',
    'Claim Document',
    'Other',
  ];

  static const int _maxFileSize = 10 * 1024 * 1024; // 10 MB

  @override
  void initState() {
    super.initState();
    // Validate file size on init
    if (widget.fileSize > _maxFileSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError('File is too large. Maximum size is 10 MB.');
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await apiService.dio.get(
        '/api/customers/',
        queryParameters: {'search': query.trim(), 'limit': 20, 'page': 1},
      );

      final List<dynamic> data = response.data['data'] as List? ?? [];
      setState(() {
        _searchResults = data
            .map((e) => _CustomerSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectCustomer(_CustomerSearchResult customer) {
    setState(() {
      _selectedCustomerId = customer.id;
      _selectedCustomerName = customer.fullName;
      _searchController.text = customer.fullName;
      _searchResults = [];
    });
    _searchFocusNode.unfocus();
  }

  Future<void> _saveDocument() async {
    if (_selectedCustomerId == null) {
      _showError('Please select a customer.');
      return;
    }

    if (widget.fileSize > _maxFileSize) {
      _showError('File is too large. Maximum size is 10 MB.');
      return;
    }

    // File format was already validated in main.dart via mime type and extension

    setState(() => _isSaving = true);

    try {
      String finalFileName = widget.fileName;
      if (!finalFileName.toLowerCase().endsWith('.pdf')) {
        finalFileName += '.pdf';
      }

      final formData = FormData.fromMap({
        'document_type': _documentType,
        'notes': _notesController.text.trim(),
        'file': await MultipartFile.fromFile(
          widget.filePath,
          filename: finalFileName,
        ),
      });

      await apiService.dio.post(
        '/api/customers/$_selectedCustomerId/documents',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            ref.read(uploadProgressProvider.notifier).setProgress(sent / total);
          }
        },
      );

      ref.read(uploadProgressProvider.notifier).clear();
      ref.invalidate(customerDocumentsProvider(_selectedCustomerId!));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document saved to ${_selectedCustomerName ?? "customer"}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to customer's detail screen (Documents tab)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/customer_detail',
        (route) => route.settings.name == '/dashboard' || route.isFirst,
        arguments: {'customerId': _selectedCustomerId},
      );
    } catch (e) {
      ref.read(uploadProgressProvider.notifier).clear();
      if (mounted) {
        _showError('Failed to upload document. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
      (route) => false,
    );
  }

  String get _fileSizeFormatted {
    final size = widget.fileSize;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final uploadProgress = ref.watch(uploadProgressProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Import PDF Document',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PDF File Preview ──
            _buildFilePreview(),
            const SizedBox(height: 24),

            // ── Customer Search ──
            _buildLabel('Which customer is this for?'),
            const SizedBox(height: 8),
            _buildCustomerSearch(),
            const SizedBox(height: 20),

            // ── Document Type ──
            _buildLabel('Document Type'),
            const SizedBox(height: 8),
            _buildDocumentTypeDropdown(),
            const SizedBox(height: 20),

            // ── Notes ──
            _buildLabel('Notes (optional)'),
            const SizedBox(height: 8),
            _buildNotesField(),
            const SizedBox(height: 32),

            // ── Upload Progress ──
            if (uploadProgress != null) ...[
              LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                '${(uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemeHelper.textSecondary(context),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDocument,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save to Customer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.green[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final isTooLarge = widget.fileSize > _maxFileSize;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTooLarge ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTooLarge ? Colors.red[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 48,
            color: isTooLarge ? Colors.red : Colors.red[700],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppThemeHelper.textPrimary(context),
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _fileSizeFormatted,
                  style: TextStyle(
                    fontSize: 13,
                    color: isTooLarge ? Colors.red : AppThemeHelper.textSecondary(context),
                    fontFamily: 'Poppins',
                    fontWeight: isTooLarge ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isTooLarge) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'File exceeds 10 MB limit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearch() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search by name or phone...',
            hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _selectedCustomerId != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedCustomerId = null;
                        _selectedCustomerName = null;
                        _searchController.clear();
                        _searchResults = [];
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: _selectedCustomerId != null ? Colors.green[50] : null,
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          onChanged: (val) {
            if (_selectedCustomerId != null) {
              setState(() {
                _selectedCustomerId = null;
                _selectedCustomerName = null;
              });
            }
            _searchCustomers(val);
          },
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = _searchResults[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      customer.fullName.isNotEmpty
                          ? customer.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    customer.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  subtitle: Text(
                    customer.phone,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeHelper.textSecondary(context),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () => _selectCustomer(customer),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _documentType,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppThemeHelper.textPrimary(context),
      ),
      items: _documentTypes.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _documentType = val);
      },
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add any notes about this document...',
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppThemeHelper.textPrimary(context),
        fontFamily: 'Poppins',
      ),
    );
  }
}

// ── Helper model for customer search results ─────────────────────────────────

class _CustomerSearchResult {
  final String id;
  final String fullName;
  final String phone;

  _CustomerSearchResult({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory _CustomerSearchResult.fromJson(Map<String, dynamic> json) {
    return _CustomerSearchResult(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
