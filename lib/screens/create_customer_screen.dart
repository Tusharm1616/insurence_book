import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';

// ── All Indian States + UTs ──────────────────────────────────────────────────
const List<String> kAllStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  // Union Territories
  'Andaman & Nicobar Islands',
  'Chandigarh',
  'Dadra & Nagar Haveli and Daman & Diu',
  'Delhi',
  'Jammu & Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

// ── Cities mapped to each state ──────────────────────────────────────────────
const Map<String, List<String>> kStateCities = {
  'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Tirupati', 'Kakinada', 'Rajahmundry'],
  'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro'],
  'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon', 'Tinsukia', 'Tezpur'],
  'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia', 'Darbhanga', 'Bihar Sharif', 'Arrah'],
  'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg', 'Rajnandgaon', 'Jagdalpur'],
  'Goa': ['Panaji', 'Vasco da Gama', 'Margao', 'Mapusa', 'Ponda', 'Bicholim'],
  'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar', 'Anand', 'Morbi'],
  'Haryana': ['Faridabad', 'Gurugram', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal', 'Sonipat'],
  'Himachal Pradesh': ['Shimla', 'Solan', 'Mandi', 'Dharamshala', 'Kullu', 'Manali', 'Hamirpur'],
  'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Phusro', 'Hazaribagh'],
  'Karnataka': ['Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi', 'Davangere', 'Ballari', 'Tumkur'],
  'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam', 'Palakkad', 'Alappuzha', 'Kannur'],
  'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Ratlam', 'Satna'],
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad', 'Solapur', 'Kolhapur', 'Amravati', 'Thane', 'Navi Mumbai'],
  'Manipur': ['Imphal', 'Thoubal', 'Bishnupur', 'Churachandpur', 'Kakching'],
  'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Nongstoin', 'Baghmara'],
  'Mizoram': ['Aizawl', 'Lunglei', 'Champhai', 'Serchhip', 'Kolasib'],
  'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Wokha', 'Zunheboto'],
  'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Brahmapur', 'Sambalpur', 'Puri', 'Balasore'],
  'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Hoshiarpur', 'Gurdaspur'],
  'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer', 'Bhilwara', 'Alwar'],
  'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing', 'Mangan'],
  'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Vellore', 'Erode'],
  'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam', 'Ramagundam', 'Mahbubnagar'],
  'Tripura': ['Agartala', 'Dharmanagar', 'Udaipur', 'Kailashahar', 'Belonia'],
  'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Allahabad', 'Meerut', 'Ghaziabad', 'Noida', 'Bareilly', 'Aligarh'],
  'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Haldwani', 'Rishikesh', 'Nainital', 'Mussoorie'],
  'West Bengal': ['Kolkata', 'Asansol', 'Siliguri', 'Durgapur', 'Bardhaman', 'Malda', 'Baharampur', 'Howrah'],
  'Andaman & Nicobar Islands': ['Port Blair', 'Rangat', 'Diglipur', 'Car Nicobar'],
  'Chandigarh': ['Chandigarh'],
  'Dadra & Nagar Haveli and Daman & Diu': ['Silvassa', 'Daman', 'Diu'],
  'Delhi': ['New Delhi', 'Dwarka', 'Rohini', 'Janakpuri', 'Lajpat Nagar', 'Saket', 'Pitampura', 'Shahdara'],
  'Jammu & Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Sopore', 'Kathua', 'Udhampur'],
  'Ladakh': ['Leh', 'Kargil'],
  'Lakshadweep': ['Kavaratti', 'Andrott', 'Minicoy'],
  'Puducherry': ['Puducherry', 'Karaikal', 'Mahe', 'Yanam'],
};

class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  ConsumerState<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends ConsumerState<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Basic ─────────────────────────────────────────────────────────────
  String _customerType = 'Individual';
  String _subAgent = 'Self';

  // ── Personal Detail ───────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _selectedState;
  String? _selectedCity;
  final _addressCtrl = TextEditingController();
  DateTime? _dob;
  DateTime? _anniversary;

  // ── Personal Info ─────────────────────────────────────────────────────
  String _gender = 'Male';
  String _height = "5'5\"";
  final _weightCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  String _maritalStatus = 'Single';

  // ── Business/Job ──────────────────────────────────────────────────────
  String _jobType = 'Salaried';
  final _jobNameCtrl = TextEditingController();
  final _dutyTypeCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  List<String> get _citiesForState =>
      _selectedState != null ? (kStateCities[_selectedState!] ?? []) : [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _weightCtrl.dispose();
    _educationCtrl.dispose();
    _jobNameCtrl.dispose();
    _dutyTypeCtrl.dispose();
    _incomeCtrl.dispose();
    _panCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Build a unique ID from timestamp
    final id = DateTime.now().millisecondsSinceEpoch;
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();

    // Generate simple credentials
    final username = name.toLowerCase().replaceAll(' ', '.') + id.toString().substring(8);
    final password = 'Cust@${mobile.length >= 4 ? mobile.substring(mobile.length - 4) : '0000'}';

    final newCustomer = Customer(
      id: id,
      fullName: name,
      mobileNumber: mobile,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      state: _selectedState,
      city: _selectedCity,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      gender: _gender,
      maritalStatus: _maritalStatus,
      jobType: _jobType,
      panNo: _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
      generatedUsername: username,
      generatedPassword: password,
      isActive: true,
    );

    // Push to provider — dashboard & customer list update instantly
    await ref.read(customerProvider.notifier).addCustomer(newCustomer);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Customer saved successfully!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Go back to dashboard
    Navigator.pop(context);
  }

  // ── Date Picker ───────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isDob}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
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
      appBar: AppBar(
        title: const Text('Create Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Customer Type ──────────────────────────────────────
              _sectionHeader('Customer Type'),
              RadioGroup<String>(
                groupValue: _customerType,
                onChanged: (v) => setState(() => _customerType = v!),
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'Individual',
                      activeColor: AppColors.primary,
                    ),
                    const Text('Individual'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'Corporate',
                      activeColor: AppColors.primary,
                    ),
                    const Text('Corporate'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _label('Sub Agent'),
              _dropdown(
                value: _subAgent,
                items: const ['Self', 'Sub Agent 1', 'Sub Agent 2'],
                onChanged: (v) => setState(() => _subAgent = v!),
              ),

              // ── Personal Detail ────────────────────────────────────
              const SizedBox(height: 24),
              _sectionHeader('Personal Detail'),
              _textField('Full Name*', LucideIcons.user, _nameCtrl, required: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _textField('Mobile Number*', LucideIcons.phone, _mobileCtrl, keyboardType: TextInputType.phone, required: true)),
                const SizedBox(width: 12),
                Expanded(child: _textField('Email', LucideIcons.mail, _emailCtrl, keyboardType: TextInputType.emailAddress)),
              ]),
              const SizedBox(height: 16),

              // State
              _label('State'),
              _dropdown(
                value: _selectedState,
                hint: 'Select State',
                items: kAllStates,
                onChanged: (v) => setState(() {
                  _selectedState = v;
                  _selectedCity = null; // reset city when state changes
                }),
              ),
              const SizedBox(height: 16),

              // City (filtered by state)
              _label('City'),
              _dropdown(
                value: _selectedCity,
                hint: _selectedState == null ? 'Select State First' : 'Select City',
                items: _citiesForState,
                onChanged: _selectedState == null ? null : (v) => setState(() => _selectedCity = v),
              ),
              const SizedBox(height: 16),

              _textField('Address', LucideIcons.mapPin, _addressCtrl, maxLines: 2),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _datePicker('Date of Birth', LucideIcons.calendar, _dob, isDob: true)),
                const SizedBox(width: 12),
                Expanded(child: _datePicker('Anniversary Date', LucideIcons.heart, _anniversary, isDob: false)),
              ]),

              // ── Personal Info ──────────────────────────────────────
              const SizedBox(height: 24),
              _sectionHeader('Personal Info'),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Gender'),
                  _dropdown(
                    value: _gender,
                    items: const ['Male', 'Female', 'Other'],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Height'),
                  _dropdown(
                    value: _height,
                    items: const ["4'8\"", "4'10\"", "5'0\"", "5'1\"", "5'2\"", "5'3\"", "5'4\"", "5'5\"", "5'6\"", "5'7\"", "5'8\"", "5'9\"", "5'10\"", "5'11\"", "6'0\"", "6'1\"", "6'2\""],
                    onChanged: (v) => setState(() => _height = v!),
                  ),
                ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _textField('Weight (kg)', LucideIcons.activity, _weightCtrl, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _textField('Education', LucideIcons.graduationCap, _educationCtrl)),
              ]),
              const SizedBox(height: 16),
              _label('Marital Status'),
              _dropdown(
                value: _maritalStatus,
                items: const ['Single', 'Married', 'Divorced', 'Widowed'],
                onChanged: (v) => setState(() => _maritalStatus = v!),
              ),

              // ── Business/Job ───────────────────────────────────────
              const SizedBox(height: 24),
              _sectionHeader('Business/Job'),
              _label('Business/Job Type'),
              _dropdown(
                value: _jobType,
                items: const ['Salaried', 'Self Employed', 'Business', 'Retired', 'Student', 'Homemaker', 'Other'],
                onChanged: (v) => setState(() => _jobType = v!),
              ),
              const SizedBox(height: 16),
              _textField('Name of Business/Job', LucideIcons.briefcase, _jobNameCtrl),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _textField('Type of Duty', LucideIcons.wrench, _dutyTypeCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _textField('Annual Income', LucideIcons.dollarSign, _incomeCtrl, keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _textField('Pan No', LucideIcons.creditCard, _panCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _textField('GST No', LucideIcons.hash, _gstCtrl)),
              ]),

              // ── Profile Image ──────────────────────────────────────
              const SizedBox(height: 24),
              _sectionHeader('Profile Image'),
              _imageUploadBox(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // ── Sticky Save Button ─────────────────────────────────────────
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Save'),
          ),
        ),
      ),
    );
  }

  // ── Reusable Widgets ─────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      );

  Widget _textField(String hint, IconData icon, TextEditingController ctrl,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$hint is required' : null
          : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    String? hint,
  }) {
    // Ensure value is in items list, else null
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: onChanged == null ? Colors.grey.shade100 : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: Text(hint ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _datePicker(String hint, IconData icon, DateTime? date, {required bool isDob}) {
    return GestureDetector(
      onTap: () => _pickDate(isDob: isDob),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: date != null ? AppColors.primary : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                    : hint,
                style: TextStyle(
                  color: date != null ? AppColors.textPrimary : Colors.grey,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageUploadBox() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.camera, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Upload Profile Image', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
