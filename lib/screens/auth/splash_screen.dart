import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart' show pendingSharedPdf;
import '../pdf_intake_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for at least 2.5 seconds total for the splash screen effect
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Wait until auth initialization completes
    while (true) {
      if (!mounted) return;
      if (!ref.read(authProvider).isLoading) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    final authState = ref.read(authProvider);
    
    if (authState.isAuthenticated) {
      // If app was opened via share intent with a PDF, go to PDF intake
      if (pendingSharedPdf != null && pendingSharedPdf!.path.isNotEmpty) {
        final pdfFile = pendingSharedPdf!;
        pendingSharedPdf = null; // Clear so it doesn't trigger again
        final file = File(pdfFile.path);
        final fileSize = file.existsSync() ? file.lengthSync() : 0;
        final fileName = pdfFile.path.split('/').last.split('\\').last;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PdfIntakeScreen(
              filePath: pdfFile.path,
              fileName: fileName,
              fileSize: fileSize,
            ),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF22C55E),
              Color(0xFF16A34A),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // We simulate the shield SVG with an Icon since flutter_svg requires an asset
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  size: 60,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'InsureAgent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Smart Insurance Partner',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
