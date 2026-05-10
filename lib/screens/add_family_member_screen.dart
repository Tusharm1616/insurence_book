import 'package:flutter/material.dart';
import '../models/customer_model.dart';

const Color _headerColor = Color(0xFF0D6B7A);

class FamilyMemberForm {
  final TextEditingController fullName = TextEditingController();
  final TextEditingController mobileNumber = TextEditingController();
  final TextEditingController panNo = TextEditingController();
  final TextEditingController aadhaarNo = TextEditingController();
  DateTime? birthDate;
  DateTime? drivingLicenceExpiry;
  String? gender;
  String? height;
  String? weight;
  String? relationship;

  FamilyMemberForm();

  void dispose() {
    fullName.dispose();
    mobileNumber.dispose();
    panNo.dispose();
    aadhaarNo.dispose();
  }
}

class AddFamilyMemberScreen extends StatefulWidget {
  final Customer customer;

  const AddFamilyMemberScreen({super.key, required this.customer});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final List<FamilyMemberForm> _members = [FamilyMemberForm()];
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _heights = [
    "4'0\"", "4'6\"", "4'8\"", "4'10\"", "5'0\"", "5'1\"", "5'2\"",
    "5'3\"", "5'4\"", "5'5\"", "5'6\"", "5'7\"", "5'8\"", "5'9\"",
    "5'10\"", "5'11\"", "6'0\"", "6'1\"", "6'2\"", "6'3\"",
  ];
  final List<String> _weights = List.generate(100, (i) => '${40 + i} kg');
  final List<String> _relationships = [
    'Spouse', 'Son', 'Daughter', 'Father', 'Mother',
    'Brother', 'Sister', 'Grandfather', 'Grandmother', 'Other',
  ];

  @override
  void dispose() {
    for (final m in _members) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMember() => setState(() => _members.add(FamilyMemberForm()));

  void _removeMember(int index) {
    _members[index].dispose();
    setState(() => _members.removeAt(index));
  }

  Future<void> _save() async {
    // Validate all full names
    for (final m in _members) {
      if (m.fullName.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Full Name is required for all members'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    // Backend API integration pending — endpoint not yet available
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text('${_members.length} family member(s) saved!'),
        ]),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickDate(FamilyMemberForm member, bool isBirth) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isBirth ? DateTime(1990) : now,
      firstDate: isBirth ? DateTime(1920) : now,
      lastDate: isBirth ? now : DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _headerColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          member.birthDate = picked;
        } else {
          member.drivingLicenceExpiry = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Add Family Member', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add New Member Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add New Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          // Members List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: _members.length,
              itemBuilder: (context, index) => _buildMemberCard(index),
            ),
          ),
        ],
      ),

      // Save Button
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _headerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(int index) {
    final m = _members[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Family Member ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _headerColor),
              ),
              if (_members.length > 1)
                GestureDetector(
                  onTap: () => _removeMember(index),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Full Name
          _inputField('Full Name*', m.fullName, hint: 'Full Name*'),
          const SizedBox(height: 10),

          // Mobile Number
          _inputField('Mobile Number', m.mobileNumber, hint: 'Mobile Number', keyboard: TextInputType.phone),
          const SizedBox(height: 10),

          // Birth Date
          _datePicker('Birth Date', m.birthDate, () => _pickDate(m, true)),
          const SizedBox(height: 10),

          // Driving Licence Expiry
          _datePicker('Driving Licence Expire Date', m.drivingLicenceExpiry, () => _pickDate(m, false)),
          const SizedBox(height: 10),

          // Gender & Height
          Row(children: [
            Expanded(child: _dropdownField('Gender', m.gender, _genders, (v) => setState(() => m.gender = v))),
            const SizedBox(width: 10),
            Expanded(child: _dropdownField('Height', m.height, _heights, (v) => setState(() => m.height = v))),
          ]),
          const SizedBox(height: 10),

          // Weight & Relationship
          Row(children: [
            Expanded(child: _dropdownField('Weigh...', m.weight, _weights, (v) => setState(() => m.weight = v))),
            const SizedBox(width: 10),
            Expanded(child: _dropdownField('Relationship', m.relationship, _relationships, (v) => setState(() => m.relationship = v))),
          ]),
          const SizedBox(height: 10),

          // PAN No
          _inputField('Pan No', m.panNo, hint: 'Pan No'),
          const SizedBox(height: 10),

          // Aadhaar No
          _inputField('Aadhaar No', m.aadhaarNo, hint: 'Aadhaar No', keyboard: TextInputType.number),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint ?? label,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: _headerColor, width: 1.5)),
      ),
    );
  }

  Widget _datePicker(String hint, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                    : hint,
                style: TextStyle(
                  color: date != null ? Colors.black87 : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: _headerColor, width: 1.5)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }
}
