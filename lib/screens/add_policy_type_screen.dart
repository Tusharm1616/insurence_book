import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'add_policy_wizard.dart';
import 'motor_subtypes_screen.dart';

class AddPolicyTypeScreen extends StatelessWidget {
  const AddPolicyTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final types = [
      {'title': 'Health Insurance', 'subtitle': 'Medical expenses for you\nand your family', 'icon': LucideIcons.activity, 'bgColor': Colors.green.shade50, 'color': Colors.green},
      {'title': 'Motor Insurance', 'subtitle': 'Car, bike, commercial\nvehicle and more', 'icon': LucideIcons.car, 'bgColor': Colors.orange.shade50, 'color': Colors.orange},
      {'title': 'Life Insurance', 'subtitle': 'Secure your family\'s future\n& long-term goals', 'icon': LucideIcons.heart, 'bgColor': Colors.pink.shade50, 'color': Colors.pink},
      {'title': 'Travel Insurance', 'subtitle': 'Travel worry-free anywhere\nin the world', 'icon': LucideIcons.plane, 'bgColor': Colors.blue.shade50, 'color': Colors.blue},
      {'title': 'Home Insurance', 'subtitle': 'Protect home & belongings\nfrom risks', 'icon': LucideIcons.home, 'bgColor': Colors.amber.shade50, 'color': Colors.amber.shade700},
      {'title': 'Business Insurance', 'subtitle': 'Comprehensive protection\nfor your business', 'icon': LucideIcons.building, 'bgColor': Colors.indigo.shade50, 'color': Colors.indigo},
      {'title': 'Shop / Commercial', 'subtitle': 'Security for shop, office &\ncommercial space', 'icon': LucideIcons.store, 'bgColor': Colors.orange.shade50, 'color': Colors.orangeAccent.shade700},
      {'title': 'Two Wheeler', 'subtitle': 'Complete protection for\nyour two wheeler', 'icon': Icons.two_wheeler, 'bgColor': Colors.purple.shade50, 'color': Colors.purple},
      {'title': 'Accident Insurance', 'subtitle': 'Support in case of\naccidental injury or ...', 'icon': Icons.local_hospital, 'bgColor': Colors.red.shade50, 'color': Colors.redAccent},
      {'title': 'Term Insurance', 'subtitle': 'High life cover at affordable\npremiums', 'icon': LucideIcons.shieldCheck, 'bgColor': Colors.teal.shade50, 'color': Colors.teal},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.filePlus, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Insurance Type', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Choose from 10 insurance categories', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final t = types[index];
                return GestureDetector(
                  onTap: () {
                    final title = t['title'] as String;
                    if (title == 'Motor Insurance') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MotorSubtypesScreen()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddPolicyWizard(
                          policyType: title,
                          color: t['color'] as Color,
                          icon: t['icon'] as IconData,
                          isMotor: false,
                        ),
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (t['color'] as Color).withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: (t['color'] as Color).withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: t['bgColor'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(t['icon'] as IconData, color: t['color'] as Color, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t['subtitle'] as String,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
