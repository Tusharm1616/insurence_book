import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/policy_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/life_report_provider.dart';
import '../providers/expiring_policies_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/policies_provider.dart';
import '../services/api_service.dart';

class AddPolicyWizard extends ConsumerStatefulWidget {
  final String policyType;
  final Color color;
  final IconData icon;
  final bool isMotor;
  final int? prefilledCustomerId;
  final String? prefilledCustomerName;

  const AddPolicyWizard({
    super.key,
    required this.policyType,
    required this.color,
    required this.icon,
    this.isMotor = false,
    this.prefilledCustomerId,
    this.prefilledCustomerName,
  });

  @override
  ConsumerState<AddPolicyWizard> createState() => _AddPolicyWizardState();
}

class _AddPolicyWizardState extends ConsumerState<AddPolicyWizard> {
  int _currentStep = 0;
  
  // -- Form Keys --
  final _clientFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();
  final _policyFormKey = GlobalKey<FormState>();

  // -- Step 1: Client --
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _policyHolder;
  final _referenceCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();

  // -- Step 2: Vehicle --
  String _vehicleType = 'Private Car';
  final _vehicleNoCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _regYearCtrl = TextEditingController();
  String _fuelType = 'Petrol';
  final _engineNoCtrl = TextEditingController();
  final _chassisNoCtrl = TextEditingController();

  // -- Step 3: Policy --
  final _policyNoCtrl = TextEditingController();
  String? _insuranceCompany;
  final _sumInsuredCtrl = TextEditingController();
  final _tpPremiumCtrl = TextEditingController();
  final _totalPremiumCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _expiryDate;
  String _paymentFreq = 'Annually';
  String _status = 'Active';
  final _nomineeCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();

  // Dynamic Steps count
  int get _totalSteps => widget.isMotor ? 4 : 3;

  List<String> get _stepTitles {
    if (widget.isMotor) return ['Client', 'Vehicle', 'Policy', 'Review'];
    return ['Client', 'Policy', 'Review'];
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCustomerId != null) {
      _selectedCustomerId = widget.prefilledCustomerId;
      _selectedCustomerName = widget.prefilledCustomerName;
      _policyHolder = widget.prefilledCustomerName;
      _clientNameCtrl.text = widget.prefilledCustomerName ?? '';
    }
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _referenceCtrl.dispose();
    _vehicleNoCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _regYearCtrl.dispose();
    _engineNoCtrl.dispose();
    _chassisNoCtrl.dispose();
    _policyNoCtrl.dispose();
    _sumInsuredCtrl.dispose();
    _tpPremiumCtrl.dispose();
    _totalPremiumCtrl.dispose();
    _nomineeCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 0) {
      if (_clientFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep++);
      }
    } else if (widget.isMotor && _currentStep == 1) {
      if (_vehicleFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep++);
      }
    } else if ((widget.isMotor && _currentStep == 2) || (!widget.isMotor && _currentStep == 1)) {
      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expiry date'), backgroundColor: Colors.red));
        return;
      }
      if (_policyFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep++);
      }
    } else {
      _save();
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
    final clientName = _clientNameCtrl.text.trim();
    final policyHolder = _policyHolder?.trim() ?? clientName;

    try {
      // Build payload directly for /api/policies/ endpoint
      final payload = <String, dynamic>{
        'policy_type': widget.policyType,
        // Never send null — backend auto-generates if empty string
        'policy_number': _policyNoCtrl.text.trim(),
        'insurer_name': _insuranceCompany ?? 'Unknown',
        'plan_name': policyHolder.isNotEmpty ? policyHolder : clientName,
        'sum_assured': double.tryParse(_sumInsuredCtrl.text.replaceAll(',', '')) ?? 0.0,
        'premium_amount': double.tryParse(_totalPremiumCtrl.text.replaceAll(',', '')) ?? 0.0,
        'start_date': _startDate.toIso8601String().split('T').first,
        'end_date': _expiryDate!.toIso8601String().split('T').first,
        'issue_date': _startDate.toIso8601String().split('T').first,
        'expiry_date': _expiryDate!.toIso8601String().split('T').first,
        'status': _status.toLowerCase(),
        if (_nomineeCtrl.text.trim().isNotEmpty)
          'nominee_name': _nomineeCtrl.text.trim(),
        if (_relationCtrl.text.trim().isNotEmpty)
          'nominee_relation': _relationCtrl.text.trim(),
        'notes': [
          if (clientName.isNotEmpty) 'Client: $clientName',
          if (_referenceCtrl.text.trim().isNotEmpty)
            'Ref: ${_referenceCtrl.text.trim()}',
          if (widget.isMotor) ...[
            'Vehicle: ${_vehicleNoCtrl.text.trim()}',
            'Make/Model: ${_makeCtrl.text.trim()} ${_modelCtrl.text.trim()}',
          ],
        ].join(' | '),
      };

      // If customer_id is available (prefilled), include it
      if (_selectedCustomerId != null) {
        payload['customer_id'] = _selectedCustomerId;
      }

      await apiService.dio.post('/api/policies/', data: payload);

      if (!mounted) return;

      // Use fetchDashboardStats() directly instead of invalidate()
      // invalidate() resets to loading but doesn't auto-refetch unless build() does it
      ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
      ref.invalidate(lifeReportProvider);
      ref.invalidate(expiringPoliciesProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(policiesProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Policy saved successfully!'),
        ]),
        backgroundColor: Colors.green,
      ));

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      // Show clean error message
      String msg = 'Failed to save policy. Please try again.';
      try {
        final detail = (e as dynamic).response?.data?['detail'];
        if (detail != null) msg = detail.toString();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.policyType.split(' - ').first, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Custom Stepper
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildStepper(),
          ),
          
          // Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStep(),
            ),
          ),
          
          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_currentStep == _totalSteps - 1 ? 'Save Policy' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_currentStep < _totalSteps - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final titles = _stepTitles;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(titles.length * 2 - 1, (index) {
        if (index % 2 == 1) {
          // Line
          final stepIndex = index ~/ 2;
          final isCompleted = _currentStep > stepIndex;
          return Container(
            width: 40,
            height: 2,
            color: isCompleted ? widget.color : Colors.grey.shade300,
          );
        } else {
          // Circle
          final stepIndex = index ~/ 2;
          final isActive = _currentStep == stepIndex;
          final isCompleted = _currentStep > stepIndex;
          
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? widget.color : (isActive ? widget.color : Colors.grey.shade100),
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive || isCompleted ? widget.color : Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                titles[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isActive || isCompleted ? widget.color : Colors.grey,
                ),
              )
            ],
          );
        }
      }),
    );
  }

  Widget _buildCurrentStep() {
    // 0: Client
    // 1: Vehicle (if motor) OR Policy (if not motor)
    // 2: Policy (if motor) OR Review (if not motor)
    // 3: Review (if motor)

    if (_currentStep == 0) return _buildClientStep();
    if (widget.isMotor) {
      if (_currentStep == 1) return _buildVehicleStep();
      if (_currentStep == 2) return _buildPolicyStep();
    } else {
      if (_currentStep == 1) return _buildPolicyStep();
    }
    return _buildReviewStep();
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(widget.icon, color: widget.color, size: 32),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(widget.policyType, style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: widget.color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Step 1: Client ────────────────────────────────────────────────────────
  Widget _buildClientStep() {
    return Form(
      key: _clientFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Client Details', 'Who is this policy for?'),

          // ── Client Name (simple text field) ──────────────────────────────
          _label('Client Name', isRequired: true),
          TextFormField(
            controller: _clientNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDeco(hint: 'Enter client name'),
            onChanged: (val) {
              _selectedCustomerName = val.trim();
              // Auto-fill Policy Holder if it's still empty
              if (_policyHolder == null || _policyHolder!.isEmpty) {
                setState(() => _policyHolder = val.trim());
              }
            },
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Client name is required' : null,
          ),

          // ── Policy Holder ─────────────────────────────────────────────────
          _label('Policy Holder', isRequired: true),
          TextFormField(
            initialValue: _policyHolder,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDeco(hint: 'Name of the policy holder'),
            onChanged: (val) => _policyHolder = val,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),

          // ── Reference By ──────────────────────────────────────────────────
          _label('Reference By', isOptional: true),
          TextFormField(
            controller: _referenceCtrl,
            decoration: _inputDeco(hint: 'Referred by (optional)'),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.policyType,
                    style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Vehicle (Motor Only) ──────────────────────────────────────────
  Widget _buildVehicleStep() {
    return Form(
      key: _vehicleFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Vehicle Details', 'Enter the vehicle information'),
          _label('Vehicle Type', isRequired: true),
          DropdownButtonFormField<String>(
            initialValue: _vehicleType,
            decoration: _inputDeco(),
            items: ['Private Car', 'Two Wheeler', 'Commercial Vehicle'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _vehicleType = v!),
          ),

          _label('Vehicle Number', isRequired: true),
          TextFormField(
            controller: _vehicleNoCtrl,
            decoration: _inputDeco(hint: 'e.g. MH12AB1234'),
            textCapitalization: TextCapitalization.characters,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Make', isRequired: true),
                    TextFormField(controller: _makeCtrl, decoration: _inputDeco(hint: 'e.g. Maruti'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Model', isRequired: true),
                    TextFormField(controller: _modelCtrl, decoration: _inputDeco(hint: 'e.g. Swift'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  ],
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Reg. Year', isRequired: true),
                    TextFormField(controller: _regYearCtrl, keyboardType: TextInputType.number, decoration: _inputDeco(hint: 'e.g. 2022'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Fuel Type', isRequired: true),
                    DropdownButtonFormField<String>(
                      initialValue: _fuelType,
                      decoration: _inputDeco(),
                      items: ['Petrol', 'Diesel', 'CNG', 'EV'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _fuelType = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),

          _label('Engine Number', isOptional: true),
          TextFormField(controller: _engineNoCtrl, decoration: _inputDeco(hint: 'Engine number (optional)')),

          _label('Chassis Number', isOptional: true),
          TextFormField(controller: _chassisNoCtrl, decoration: _inputDeco(hint: 'Chassis number (optional)')),
        ],
      ),
    );
  }

  // ─── Step 3: Policy ────────────────────────────────────────────────────────
  Widget _buildPolicyStep() {
    return Form(
      key: _policyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Policy Details', 'Enter premium & policy info'),

          _label('Policy Number', isOptional: true),
          TextFormField(
            controller: _policyNoCtrl,
            decoration: _inputDeco(hint: 'e.g. LIC-2026-LF-1001 (auto-generated if blank)'),
          ),

          _label('Insurance Company', isRequired: true),
          DropdownButtonFormField<String>(
            initialValue: _insuranceCompany,
            decoration: _inputDeco(),
            hint: const Text('Select Company'),
            isExpanded: true,
            items: kInsuranceCompanies
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _insuranceCompany = v!),
            validator: (v) => v == null ? 'Required' : null,
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Details', style: TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                const Text('Sum Insured / Assured (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sumInsuredCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco(hint: 'e.g. 500000', isWhite: true),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Sum insured is required' : null,
                ),
                const SizedBox(height: 16),
                if (widget.isMotor) ...[
                  const Text('Third Party Premium (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextFormField(controller: _tpPremiumCtrl, keyboardType: TextInputType.number, decoration: _inputDeco(hint: 'TP premium amount', isWhite: true)),
                  const SizedBox(height: 16),
                ],
                const Text('Total Premium (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _totalPremiumCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco(hint: 'Total premium payable', isWhite: true),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _label('Policy Start Date', isRequired: true),
          _dateCard('Policy Start Date', _startDate, (d) => setState(() => _startDate = d)),

          _label('Policy Expiry Date', isRequired: true),
          _dateCard('Policy Expiry Date', _expiryDate, (d) => setState(() => _expiryDate = d)),

          _label('Payment Frequency'),
          DropdownButtonFormField<String>(
            initialValue: _paymentFreq,
            decoration: _inputDeco(),
            items: ['Annually', 'Half-Yearly', 'Quarterly', 'Monthly']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _paymentFreq = v!),
          ),

          _label('Policy Status'),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: _inputDeco(),
            items: ['Active', 'Pending', 'Lapsed', 'Matured', 'Cancelled']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),

          _label('Nominee Name', isOptional: true),
          TextFormField(controller: _nomineeCtrl, decoration: _inputDeco(hint: 'Nominee full name')),

          _label('Nominee Relation', isOptional: true),
          TextFormField(controller: _relationCtrl, decoration: _inputDeco(hint: 'e.g. Spouse, Son, Daughter')),
        ],
      ),
    );
  }

  // ─── Step 4: Review ────────────────────────────────────────────────────────
  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Review Details', 'Check info before saving'),
        _reviewSection('Client Details', {
          'Client Name': _selectedCustomerName ?? '',
          'Policy Holder': _policyHolder ?? '',
        }),
        if (widget.isMotor)
          _reviewSection('Vehicle Details', {
            'Vehicle No': _vehicleNoCtrl.text,
            'Make & Model': '${_makeCtrl.text} ${_modelCtrl.text}',
          }),
        _reviewSection('Policy Details', {
          'Company': _insuranceCompany ?? '',
          'Policy No': _policyNoCtrl.text,
          'Total Premium': '₹${_totalPremiumCtrl.text}',
        }),
      ],
    );
  }

  Widget _reviewSection(String title, Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const Divider(),
          ...data.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(e.value.isEmpty ? 'N/A' : e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ))
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text, {bool isRequired = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          children: [
            if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            if (isOptional) const TextSpan(text: ' optional', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({String? hint, bool isWhite = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: isWhite ? Colors.white : Colors.grey.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.color, width: 1.5)),
    );
  }

  Widget _dateCard(String title, DateTime? date, Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: widget.color)),
            child: child!,
          ),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(LucideIcons.calendar, color: widget.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    date != null ? '${['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][date.weekday-1]}, ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.month-1]} ${date.day}, ${date.year}' : 'Tap to select date',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: date != null ? Colors.black87 : Colors.grey),
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: () {}, // Clear logic if needed
                child: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
