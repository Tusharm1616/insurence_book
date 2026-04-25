import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/policy_model.dart';
import '../providers/policy_provider.dart';
import '../providers/customer_provider.dart';

// ─── 3-Step Policy Wizard ─────────────────────────────────────────────────────

class AddPolicyWizard extends ConsumerStatefulWidget {
  final String policyType;
  final Color color;
  final IconData icon;
  final int? prefilledCustomerId;
  final String? prefilledCustomerName;

  const AddPolicyWizard({
    super.key,
    required this.policyType,
    required this.color,
    required this.icon,
    this.prefilledCustomerId,
    this.prefilledCustomerName,
  });

  @override
  ConsumerState<AddPolicyWizard> createState() => _AddPolicyWizardState();
}

class _AddPolicyWizardState extends ConsumerState<AddPolicyWizard> {
  int _currentStep = 0;
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // ── Step 1: Client Detail ─────────────────────────────────────────────────
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _policyHolder;
  String _subAgent = 'Self';
  final _referenceCtrl = TextEditingController();
  final _brokerCtrl = TextEditingController();

  // ── Step 2: Policy Details ─────────────────────────────────────────────────
  final _companyCtrl = TextEditingController();
  final _policyNoCtrl = TextEditingController();
  DateTime _bookingDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  String _paymentMode = 'Yearly';
  String _claimProcess = 'Cashless';
  final _sumInsuredCtrl = TextEditingController();
  final _netPremiumCtrl = TextEditingController();
  final _deductibleCtrl = TextEditingController(text: '0');
  final _bonusCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();

  // ── Step 3: Commission Details ─────────────────────────────────────────────
  final _mainCommPctCtrl = TextEditingController(text: '10');
  final _mainTdsPctCtrl = TextEditingController(text: '0');
  final _subCommPctCtrl = TextEditingController(text: '0');
  final _subTdsPctCtrl = TextEditingController(text: '0');

  // ── Computed values ────────────────────────────────────────────────────────
  double get _netPremium => double.tryParse(_netPremiumCtrl.text) ?? 0;
  double get _totalPremium => _netPremium * 1.18;
  double get _mainCommAmt => _netPremium * (double.tryParse(_mainCommPctCtrl.text) ?? 0) / 100;
  double get _mainTdsAmt => _mainCommAmt * (double.tryParse(_mainTdsPctCtrl.text) ?? 0) / 100;
  double get _mainAfterTds => _mainCommAmt - _mainTdsAmt;
  double get _subCommAmt => _netPremium * (double.tryParse(_subCommPctCtrl.text) ?? 0) / 100;
  double get _subTdsAmt => _subCommAmt * (double.tryParse(_subTdsPctCtrl.text) ?? 0) / 100;
  double get _subAfterTds => _subCommAmt - _subTdsAmt;

  int get _policyTermYears => ((_endDate.difference(_startDate).inDays) / 365).round();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCustomerId != null) {
      _selectedCustomerId = widget.prefilledCustomerId;
      _selectedCustomerName = widget.prefilledCustomerName;
      _policyHolder = widget.prefilledCustomerName;
    }
    _netPremiumCtrl.addListener(() => setState(() {}));
    _mainCommPctCtrl.addListener(() => setState(() {}));
    _mainTdsPctCtrl.addListener(() => setState(() {}));
    _subCommPctCtrl.addListener(() => setState(() {}));
    _subTdsPctCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _referenceCtrl.dispose(); _brokerCtrl.dispose();
    _companyCtrl.dispose(); _policyNoCtrl.dispose();
    _sumInsuredCtrl.dispose(); _netPremiumCtrl.dispose();
    _deductibleCtrl.dispose(); _bonusCtrl.dispose(); _noteCtrl.dispose();
    _mainCommPctCtrl.dispose(); _mainTdsPctCtrl.dispose();
    _subCommPctCtrl.dispose(); _subTdsPctCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 0) {
      if (_selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      if (_step1Key.currentState?.validate() ?? false) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_step2Key.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    } else {
      if (_step3Key.currentState?.validate() ?? false) {
        _save();
      }
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    final policy = Policy(
      id: DateTime.now().millisecondsSinceEpoch,
      customerId: _selectedCustomerId,
      policyType: widget.policyType,
      policyNumber: _policyNoCtrl.text.trim(),
      insuranceCompany: _companyCtrl.text.trim(),
      sumInsured: double.tryParse(_sumInsuredCtrl.text) ?? 0,
      premium: _netPremium,
      startDate: _startDate,
      expiryDate: _endDate,
      extraData: {
        'customerName': _selectedCustomerName ?? '',
        'policyHolder': _policyHolder ?? '',
        'subAgent': _subAgent,
        'referenceBy': _referenceCtrl.text,
        'broker': _brokerCtrl.text,
        'paymentMode': _paymentMode,
        'claimProcess': _claimProcess,
        'totalPremium': _totalPremium.toStringAsFixed(2),
        'deductible': _deductibleCtrl.text,
        'bonus': _bonusCtrl.text,
        'note': _noteCtrl.text,
        'mainCommPct': _mainCommPctCtrl.text,
        'mainCommAmt': _mainCommAmt.toStringAsFixed(2),
        'mainTdsPct': _mainTdsPctCtrl.text,
        'mainTdsAmt': _mainTdsAmt.toStringAsFixed(2),
        'mainAfterTds': _mainAfterTds.toStringAsFixed(2),
      },
    );

    await ref.read(policyProvider.notifier).addPolicy(policy);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Text('${widget.policyType} saved successfully!'),
      ]),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));

    // Pop wizard + type selection back to dashboard
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = ['Client Detail', '${widget.policyType} Details', 'Commission Details'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(stepTitles[_currentStep], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: Column(
        children: [
          _buildStepProgress(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: [_buildStep1(), _buildStep2(), _buildStep3()][_currentStep],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Step Progress Indicator ────────────────────────────────────────────────
  Widget _buildStepProgress() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          final stepColor = done || active ? widget.color : Colors.grey.shade300;
          return Expanded(
            child: Row(children: [
              // Circle
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: done || active ? widget.color : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text('${i + 1}', style: TextStyle(color: active ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              // Line (except last)
              if (i < 2) Expanded(child: Container(height: 2, color: stepColor, margin: const EdgeInsets.symmetric(horizontal: 4))),
            ]),
          );
        }),
      ),
    );
  }

  // ── Header Icon ───────────────────────────────────────────────────────────
  Widget _buildHeaderIcon(String subtitle) {
    return Column(children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(20)),
        child: Icon(widget.icon, size: 40, color: Colors.white),
      ),
      const SizedBox(height: 14),
      Text(
        ['Client Detail', '${widget.policyType} Details', 'Commission Details'][_currentStep],
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.color),
      ),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 20),
    ]);
  }

  // ── STEP 1: Client Information ─────────────────────────────────────────────
  Widget _buildStep1() {
    final customers = ref.watch(customerProvider).asData?.value ?? [];

    return Form(
      key: _step1Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeaderIcon('Step 1: Client Information'),

        _label('Client Name *'),
        DropdownButtonFormField<int>(
          initialValue: _selectedCustomerId,
          hint: const Row(children: [
            Icon(LucideIcons.user, size: 18, color: Colors.grey),
            SizedBox(width: 8),
            Text('Select Client', style: TextStyle(color: Colors.grey)),
          ]),
          validator: (v) => v == null ? 'Please select a client' : null,
          onChanged: (v) {
            if (v == null) return;
            final c = customers.firstWhere((c) => c.id == v);
            setState(() {
              _selectedCustomerId = v;
              _selectedCustomerName = c.fullName;
              _policyHolder = c.fullName;
            });
          },
          items: customers.isEmpty
              ? [const DropdownMenuItem(value: -1, child: Text('No customers found'))]
              : customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullName))).toList(),
          decoration: _ddDecoration(),
        ),
        if (_selectedCustomerId == null) Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text('Please select a client', style: TextStyle(color: Colors.red.shade700, fontSize: 11)),
        ),
        const SizedBox(height: 16),

        _label('Policy Holder *'),
        DropdownButtonFormField<String>(
          initialValue: _policyHolder,
          hint: const Text('Select Policy Holder *', style: TextStyle(color: Colors.grey)),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          onChanged: (v) => setState(() => _policyHolder = v),
          items: [
            if (_selectedCustomerName != null)
              DropdownMenuItem(value: _selectedCustomerName, child: Text(_selectedCustomerName!)),
            ...['Self', 'Spouse', 'Parent', 'Child', 'Business'].map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          decoration: _ddDecoration(),
        ),
        const SizedBox(height: 16),

        _label('Sub Agent *'),
        DropdownButtonFormField<String>(
          initialValue: _subAgent,
          onChanged: (v) => setState(() => _subAgent = v!),
          items: ['Self', 'Agent 1', 'Agent 2', 'Agent 3'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          decoration: _ddDecoration(),
        ),
        const SizedBox(height: 16),

        _label('Reference By Name'),
        _tf(_referenceCtrl, 'Enter reference name', LucideIcons.userCheck),
        const SizedBox(height: 16),

        _label('Broker Name'),
        _tf(_brokerCtrl, 'Enter broker name', LucideIcons.building2),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── STEP 2: Policy Details ─────────────────────────────────────────────────
  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeaderIcon('Step 2: Policy Information'),

        _label('Insurance Company *'),
        _tf(_companyCtrl, 'Enter insurance company name', LucideIcons.building2, required: true),
        const SizedBox(height: 16),

        _label('Policy Number *'),
        _tf(_policyNoCtrl, 'Enter policy number', LucideIcons.hash, required: true),
        const SizedBox(height: 16),

        _label('Policy Booking Date'),
        _dp(_bookingDate, (d) => setState(() => _bookingDate = d)),
        const SizedBox(height: 16),

        _label('Policy Start Date *'),
        _dp(_startDate, (d) => setState(() { _startDate = d; if (_endDate.isBefore(d)) _endDate = d.add(const Duration(days: 365)); })),
        const SizedBox(height: 16),

        _label('Policy End Date *'),
        _dp(_endDate, (d) => setState(() => _endDate = d)),
        const SizedBox(height: 16),

        _label('Policy Term'),
        _readonlyTile('$_policyTermYears Year${_policyTermYears != 1 ? 's' : ''}', LucideIcons.clock, 'Auto-calculated from dates'),
        const SizedBox(height: 16),

        _label('Payment Mode *'),
        DropdownButtonFormField<String>(
          initialValue: _paymentMode,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          onChanged: (v) => setState(() => _paymentMode = v!),
          items: ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly', 'Single Premium'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          decoration: _ddDecoration(),
        ),
        const SizedBox(height: 16),

        _label('Claim Process'),
        DropdownButtonFormField<String>(
          initialValue: _claimProcess,
          onChanged: (v) => setState(() => _claimProcess = v!),
          items: ['Cashless', 'Reimbursement', 'Both'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          decoration: _ddDecoration(),
        ),
        const SizedBox(height: 16),

        _label('Sum Insured (₹)'),
        _tf(_sumInsuredCtrl, 'Enter sum insured amount', LucideIcons.indianRupee, keyboardType: TextInputType.number),
        const SizedBox(height: 16),

        _label('Net Premium *'),
        _tf(_netPremiumCtrl, 'Enter net premium amount', LucideIcons.dollarSign, keyboardType: TextInputType.number, required: true),
        const SizedBox(height: 16),

        _label('Total Premium *'),
        _readonlyTile('₹${_totalPremium.toStringAsFixed(2)}', LucideIcons.indianRupee, 'Net Premium + 18% GST'),
        const SizedBox(height: 16),

        _label('Deductible Amount'),
        _tf(_deductibleCtrl, '0', LucideIcons.minusCircle, keyboardType: TextInputType.number),
        const SizedBox(height: 16),

        _label('Bonus Amount'),
        _tf(_bonusCtrl, '0', LucideIcons.plusCircle, keyboardType: TextInputType.number),
        const SizedBox(height: 16),

        _label('Extra Note'),
        _tf(_noteCtrl, 'Enter any additional notes here...', LucideIcons.fileText, maxLines: 3),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── STEP 3: Commission Details ─────────────────────────────────────────────
  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeaderIcon('Step 3: Commission Information'),

        // Policy summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Policy Information', style: TextStyle(fontWeight: FontWeight.bold, color: widget.color, fontSize: 14)),
            const Divider(height: 14),
            _summaryRow('Total Premium', '₹${_totalPremium.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _summaryRow('Net Premium', '₹${_netPremium.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _summaryRow('Policy Holder', _policyHolder ?? '–'),
            const SizedBox(height: 4),
            _summaryRow('Client', _selectedCustomerName ?? '–'),
          ]),
        ),

        // Main Agent Section
        _sectionHeader('Main Agent Commission Calculation'),
        const SizedBox(height: 12),
        _label('Main Agent Commission %'),
        _tf(_mainCommPctCtrl, '10', LucideIcons.percent, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _label('Main Agent Commission Amount'),
        _readonlyTile('₹${_mainCommAmt.toStringAsFixed(2)}', LucideIcons.indianRupee, 'Auto-calculated'),
        const SizedBox(height: 12),
        _label('Main Agent TDS %'),
        _tf(_mainTdsPctCtrl, 'Enter TDS percentage', LucideIcons.percent, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _label('Main Agent TDS Amount'),
        _readonlyTile('₹${_mainTdsAmt.toStringAsFixed(2)}', LucideIcons.indianRupee, 'Auto-calculated'),
        const SizedBox(height: 12),
        _label('Main Agent After TDS Amount'),
        _readonlyTile('₹${_mainAfterTds.toStringAsFixed(2)}', LucideIcons.indianRupee, 'Auto-calculated'),
        const SizedBox(height: 20),

        // Sub Agent Section
        _sectionHeader('Sub Agent Commission Calculation'),
        const SizedBox(height: 12),
        _label('Sub Agent Commission %'),
        _tf(_subCommPctCtrl, '0', LucideIcons.percent, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _label('Sub Agent Commission Amount'),
        _readonlyTile('₹${_subCommAmt.toStringAsFixed(2)}', LucideIcons.indianRupee, 'Auto-calculated'),
        const SizedBox(height: 12),
        _label('Sub Agent TDS %'),
        _tf(_subTdsPctCtrl, 'Enter TDS percentage', LucideIcons.percent, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _label('Sub Agent TDS Amount'),
        _readonlyTile('₹${_subTdsAmt.toStringAsFixed(2)}', LucideIcons.indianRupee, 'Auto-calculated'),
        const SizedBox(height: 12),
        _label('Sub Agent After TDS Amount'),
        _readonlyTile('₹${_subAfterTds.toStringAsFixed(2)}', LucideIcons.indianRupee, 'Auto-calculated'),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Row(children: [
        if (_currentStep > 0) ...[
          Expanded(child: OutlinedButton(
            onPressed: _back,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: widget.color),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Back', style: TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 16)),
          )),
          const SizedBox(width: 12),
        ],
        Expanded(child: ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: Text(_currentStep == 2 ? 'Save Policy' : 'Next'),
        )),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
  );

  Widget _sectionHeader(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: widget.color, fontSize: 14)),
  );

  Widget _summaryRow(String label, String value) => Row(children: [
    Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
  ]);

  Widget _tf(TextEditingController ctrl, String hint, IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.color, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  InputDecoration _ddDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.color, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
  );

  Widget _dp(DateTime date, ValueChanged<DateTime> onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2060),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: widget.color)),
            child: child!,
          ),
        );
        if (picked != null) { onChanged(picked); }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(LucideIcons.calendar, size: 18, color: widget.color),
          const SizedBox(width: 10),
          Text(
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Icon(LucideIcons.chevronsUpDown, size: 16, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  Widget _readonlyTile(String value, IconData icon, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const Spacer(),
        Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    );
  }
}

// ─── Policy Type Selection Screen ────────────────────────────────────────────

class AddPolicyTypeScreen extends StatelessWidget {
  const AddPolicyTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final types = [
      {'title': 'Life Insurance',   'subtitle': 'Term, ULIP, Endowment, Money Back', 'icon': LucideIcons.heart,     'bgColor': Colors.pink.shade100,   'iconColor': Colors.pinkAccent, 'color': Colors.pink},
      {'title': 'Health Insurance', 'subtitle': 'Individual, Floater, Senior Citizen','icon': LucideIcons.plus,      'bgColor': Colors.green.shade100,  'iconColor': Colors.green,      'color': Colors.green},
      {'title': 'Motor Insurance',  'subtitle': 'Car, Bike, Commercial Vehicle',      'icon': LucideIcons.car,       'bgColor': Colors.orange.shade100, 'iconColor': Colors.orange,     'color': Colors.orange},
      {'title': 'WC Insurance',     'subtitle': 'Workmen Compensation Policy',        'icon': LucideIcons.briefcase, 'bgColor': Colors.purple.shade100, 'iconColor': Colors.purple,     'color': Colors.purple},
      {'title': 'Other Insurance',  'subtitle': 'Fire, Marine, Travel, Home, Crop',   'icon': LucideIcons.shield,    'bgColor': Colors.grey.shade200,   'iconColor': Colors.blueGrey,   'color': Colors.blueGrey},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Text('Select Insurance Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Choose the type of policy to add', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
              ),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final t = types[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AddPolicyWizard(
                      policyType: t['title'] as String,
                      color: t['color'] as Color,
                      icon: t['icon'] as IconData,
                    ),
                  )),
                  child: Card(
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: t['bgColor'] as Color, shape: BoxShape.circle),
                          child: Icon(t['icon'] as IconData, color: t['iconColor'] as Color, size: 36),
                        ),
                        const SizedBox(height: 14),
                        Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(t['subtitle'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 2),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
