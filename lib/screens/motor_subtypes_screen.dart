import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'add_policy_wizard.dart'; // We will create this next

class MotorSubtypesScreen extends StatelessWidget {
  final int? prefilledCustomerId;
  final String? prefilledCustomerName;

  const MotorSubtypesScreen({
    super.key,
    this.prefilledCustomerId,
    this.prefilledCustomerName,
  });

  @override
  Widget build(BuildContext context) {
    final subtypes = [
      {
        'id': '1',
        'tag': 'Mandatory',
        'title': 'Third Party Insurance',
        'subtitle': 'Covers damage & injury caused to a third party. Required by law.',
        'features': ['Third-party damage cover', 'Mandatory by Law', 'Legal liability'],
        'icon': LucideIcons.shield,
        'bgColor': Colors.green.shade50,
        'tagColor': Colors.green,
        'textColor': Colors.green.shade700,
      },
      {
        'id': '2',
        'tag': 'Most Popular',
        'title': 'Comprehensive Insurance',
        'subtitle': '360° protection — own vehicle damage + third-party liability.',
        'features': ['Own vehicle damage', 'Third-party liability'],
        'icon': LucideIcons.car,
        'bgColor': Colors.red.shade50,
        'tagColor': Colors.red,
        'textColor': Colors.red.shade700,
      },
      {
        'id': '3',
        'tag': 'Standalone',
        'title': 'Own Damage Insurance',
        'subtitle': 'Covers your vehicle against accidents, fire, theft and natural calamities.',
        'features': ['Accident & theft cover', 'Natural calamities'],
        'icon': LucideIcons.wrench,
        'bgColor': Colors.blue.shade50,
        'tagColor': Colors.blue.shade700,
        'textColor': Colors.blue.shade800,
      },
      {
        'id': '4',
        'tag': 'Add-on',
        'title': 'Zero Depreciation Insurance',
        'subtitle': 'No depreciation cuts on parts. Get maximum claim settlement.',
        'features': ['No deduction on parts', 'Max claim settlement'],
        'icon': LucideIcons.settings,
        'bgColor': Colors.purple.shade50,
        'tagColor': Colors.purple,
        'textColor': Colors.purple.shade700,
      },
      {
        'id': '5',
        'tag': 'Add-on',
        'title': 'Engine Protect Insurance',
        'subtitle': 'Covers expensive engine & gearbox repair not included in standard plans.',
        'features': ['Engine repair / replacement', 'Waterlogging protection'],
        'icon': LucideIcons.zap, // closest to engine icon
        'bgColor': Colors.orange.shade50,
        'tagColor': Colors.deepOrange,
        'textColor': Colors.deepOrange.shade700,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Motor Insurance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: subtypes.length,
        itemBuilder: (context, index) {
          final item = subtypes[index];
          return _buildSubtypeCard(context, item);
        },
      ),
    );
  }

  Widget _buildSubtypeCard(BuildContext context, Map<String, dynamic> item) {
    final String id = item['id'];
    final String tag = item['tag'];
    final String title = item['title'];
    final String subtitle = item['subtitle'];
    final List<String> features = item['features'];
    final IconData icon = item['icon'];
    final Color bgColor = item['bgColor'];
    final Color tagColor = item['tagColor'];
    final Color textColor = item['textColor'];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPolicyWizard(
                  policyType: 'Motor Insurance - $title',
                  color: tagColor,
                  icon: icon,
                  isMotor: true,
                  prefilledCustomerId: prefilledCustomerId,
                  prefilledCustomerName: prefilledCustomerName,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20, left: 12, right: 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tagColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tagColor, size: 28),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 12),
                      // Features
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: features.map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 6, color: tagColor),
                              const SizedBox(width: 4),
                              Text(f, style: TextStyle(fontSize: 10, color: tagColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                // Right Arrow
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tagColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Badge
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              id,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
