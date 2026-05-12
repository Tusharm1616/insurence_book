import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/api_service.dart';
import '../providers/customers_provider.dart';
import '../providers/customer_detail_provider.dart';
import '../providers/dashboard_provider.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  final String customerId;

  const EditCustomerScreen({super.key, required this.customerId});

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  DateTime? _dob;
  String _status = 'active';
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    try {
      final response =
          await ApiService().get('/api/customers/${widget.customerId}');
      final d = response.data;
      _nameCtrl.text = d['full_name'] ?? '';
      _phoneCtrl.text = d['phone'] ?? '';
      _emailCtrl.text = d['email'] ?? '';
      _addressCtrl.text = d['address'] ?? '';
      _cityCtrl.text = d['city'] ?? '';
      _stateCtrl.text = d['state'] ?? '';
      _pincodeCtrl.text = d['pincode'] ?? '';
      _status = d['status'] ?? 'active';
      if (d['dob'] != null && (d['dob'] as String).isNotEmpty) {
        _dob = DateTime.tryParse(d['dob']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetching = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ApiService().put('/api/customers/${widget.customerId}', data: {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'dob': _dob?.toIso8601String().split('T').first,
        'status': _status,
      });

      // Invalidate caches
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(customerDetailProvider(widget.customerId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Customer updated successfully!',
                style: TextStyle(fontFamily: 'Poppins')),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text(
          'Edit Customer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard([
                      _label('Full Name *'),
                      _textField('Full name', _nameCtrl,
                          required: true, icon: Icons.person_outline),
                      _label('Phone Number'),
                      _textField('Phone number', _phoneCtrl,
                          keyboard: TextInputType.phone,
                          icon: Icons.phone_outlined),
                      _label('Email Address'),
                      _textField('Email address', _emailCtrl,
                          keyboard: TextInputType.emailAddress,
                          icon: Icons.email_outlined),
                      _label('Date of Birth'),
                      _dobPicker(),
                      _label('Status'),
                      _statusPicker(),
                    ]),
                    const SizedBox(height: 16),
                    _buildCard([
                      _label('Address'),
                      _textField('Full address', _addressCtrl,
                          maxLines: 2, icon: Icons.location_on_outlined),
                      _label('City'),
                      _textField('City', _cityCtrl,
                          icon: Icons.location_city_outlined),
                      _label('State'),
                      _textField('State', _stateCtrl,
                          icon: Icons.map_outlined),
                      _label('Pincode'),
                      _textField('Pincode', _pincodeCtrl,
                          keyboard: TextInputType.number,
                          icon: Icons.pin_drop_outlined),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _textField(
    String hint,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator:
          required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _dobPicker() {
    return GestureDetector(
      onTap: _pickDob,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              _dob != null
                  ? DateFormat('dd MMM yyyy').format(_dob!)
                  : 'Select date of birth',
              style: TextStyle(
                color: _dob != null ? Colors.black87 : Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
      ],
      onChanged: (v) => setState(() => _status = v ?? 'active'),
    );
  }
}
