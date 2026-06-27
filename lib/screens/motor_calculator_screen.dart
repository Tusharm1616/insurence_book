import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/lucide_compat.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/motor_calculator_provider.dart';

class MotorCalculatorScreen extends ConsumerStatefulWidget {
  const MotorCalculatorScreen({super.key});

  @override
  ConsumerState<MotorCalculatorScreen> createState() => _MotorCalculatorScreenState();
}

class _MotorCalculatorScreenState extends ConsumerState<MotorCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _showResult = false;
  bool _isGeneratingPdf = false;

  String _vehicleType = '4-Wheeler (<1000cc)';
  String _fuelType = 'Petrol';
  String _year = '2022';
  final _idvController = TextEditingController(text: '500000');
  
  int _ncbPercent = 0;
  final List<int> _ncbOptions = [0, 20, 25, 35, 45, 50];

  final Map<String, bool> _addons = {
    'Zero Depreciation': false,
    'Engine Protection': false,
    'Roadside Assistance': false,
    'Personal Accident Cover': false,
    'Return to Invoice': false,
  };

  @override
  void dispose() {
    _idvController.dispose();
    super.dispose();
  }

  void _calculatePremium() {
    if (_formKey.currentState!.validate()) {
      // Note: Since we removed customer info from UI to match the screenshot,
      // we are using default values for the backend API for now.
      final req = MotorCalcPremiumRequest(
        vehicleType: _vehicleType.contains('4') ? 'Four Wheeler' : 'Two Wheeler',
        fuelType: _fuelType,
        yearOfManufacture: int.parse(_year),
        ccCategory: _vehicleType.contains('<1000cc') ? 'Less than 1000cc' : 'Not Applicable',
        idv: double.parse(_idvController.text),
        ncbPercent: _ncbPercent.toDouble(),
        addons: _addons.entries.where((e) => e.value).map((e) => e.key).toList(),
        customerName: 'Guest User',
        vehicleRegNo: 'NEW VEHICLE',
      );
      
      ref.read(motorCalculatorProvider.notifier).calculatePremium(req).then((_) {
        setState(() => _showResult = true);
      });
    }
  }

  Future<void> _handlePdf(bool share) async {
    setState(() => _isGeneratingPdf = true);
    
    final req = MotorCalcPremiumRequest(
      vehicleType: _vehicleType.contains('4') ? 'Four Wheeler' : 'Two Wheeler',
      fuelType: _fuelType,
      yearOfManufacture: int.parse(_year),
      ccCategory: _vehicleType.contains('<1000cc') ? 'Less than 1000cc' : 'Not Applicable',
      idv: double.parse(_idvController.text),
      ncbPercent: _ncbPercent.toDouble(),
      addons: _addons.entries.where((e) => e.value).map((e) => e.key).toList(),
      customerName: 'Guest User',
      vehicleRegNo: 'NEW VEHICLE',
    );
      
    final path = await ref.read(motorCalculatorProvider.notifier).generateQuotePdf(req);
    setState(() => _isGeneratingPdf = false);
    
    if (path != null && mounted) {
      if (share) {
        await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Motor Insurance Quotation'));
      } else {
        OpenFile.open(path);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate PDF')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Motor Calculator', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _showResult ? _buildResultView() : _buildFormView(),
      bottomNavigationBar: _showResult ? null : _buildStickyButton(),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculate premium and generate quote',
            style: TextStyle(color: Colors.blueGrey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Vehicle Type'),
                  _buildDropdown(
                    value: _vehicleType,
                    items: ['4-Wheeler (<1000cc)', '4-Wheeler (>1000cc)', '2-Wheeler'],
                    onChanged: (v) => setState(() => _vehicleType = v!),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Fuel Type'),
                  _buildDropdown(
                    value: _fuelType,
                    items: ['Petrol', 'Diesel', 'CNG', 'Electric'],
                    onChanged: (v) => setState(() => _fuelType = v!),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Year of Manufacture'),
                  _buildDropdown(
                    value: _year,
                    items: ['2024', '2023', '2022', '2021', '2020', '2019', '2018'],
                    onChanged: (v) => setState(() => _year = v!),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('IDV Amount (₹)'),
                  TextFormField(
                    controller: _idvController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF4F6FB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('No Claim Bonus (NCB) %'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _ncbOptions.map((opt) {
                      final isSelected = _ncbPercent == opt;
                      return GestureDetector(
                        onTap: () => setState(() => _ncbPercent = opt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF2F6F3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$opt%',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Add-ons'),
                  const SizedBox(height: 8),
                  ..._addons.keys.map((key) => _buildCheckbox(key)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(LucideIcons.chevronDown, size: 20, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String key) {
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      child: CheckboxListTile(
        title: Text(key, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1D26))),
        value: _addons[key],
        onChanged: (v) => setState(() => _addons[key] = v!),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF4CAF50),
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        dense: true,
      ),
    );
  }

  Widget _buildStickyButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Consumer(builder: (context, ref, child) {
        final calcState = ref.watch(motorCalculatorProvider);
        
        return ElevatedButton.icon(
          onPressed: calcState.isLoading ? null : _calculatePremium,
          icon: calcState.isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(LucideIcons.cpu, size: 20),
          label: Text(calcState.isLoading ? 'Calculating...' : 'Calculate Premium', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }),
    );
  }

  Widget _buildResultView() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(motorCalculatorProvider);
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.value == null) return const Center(child: Text('Please calculate premium first'));
        
        final res = state.value!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Premium', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Text('₹${res.totalPremium.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildRow('Base OD Premium', '₹${res.odBeforeNcb.toStringAsFixed(2)}'),
                          _buildRow('NCB Discount (${res.ncbPercent}%)', '- ₹${res.ncbDiscount.toStringAsFixed(2)}', color: Colors.green),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                          _buildRow('Total OD Premium', '₹${res.odPremium.toStringAsFixed(2)}', isBold: true),
                          const SizedBox(height: 12),
                          _buildRow('Total TP Premium', '₹${res.tpPremium.toStringAsFixed(2)}', isBold: true),
                          if (res.addonsTotal > 0) ...[
                            const SizedBox(height: 12),
                            _buildRow('Add-Ons Premium', '₹${res.addonsTotal.toStringAsFixed(2)}', isBold: true),
                            ...res.addonBreakdown.entries.map((e) => _buildRow('  ${e.key}', '₹${e.value.toStringAsFixed(2)}', fontSize: 12, color: Colors.grey.shade600)),
                          ],
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                          _buildRow('Subtotal', '₹${res.subtotal.toStringAsFixed(2)}', isBold: true),
                          _buildRow('GST (18%)', '₹${res.gst.toStringAsFixed(2)}'),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isGeneratingPdf ? null : () => _handlePdf(false),
                                  icon: const Icon(LucideIcons.fileText, size: 18),
                                  label: const Text('View PDF'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    foregroundColor: const Color(0xFF4CAF50),
                                    side: const BorderSide(color: Color(0xFF4CAF50)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingPdf ? null : () => _handlePdf(true),
                                  icon: const Icon(LucideIcons.share2, size: 18),
                                  label: const Text('Share'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isGeneratingPdf) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(color: Color(0xFF4CAF50)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => setState(() => _showResult = false),
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: const Text('Back to Edit Form', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: color ?? Colors.black87)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
