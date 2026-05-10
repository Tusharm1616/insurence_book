import 'package:flutter/material.dart';
import '../models/customer_model.dart';

const Color _headerColor = Color(0xFF0D6B7A);

// Indian states list
const List<String> _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
  'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
  'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
  'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
];

// Indian cities by state (simplified)
const Map<String, List<String>> _citiesByState = {
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad', 'Thane', 'Kolhapur'],
  'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Gandhinagar'],
  'Delhi': ['New Delhi', 'Dwarka', 'Rohini', 'Noida', 'Gurugram'],
  'Karnataka': ['Bengaluru', 'Mysuru', 'Hubli', 'Mangaluru', 'Belagavi'],
  'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Tiruchirappalli'],
  'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer'],
  'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Allahabad', 'Meerut'],
  'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri'],
  'Telangana': ['Hyderabad', 'Warangal', 'Karimnagar', 'Nizamabad', 'Khammam'],
  'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior', 'Ujjain'],
  'Punjab': ['Ludhiana', 'Amritsar', 'Chandigarh', 'Jalandhar', 'Patiala'],
  'Haryana': ['Gurugram', 'Faridabad', 'Ambala', 'Rohtak', 'Panipat'],
  'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia'],
  'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Tirupati', 'Kurnool'],
  'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam'],
};

class CorporateMemberForm {
  final TextEditingController companyName = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController annualIncome = TextEditingController();
  final TextEditingController panNo = TextEditingController();
  final TextEditingController gstNo = TextEditingController();
  String? state;
  String? city;

  CorporateMemberForm();

  void dispose() {
    companyName.dispose();
    mobile.dispose();
    email.dispose();
    address.dispose();
    annualIncome.dispose();
    panNo.dispose();
    gstNo.dispose();
  }
}

class AddCorporateMemberScreen extends StatefulWidget {
  final Customer customer;

  const AddCorporateMemberScreen({super.key, required this.customer});

  @override
  State<AddCorporateMemberScreen> createState() => _AddCorporateMemberScreenState();
}

class _AddCorporateMemberScreenState extends State<AddCorporateMemberScreen> {
  final List<CorporateMemberForm> _members = [CorporateMemberForm()];
  bool _isSaving = false;

  @override
  void dispose() {
    for (final m in _members) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMember() => setState(() => _members.add(CorporateMemberForm()));

  void _removeMember(int index) {
    _members[index].dispose();
    setState(() => _members.removeAt(index));
  }

  Future<void> _save() async {
    for (final m in _members) {
      if (m.companyName.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company Name is required for all members'), backgroundColor: Colors.red),
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
          Text('${_members.length} corporate member(s) saved!'),
        ]),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Add Corporate Member', style: TextStyle(fontWeight: FontWeight.bold)),
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
                label: const Text('Add New Corporate Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
    final cities = _citiesByState[m.state] ?? [];

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Corporate Member ${index + 1}',
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

          // Company Name
          _inputField(m.companyName, hint: 'Company Name*'),
          const SizedBox(height: 10),

          // Mobile & Email
          Row(children: [
            Expanded(child: _inputField(m.mobile, hint: 'Mobile', keyboard: TextInputType.phone)),
            const SizedBox(width: 10),
            Expanded(child: _inputField(m.email, hint: 'Email', keyboard: TextInputType.emailAddress)),
          ]),
          const SizedBox(height: 10),

          // State dropdown
          _stateDropdown(m),
          const SizedBox(height: 10),

          // City dropdown (depends on state)
          _cityDropdown(m, cities),
          const SizedBox(height: 10),

          // Address
          _inputField(m.address, hint: 'Address', maxLines: 2),
          const SizedBox(height: 10),

          // Annual Income
          _inputField(m.annualIncome, hint: 'Annual Income', keyboard: TextInputType.number),
          const SizedBox(height: 10),

          // PAN & GST
          Row(children: [
            Expanded(child: _inputField(m.panNo, hint: 'Pan No')),
            const SizedBox(width: 10),
            Expanded(child: _inputField(m.gstNo, hint: 'GST No')),
          ]),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, {String? hint, TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
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

  Widget _stateDropdown(CorporateMemberForm m) {
    return DropdownButtonFormField<String>(
      initialValue: m.state,
      hint: const Text('State', style: TextStyle(color: Colors.grey, fontSize: 14)),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: _headerColor, width: 1.5)),
      ),
      items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (v) => setState(() {
        m.state = v;
        m.city = null; // reset city when state changes
      }),
    );
  }

  Widget _cityDropdown(CorporateMemberForm m, List<String> cities) {
    if (m.state == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text('Select state first', style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    if (cities.isEmpty) {
      return _inputField(TextEditingController(text: m.city), hint: 'Enter city');
    }

    return DropdownButtonFormField<String>(
      initialValue: m.city,
      hint: const Text('City', style: TextStyle(color: Colors.grey, fontSize: 14)),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: _headerColor, width: 1.5)),
      ),
      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (v) => setState(() => m.city = v),
    );
  }
}
