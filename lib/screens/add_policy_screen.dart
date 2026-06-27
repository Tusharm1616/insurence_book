import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/policy_v2_model.dart';
import '../services/api_service.dart';
import '../utils/lucide_compat.dart';

// ── Insurance Type Options ─────────────────────────────────────────────────
const List<String> kInsuranceTypes = ['Life', 'Motor', 'Health', 'Travel', 'Other'];

// ── AddPolicyScreen ────────────────────────────────────────────────────────

class AddPolicyScreen extends ConsumerStatefulWidget {
  /// If provided, the screen operates in edit mode and pre-fills the form.
  final PolicyV2? existingPolicy;

  const AddPolicyScreen({super.key, this.existingPolicy});

  @override
  ConsumerState<AddPolicyScreen> createState() => _AddPolicyScreenState();
}

class _AddPolicyScreenState extends ConsumerState<AddPolicyScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existingPolicy != null;

  // ── Section expansion state ──────────────────────────────────────────────
  bool _policyInfoExpanded = true;
  bool _financialDetailsExpanded = false;
  bool _inspectionClaimExpanded = false;
  bool _otherDetailsExpanded = false;
  bool _documentsExpanded = false;

  // ── Policy Info fields ───────────────────────────────────────────────────
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  final _policyNumberCtrl = TextEditingController();
  final _insuranceCompanyCtrl = TextEditingController();
  String? _insuranceType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _prefillForm(widget.existingPolicy!);
    }
  }

  void _prefillForm(PolicyV2 policy) {
    _selectedCustomerId = policy.customerId;
    _selectedCustomerName = policy.customerName;
    _policyNumberCtrl.text = policy.policyNumber;
    _insuranceCompanyCtrl.text = policy.insuranceCompany ?? '';
    _insuranceType = policy.insuranceType;
    _startDate = policy.startDate;
    _endDate = policy.endDate;
  }

  @override
  void dispose() {
    _policyNumberCtrl.dispose();
    _insuranceCompanyCtrl.dispose();
    super.dispose();
  }

  // ── Date constraint: clear end_date if start_date is after it ────────────
  void _onStartDateChanged(DateTime newStart) {
    setState(() {
      _startDate = newStart;
      if (_endDate != null && newStart.isAfter(_endDate!)) {
        _endDate = null;
      }
    });
  }

  void _onEndDateChanged(DateTime newEnd) {
    setState(() {
      _endDate = newEnd;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Policy' : 'Add Policy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Section 1: Policy Info
              _buildExpandableSection(
                title: 'Policy Info',
                icon: LucideIcons.fileText,
                isExpanded: _policyInfoExpanded,
                onToggle: () => setState(() => _policyInfoExpanded = !_policyInfoExpanded),
                child: _buildPolicyInfoSection(),
              ),
              const SizedBox(height: 12),

              // Section 2: Financial Details (placeholder)
              _buildExpandableSection(
                title: 'Financial Details',
                icon: LucideIcons.indianRupee,
                isExpanded: _financialDetailsExpanded,
                onToggle: () => setState(() => _financialDetailsExpanded = !_financialDetailsExpanded),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Financial details section coming soon...',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Section 3: Inspection & Claim (placeholder)
              _buildExpandableSection(
                title: 'Inspection & Claim',
                icon: LucideIcons.shieldCheck,
                isExpanded: _inspectionClaimExpanded,
                onToggle: () => setState(() => _inspectionClaimExpanded = !_inspectionClaimExpanded),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Inspection & claim section coming soon...',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Section 4: Other Details (placeholder)
              _buildExpandableSection(
                title: 'Other Details',
                icon: LucideIcons.info,
                isExpanded: _otherDetailsExpanded,
                onToggle: () => setState(() => _otherDetailsExpanded = !_otherDetailsExpanded),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Other details section coming soon...',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Section 5: Documents (placeholder)
              _buildExpandableSection(
                title: 'Documents',
                icon: LucideIcons.upload,
                isExpanded: _documentsExpanded,
                onToggle: () => setState(() => _documentsExpanded = !_documentsExpanded),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Documents section coming soon...',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Expandable Section Widget ────────────────────────────────────────────
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade200),
                child,
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // ── Policy Info Section ──────────────────────────────────────────────────
  Widget _buildPolicyInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer searchable dropdown
          _label('Customer', isRequired: true),
          CustomerSearchDropdown(
            selectedCustomerId: _selectedCustomerId,
            selectedCustomerName: _selectedCustomerName,
            onCustomerSelected: (int id, String name) {
              setState(() {
                _selectedCustomerId = id;
                _selectedCustomerName = name;
              });
            },
          ),
          const SizedBox(height: 4),

          // Policy Number
          _label('Policy Number', isRequired: true),
          TextFormField(
            controller: _policyNumberCtrl,
            maxLength: 50,
            decoration: _inputDecoration(hint: 'Enter policy number'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Policy number is required' : null,
          ),

          // Insurance Company
          _label('Insurance Company'),
          TextFormField(
            controller: _insuranceCompanyCtrl,
            maxLength: 100,
            decoration: _inputDecoration(hint: 'Enter insurance company name'),
          ),

          // Insurance Type
          _label('Insurance Type', isRequired: true),
          DropdownButtonFormField<String>(
            initialValue: _insuranceType,
            hint: const Text('Select type', style: TextStyle(color: Colors.grey, fontSize: 14)),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            decoration: _inputDecoration(),
            items: kInsuranceTypes
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) => setState(() => _insuranceType = v),
            validator: (v) => v == null ? 'Insurance type is required' : null,
          ),

          // Start Date
          _label('Start Date', isRequired: true),
          _buildDatePicker(
            label: 'Start Date',
            date: _startDate,
            onPicked: _onStartDateChanged,
          ),

          // End Date
          _label('End Date', isRequired: true),
          _buildDatePicker(
            label: 'End Date',
            date: _endDate,
            onPicked: _onEndDateChanged,
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────

  Widget _label(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onPicked,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.green),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.calendar, color: Colors.green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                        : 'Tap to select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: date != null ? FontWeight.bold : FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── CustomerSearchDropdown Widget ──────────────────────────────────────────

class CustomerSearchDropdown extends StatefulWidget {
  final int? selectedCustomerId;
  final String? selectedCustomerName;
  final void Function(int id, String name) onCustomerSelected;

  const CustomerSearchDropdown({
    super.key,
    this.selectedCustomerId,
    this.selectedCustomerName,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerSearchDropdown> createState() => _CustomerSearchDropdownState();
}

class _CustomerSearchDropdownState extends State<CustomerSearchDropdown> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCustomerName != null) {
      _searchCtrl.text = widget.selectedCustomerName!;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() => _showDropdown = true);
      if (_searchCtrl.text.isNotEmpty) {
        _searchCustomers(_searchCtrl.text);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      setState(() {
        _customers = [];
        _showDropdown = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchCustomers(query);
    });
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _showDropdown = true;
    });

    try {
      final response = await apiService.dio.get(
        '/api/customers/',
        queryParameters: {'search': query, 'limit': 20},
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      final customers = data
          .map((c) => {
                'id': c['id'],
                'full_name': c['full_name'] ?? '',
                'phone': c['phone'] ?? '',
              })
          .where((c) =>
              (c['full_name'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Could not load customers. Tap to retry.';
        });
      }
    }
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    final id = int.tryParse(customer['id'].toString()) ?? 0;
    final name = customer['full_name'] as String;
    _searchCtrl.text = name;
    setState(() => _showDropdown = false);
    _focusNode.unfocus();
    widget.onCustomerSelected(id, name);
  }

  void _retry() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      _searchCustomers(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextFormField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search customer by name...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: Colors.grey),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _customers = [];
                        _showDropdown = false;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          onChanged: _onSearchChanged,
          validator: (v) {
            if (widget.selectedCustomerId == null) {
              return 'Please select a customer';
            }
            return null;
          },
        ),

        // Dropdown results
        if (_showDropdown) _buildDropdownResults(),
      ],
    );
  }

  Widget _buildDropdownResults() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildDropdownContent(),
    );
  }

  Widget _buildDropdownContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
          ),
        ),
      );
    }

    if (_hasError) {
      return InkWell(
        onTap: _retry,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Failed to load customers',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
              const Icon(LucideIcons.refreshCw, color: Colors.green, size: 16),
            ],
          ),
        ),
      );
    }

    if (_customers.isEmpty && _searchCtrl.text.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No customers found',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    if (_customers.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _customers.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            child: const Icon(LucideIcons.user, size: 16, color: Colors.green),
          ),
          title: Text(
            customer['full_name'] as String,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            customer['phone'] as String,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () => _selectCustomer(customer),
        );
      },
    );
  }
}
