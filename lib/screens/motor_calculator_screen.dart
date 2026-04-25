import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class MotorCalculatorScreen extends StatefulWidget {
  const MotorCalculatorScreen({super.key});

  @override
  State<MotorCalculatorScreen> createState() => _MotorCalculatorScreenState();
}

class _MotorCalculatorScreenState extends State<MotorCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  double _calculatedPremium = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor Insurance Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calculate estimated premium for your vehicle insurance.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildDropdown('Vehicle Type', ['Private Car', 'Two Wheeler', 'Commercial Vehicle']),
              const SizedBox(height: 16),
              _buildTextField('Manufacturer/Make', LucideIcons.factory),
              const SizedBox(height: 16),
              _buildTextField('Model Name', LucideIcons.car),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Manf. Year', LucideIcons.calendar, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Registration Year', LucideIcons.calendar, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('IDV (Insured Declared Value)', LucideIcons.dollarSign, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildDropdown('Previous NCB (%)', ['0%', '20%', '25%', '35%', '45%', '50%']),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _calculatedPremium = 12500.0; // Mock calculation
                  });
                },
                child: const Text('Calculate Premium'),
              ),
              if (_calculatedPremium > 0) ...[
                const SizedBox(height: 32),
                _buildResultCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Estimated Annual Premium', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              '₹${_calculatedPremium.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // To Do: Generate PDF Quote
              },
              icon: const Icon(LucideIcons.fileDown),
              label: const Text('Generate PDF Quote'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        fillColor: Colors.grey.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.first,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {},
            ),
          ),
        ),
      ],
    );
  }
}
