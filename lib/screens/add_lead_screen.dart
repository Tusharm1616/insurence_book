import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../providers/lead_provider.dart';

class AddLeadScreen extends ConsumerStatefulWidget {
  const AddLeadScreen({super.key});

  @override
  ConsumerState<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends ConsumerState<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _mobile = '';
  String _email = '';
  String _insuranceType = 'Life Insurance';
  String _source = 'Walk-in';
  String _notes = '';
  LeadStatus _status = LeadStatus.newLead;
  DateTime? _followupDate;

  final List<String> _insuranceTypes = [
    'Life Insurance', 'Health Insurance', 'Motor Insurance',
    'WC Insurance', 'Other Insurance',
  ];

  final List<String> _sources = [
    'Walk-in', 'Referral', 'Online', 'Call', 'Other',
  ];

  void _saveLead() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newLead = Lead(
        id: DateTime.now().millisecondsSinceEpoch,
        name: _name,
        mobile: _mobile,
        email: _email,
        insuranceType: _insuranceType,
        source: _source,
        notes: _notes,
        status: _status,
        createdAt: DateTime.now(),
        followupDate: _status == LeadStatus.followup ? (_followupDate ?? DateTime.now().add(const Duration(days: 1))) : null,
      );

      ref.read(leadProvider.notifier).addLead(newLead);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead Added Successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Lead', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header('Basic Information', LucideIcons.userPlus),
              _label('Full Name *'),
              _tf('Enter full name', LucideIcons.user, validator: (v) => v!.isEmpty ? 'Required' : null, onSave: (v) => _name = v!),
              const SizedBox(height: 16),

              _label('Mobile Number *'),
              _tf('Enter mobile number', LucideIcons.phone, keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Enter valid number' : null, onSave: (v) => _mobile = v!),
              const SizedBox(height: 16),

              _label('Email Address'),
              _tf('Enter email (optional)', LucideIcons.mail, keyboardType: TextInputType.emailAddress, onSave: (v) => _email = v ?? ''),
              const SizedBox(height: 24),

              _header('Lead Details', LucideIcons.briefcase),
              _label('Insurance Type *'),
              DropdownButtonFormField<String>(
                initialValue: _insuranceType,
                decoration: _ddDecoration(),
                items: _insuranceTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _insuranceType = v!),
              ),
              const SizedBox(height: 16),

              _label('Lead Source *'),
              DropdownButtonFormField<String>(
                initialValue: _source,
                decoration: _ddDecoration(),
                items: _sources.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _source = v!),
              ),
              const SizedBox(height: 16),

              _label('Status *'),
              DropdownButtonFormField<LeadStatus>(
                initialValue: _status,
                decoration: _ddDecoration(),
                items: LeadStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),

              if (_status == LeadStatus.followup) ...[
                _label('Follow-up Date *'),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _followupDate ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _followupDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 12),
                        Text(
                          _followupDate == null ? 'Select Date' : '${_followupDate!.day}/${_followupDate!.month}/${_followupDate!.year}',
                          style: TextStyle(color: _followupDate == null ? Colors.grey : Colors.black87, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _label('Notes'),
              TextFormField(
                maxLines: 4,
                decoration: _ddDecoration().copyWith(hintText: 'Enter internal notes...'),
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveLead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Lead', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
  );

  Widget _tf(String hint, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator, void Function(String?)? onSave}) {
    return TextFormField(
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSave,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  InputDecoration _ddDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
