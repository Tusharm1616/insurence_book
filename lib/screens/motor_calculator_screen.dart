import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  
  String _vehicleType = '2W';
  final _ccController = TextEditingController();
  final _yearController = TextEditingController();
  final _idvController = TextEditingController();
  double _ncbPercent = 0.0;
  
  bool _zeroDep = false;
  bool _engineProtect = false;
  bool _rti = false;

  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _ccController.dispose();
    _yearController.dispose();
    _idvController.dispose();
    super.dispose();
  }

  MotorCalcRequest _buildRequest() {
    List<String> addOns = [];
    if (_zeroDep) addOns.add('zero_dep');
    if (_engineProtect) addOns.add('engine_protect');
    if (_rti) addOns.add('rti');

    return MotorCalcRequest(
      vehicleType: _vehicleType,
      cubicCapacity: int.tryParse(_ccController.text) ?? 1000,
      manufactureYear: int.tryParse(_yearController.text) ?? DateTime.now().year,
      idv: double.tryParse(_idvController.text) ?? 100000,
      ncbPercent: _ncbPercent,
      addOns: addOns,
    );
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      ref.read(motorCalculatorProvider.notifier).calculatePremium(_buildRequest());
    }
  }

  Future<void> _handlePdf(bool share) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isGeneratingPdf = true);
    final path = await ref.read(motorCalculatorProvider.notifier).generateQuotePdf(_buildRequest());
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
    final calcState = ref.watch(motorCalculatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: calcState.isLoading ? null : _calculate,
                icon: calcState.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.calculator),
                label: const Text('Calculate Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              calcState.when(
                data: (res) => res != null ? _buildResultCard(res) : const SizedBox.shrink(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: const InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder()),
              items: ['2W', '4W', 'CV'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _vehicleType = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ccController,
                    decoration: const InputDecoration(labelText: 'Cubic Capacity (CC)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Make Year', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _idvController,
              decoration: const InputDecoration(labelText: 'Declared IDV (₹)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              initialValue: _ncbPercent,
              decoration: const InputDecoration(labelText: 'NCB Discount', border: OutlineInputBorder()),
              items: [0.0, 20.0, 25.0, 35.0, 45.0, 50.0].map((e) => DropdownMenuItem(value: e, child: Text('${e.toInt()}%'))).toList(),
              onChanged: (v) => setState(() => _ncbPercent = v!),
            ),
            const SizedBox(height: 16),
            const Text('Add-Ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            CheckboxListTile(
              title: const Text('Zero Depreciation'),
              value: _zeroDep,
              onChanged: (v) => setState(() => _zeroDep = v!),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Engine Protection'),
              value: _engineProtect,
              onChanged: (v) => setState(() => _engineProtect = v!),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Return to Invoice (RTI)'),
              value: _rti,
              onChanged: (v) => setState(() => _rti = v!),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(MotorCalcResponse res) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.fileCheck, color: Colors.purple),
                SizedBox(width: 8),
                Text('Premium Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow('Base OD Premium', '₹${res.baseOd}'),
                _buildRow('NCB Discount', '- ₹${res.ncbDiscount}', color: Colors.green),
                const Divider(),
                _buildRow('Total OD Premium (A)', '₹${res.totalOd}', isBold: true),
                const SizedBox(height: 8),
                _buildRow('Total TP Premium (B)', '₹${res.totalTp}', isBold: true),
                const SizedBox(height: 8),
                _buildRow('Add-Ons Premium (C)', '₹${res.addOnsTotal}', isBold: true),
                const Divider(),
                _buildRow('Net Premium (A+B+C)', '₹${res.netPremium}', isBold: true),
                _buildRow('GST @ 18%', '₹${res.gst}'),
                const Divider(thickness: 2),
                _buildRow('Final Premium', '₹${res.finalPremium}', isBold: true, fontSize: 20, color: Colors.purple),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingPdf ? null : () => _handlePdf(false),
                        icon: const Icon(LucideIcons.fileText),
                        label: const Text('Open PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingPdf ? null : () => _handlePdf(true),
                        icon: const Icon(LucideIcons.share2),
                        label: const Text('Share Quote'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isGeneratingPdf) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(color: Colors.purple),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
