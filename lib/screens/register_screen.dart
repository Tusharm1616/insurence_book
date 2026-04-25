import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInput(label: 'First Name', icon: LucideIcons.user),
                const SizedBox(height: 16),
                _buildInput(label: 'Last Name', icon: LucideIcons.userPlus),
                const SizedBox(height: 16),
                _buildInput(label: 'Email', icon: LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildInput(label: 'Mobile Number', icon: LucideIcons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildPasswordInput(
                  label: 'Password',
                  obscure: _obscurePassword,
                  toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),
                _buildPasswordInput(
                  label: 'Confirm Password',
                  obscure: _obscureConfirmPassword,
                  toggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // To Do: Implement Registration
                    }
                  },
                  child: const Text('Register'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'login',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: label,
        fillColor: Colors.grey.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildPasswordInput({
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextFormField(
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: const Icon(LucideIcons.lock, size: 20),
        hintText: label,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        suffixIcon: IconButton(
          icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
          onPressed: toggle,
        ),
      ),
    );
  }
}
