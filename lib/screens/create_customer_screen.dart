import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import 'customer_options_screen.dart';

class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  ConsumerState<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends ConsumerState<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime? _dob;
  DateTime? _anniversary;
  String? _occupation;

  final List<String> _occupations = [
    'Software Engineer', 'Doctor', 'Teacher', 'Business Owner', 'Student', 'Homemaker', 'Other'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date of Birth is required'), backgroundColor: Colors.red));
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch;
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();

    final username = name.toLowerCase().replaceAll(' ', '.') + id.toString().substring(8);
    final password = 'Cust@${mobile.length >= 4 ? mobile.substring(mobile.length - 4) : '0000'}';

    final newCustomer = Customer(
      id: id,
      fullName: name,
      mobileNumber: mobile,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      dob: _dob,
      anniversaryDate: _anniversary,
      businessJobType: _occupation,
      generatedUsername: username,
      generatedPassword: password,
      isActive: true,
      gender: 'Male', // defaults
      maritalStatus: 'Single',
    );

    try {
      final savedCustomer = await ref.read(customerProvider.notifier).addCustomer(newCustomer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Customer saved successfully!')]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Redirect to Customer Options screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerOptionsScreen(customer: savedCustomer),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save customer: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickDate({required bool isDob}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.green)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _dob = picked;
        } else {
          _anniversary = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Customer', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        const Text('Fields marked * are required', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _label('Full Name', isRequired: true),
              _textField('Enter customer\'s full name', _nameCtrl, required: true),

              _label('Phone Number', isRequired: true),
              _phoneField(),

              _label('Email Address', isOptional: true),
              _textField(
                'Enter email address', 
                _emailCtrl, 
                prefixIcon: LucideIcons.mail, 
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
              ),

              _label('Date of Birth', isRequired: true),
              _dateCard('Date of Birth', LucideIcons.calendar, _dob, Colors.green, isDob: true),

              _label('Anniversary Date', isOptional: true),
              _dateCard('Anniversary Date', LucideIcons.heart, _anniversary, Colors.pink, isDob: false),

              _label('Address', isOptional: true),
              _textField('Full address with city & PIN code', _addressCtrl, maxLines: 3),

              _label('Occupation', isOptional: true),
              _dropdownField(),

              const SizedBox(height: 32),
              
              // Add Customer Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Add Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _label(String title, {bool isRequired = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: RichText(
        text: TextSpan(
          text: title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          children: [
            if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (isOptional) const TextSpan(text: ' optional', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _textField(String hint, TextEditingController ctrl, {bool required = false, int maxLines = 1, IconData? prefixIcon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.green, width: 1.5)),
      ),
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _mobileCtrl,
      keyboardType: TextInputType.phone,
      validator: (v) => (v == null || v.length < 10) ? 'Enter valid 10-digit number' : null,
      decoration: InputDecoration(
        hintText: '10-digit mobile number',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [Text('+91', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))],
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.green, width: 1.5)),
      ),
    );
  }

  Widget _dateCard(String title, IconData icon, DateTime? date, Color color, {required bool isDob}) {
    return GestureDetector(
      onTap: () => _pickDate(isDob: isDob),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}' : 'Tap to select',
                    style: TextStyle(fontSize: 14, fontWeight: date != null ? FontWeight.bold : FontWeight.w500, color: date != null ? Colors.black87 : Colors.blueGrey),
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

  Widget _dropdownField() {
    return DropdownButtonFormField<String>(
      initialValue: _occupation,
      hint: const Text('Select Occupation', style: TextStyle(color: Colors.grey, fontSize: 14)),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      decoration: InputDecoration(
        prefixIcon: const Icon(LucideIcons.briefcase, size: 18, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.green, width: 1.5)),
      ),
      items: _occupations.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (v) => setState(() => _occupation = v),
    );
  }
}
