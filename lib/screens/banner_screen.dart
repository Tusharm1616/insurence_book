import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class BannerScreen extends StatefulWidget {
  const BannerScreen({super.key});

  @override
  State<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends State<BannerScreen> {
  // Mock State
  final List<Map<String, dynamic>> _banners = [
    {
      'id': '1',
      'title': 'Diwali Super Offer',
      'subtitle': 'Flat 20% off on Motor Insurance',
      'isActive': true,
      'validUntil': '31 Oct 2026',
    },
    {
      'id': '2',
      'title': 'Health Family Combo',
      'subtitle': 'Zero waiting period for critical illness',
      'isActive': false,
      'validUntil': '31 Dec 2026',
    },
  ];

  void _uploadNewBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Gallery to upload image...'), backgroundColor: AppColors.primary),
    );
  }

  void _deleteBanner(int index) {
    setState(() {
      _banners.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle),
            tooltip: 'Upload New Banner',
            onPressed: _uploadNewBanner,
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: _banners.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return _buildBannerCard(banner, index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadNewBanner,
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.uploadCloud, color: Colors.white),
        label: const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.flag, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('No Banners Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('You haven\'t uploaded any promotional banners yet. Upload one to display it on the app.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Column(
        children: [
          // Banner Image Placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(LucideIcons.image, size: 40, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(banner['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Switch(
                      value: banner['isActive'],
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => banner['isActive'] = val);
                      },
                    ),
                  ],
                ),
                Text(banner['subtitle'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Valid until: ${banner['validUntil']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                          onPressed: () {},
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          onPressed: () => _deleteBanner(index),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
