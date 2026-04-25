import 'package:flutter/material.dart';
import '../core/theme.dart';

class GenericPlaceholderScreen extends StatelessWidget {
  final String title;
  const GenericPlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: Center(child: Text('$title\\nComing Soon...', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey))),
    );
  }
}
