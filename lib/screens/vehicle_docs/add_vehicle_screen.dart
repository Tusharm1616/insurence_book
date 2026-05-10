import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/vehicle_document_provider.dart';
import '../../providers/customer_provider.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;

  // Step 1 fields
  final _vehicleNoCtrl    = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  String _vehicleType     = 'Car';
  String _manufacturer    = 'Maruti Suzuki';
  String _fuelType        = 'Petrol';
  int?   _regYear;
  int?   _selectedCustomerId;


  // Step 2 date fields
  DateTime? _insuranceExpiry;
  DateTime? _pucExpiry;
  DateTime? _rcExpiry;
  DateTime? _licenseExpiry;
  DateTime? _fitnessExpiry;
  final _notesCtrl = TextEditingController();

  static const _vehicleTypes    = ['Car', 'Bike', 'Truck', 'Bus', 'Auto', 'Other'];
  static const _manufacturers   = ['Maruti Suzuki', 'Hyundai', 'Honda', 'Toyota', 'Tata', 'Mahindra', 'Kia', 'Bajaj', 'Hero', 'TVS', 'Royal Enfield', 'Other'];
  static const _fuelTypes       = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];

  @override
  void dispose() {
    _vehicleNoCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String label, DateTime? current, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      helpText: 'Select $label Expiry Date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Tap to select';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final vn = _vehicleNoCtrl.text.trim().toUpperCase().replaceAll(' ', '');
      String apiDate(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final payload = <String, dynamic>{
        'vehicle_number': vn,
        'vehicle_type':   _vehicleType,
        'vehicle_model':  _vehicleModelCtrl.text.trim(),
        'manufacturer':   _manufacturer,
        'fuel_type':      _fuelType,
        if (_regYear != null)       'registration_year': _regYear,
        if (_selectedCustomerId != null) 'customer_id': _selectedCustomerId,
        if (_insuranceExpiry != null) 'insurance_expiry': apiDate(_insuranceExpiry!),
        if (_pucExpiry != null)       'puc_expiry':       apiDate(_pucExpiry!),
        if (_rcExpiry != null)        'rc_expiry':        apiDate(_rcExpiry!),
        if (_licenseExpiry != null)   'license_expiry':   apiDate(_licenseExpiry!),
        if (_fitnessExpiry != null)   'fitness_expiry':   apiDate(_fitnessExpiry!),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      };

      await ref.read(vehicleDocsProvider.notifier).addVehicle(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully!'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              _stepDot(0, 'Vehicle Info'),
              Expanded(child: Container(height: 2, color: Colors.white.withValues(alpha: _step >= 1 ? 1 : 0.3))),
              _stepDot(1, 'Doc Dates'),
            ]),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _step == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    final active = _step >= index;
    return Column(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: active && _step > index
              ? const Icon(Icons.check, size: 14, color: AppColors.primary)
              : Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: active ? AppColors.primary : Colors.white)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: active ? Colors.white : Colors.white.withValues(alpha: 0.6), fontSize: 10)),
    ]);
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        border: Border(top: BorderSide(color: AppThemeHelper.borderColor(context))),
      ),
      child: Row(children: [
        if (_step > 0) ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _step--),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saving ? null : () {
              if (_step == 0) {
                if (_formKey.currentState!.validate()) setState(() => _step = 1);
              } else {
                _save();
              }
            },
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_step == 0 ? LucideIcons.arrowRight : LucideIcons.check, size: 16),
            label: Text(_saving ? 'Saving…' : (_step == 0 ? 'Next: Document Dates' : 'Save Vehicle'), style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Step 1 — Vehicle Info ──────────────────────────────────────────────
  Widget _buildStep1() {
    final customersAsync = ref.watch(customerProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Vehicle Details'),
      const SizedBox(height: 12),

      _label('Vehicle Number *'),
      TextFormField(
        controller: _vehicleNoCtrl,
        textCapitalization: TextCapitalization.characters,
        decoration: _inputDeco('MH12AB1234', LucideIcons.hash),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vehicle number is required' : null,
      ),
      const SizedBox(height: 14),

      _label('Vehicle Type *'),
      _dropdown(_vehicleType, _vehicleTypes, (v) => setState(() => _vehicleType = v!), LucideIcons.car),
      const SizedBox(height: 14),

      _label('Manufacturer *'),
      _dropdown(_manufacturer, _manufacturers, (v) => setState(() => _manufacturer = v!), LucideIcons.building2),
      const SizedBox(height: 14),

      _label('Vehicle Model *'),
      TextFormField(
        controller: _vehicleModelCtrl,
        decoration: _inputDeco('e.g. Swift Dzire', LucideIcons.tag),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Model is required' : null,
      ),
      const SizedBox(height: 14),

      _label('Fuel Type *'),
      _dropdown(_fuelType, _fuelTypes, (v) => setState(() => _fuelType = v!), LucideIcons.fuel),
      const SizedBox(height: 14),

      _label('Registration Year'),
      DropdownButtonFormField<int>(
        initialValue: _regYear,
        decoration: _inputDeco('Select year', LucideIcons.calendar),
        items: List.generate(30, (i) => DateTime.now().year - i)
            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
            .toList(),
        onChanged: (v) => setState(() => _regYear = v),
        dropdownColor: AppThemeHelper.cardColor(context),
      ),
      const SizedBox(height: 20),

      _sectionTitle('Link to Customer (Optional)'),
      const SizedBox(height: 10),
      customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => const Text('Could not load customers'),
        data: (customers) {
          final items = customers.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text('${c.fullName} — ${c.mobileNumber}', overflow: TextOverflow.ellipsis),
          )).toList();
          return DropdownButtonFormField<int>(
            initialValue: _selectedCustomerId,
            hint: const Text('Select customer (optional)'),
            decoration: _inputDeco('', LucideIcons.user),
            items: items,
            onChanged: (v) {
              setState(() {
                _selectedCustomerId = v;
              });
            },
            dropdownColor: AppThemeHelper.cardColor(context),
          );
        },
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Step 2 — Document Dates ────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Document Expiry Dates'),
      const SizedBox(height: 4),
      Text('Set expiry dates for tracking. All fields are optional.', style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context))),
      const SizedBox(height: 16),

      _dateTile(LucideIcons.shield,    'Insurance Expiry',          _insuranceExpiry, const Color(0xFFE65100), (d) => setState(() => _insuranceExpiry = d)),
      _dateTile(LucideIcons.leaf,      'PUC Expiry',               _pucExpiry,       const Color(0xFF9C27B0), (d) => setState(() => _pucExpiry       = d)),
      _dateTile(LucideIcons.creditCard,'RC (Registration) Expiry',  _rcExpiry,        const Color(0xFF1565C0), (d) => setState(() => _rcExpiry        = d)),
      _dateTile(LucideIcons.creditCard,'Driving License Expiry',    _licenseExpiry,   const Color(0xFF2E7D32), (d) => setState(() => _licenseExpiry   = d)),
      _dateTile(LucideIcons.fileCheck, 'Fitness Certificate Expiry',_fitnessExpiry,   const Color(0xFFF57F17), (d) => setState(() => _fitnessExpiry   = d)),

      const SizedBox(height: 16),
      _label('Notes (Optional)'),
      TextFormField(
        controller: _notesCtrl,
        maxLines: 3,
        decoration: _inputDeco('Any remarks about this vehicle…', LucideIcons.fileText),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _dateTile(IconData icon, String label, DateTime? value, Color color, ValueChanged<DateTime> onPicked) {
    final set = value != null;
    return GestureDetector(
      onTap: () => _pickDate(label, value, onPicked),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppThemeHelper.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: set ? color.withValues(alpha: 0.4) : AppThemeHelper.borderColor(context)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppThemeHelper.textPrimary(context))),
              const SizedBox(height: 2),
              Text(_fmtDate(value), style: TextStyle(fontSize: 12, color: set ? color : AppThemeHelper.textSecondary(context))),
            ]),
          ),
          Icon(LucideIcons.calendarDays, color: set ? color : AppThemeHelper.iconMuted(context), size: 18),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppThemeHelper.textPrimary(context)));
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppThemeHelper.textSecondary(context))));

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18, color: AppThemeHelper.iconMuted(context)),
    filled: true,
    fillColor: AppThemeHelper.surfaceColor(context),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppThemeHelper.borderColor(context))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppThemeHelper.borderColor(context))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDeco('', icon),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
      dropdownColor: AppThemeHelper.cardColor(context),
    );
  }
}
