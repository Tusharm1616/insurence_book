import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/lucide_compat.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/vehicle_document_provider.dart';

class VehicleDocumentScreen extends ConsumerStatefulWidget {
  const VehicleDocumentScreen({super.key});

  @override
  ConsumerState<VehicleDocumentScreen> createState() => _VehicleDocumentScreenState();
}

class _VehicleDocumentScreenState extends ConsumerState<VehicleDocumentScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _regNoController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_pulseController);
  }

  @override
  void dispose() {
    _regNoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _search() {
    final regNo = _regNoController.text.trim();
    if (regNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a registration number')),
      );
      return;
    }
    // Remove spaces and special chars
    final cleaned = regNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    ref.read(vehicleDocumentProvider.notifier).fetchDocumentStatus(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleDocumentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Document Validity', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFF4CAF50),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _regNoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter Vehicle Reg No (e.g. MH12AB1234)',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(LucideIcons.car, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.search, color: Color(0xFF4CAF50)),
                      onPressed: _search,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(VehicleDocumentState state) {
    if (state.isLoading) {
      return _buildShimmer();
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (state.data == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileSearch, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search for a vehicle to view document validity', 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final data = state.data!;
    final documents = data['documents'] as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVehicleInfoCard(data),
        const SizedBox(height: 16),
        const Text('Documents Status', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        const SizedBox(height: 12),
        ...documents.map((doc) => _buildDocumentCard(doc)),
      ],
    );
  }

  Widget _buildVehicleInfoCard(Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.car, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['registration_number'], 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${data['vehicle_make']} ${data['vehicle_model']}', 
                        style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(LucideIcons.user, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Owner: ${data['owner_name']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final status = doc['status'] as String;
    final days = doc['days_until_expiry'] as int;
    
    Color borderColor;
    Color bgColor;
    Color iconColor;
    IconData iconData;

    switch (status) {
      case 'expired':
        borderColor = Colors.red;
        bgColor = Colors.red.shade50;
        iconColor = Colors.red;
        iconData = LucideIcons.xCircle;
        break;
      case 'expiring':
        borderColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        iconData = LucideIcons.alertTriangle;
        break;
      default:
        borderColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.05);
        iconColor = const Color(0xFF4CAF50);
        iconData = LucideIcons.checkCircle;
    }

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(_getIconForDoc(doc['icon_name']), color: iconColor),
        ),
        title: Text(doc['document_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Expires: ${doc['expiry_date'].toString().split('T')[0]}'),
            if (days >= 0)
              Text('$days days remaining', 
                style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
            if (days < 0)
              Text('Expired ${-days} days ago', 
                style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        trailing: Icon(iconData, color: iconColor),
      ),
    );

    // Add pulse animation if expiring
    if (status == 'expiring' || status == 'expired') {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: status == 'expiring' ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  IconData _getIconForDoc(String iconName) {
    switch (iconName) {
      case 'shield': return LucideIcons.shield;
      case 'leaf': return LucideIcons.leaf;
      case 'receipt': return LucideIcons.receipt;
      case 'credit_card': return LucideIcons.creditCard;
      default: return LucideIcons.fileText;
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const SizedBox(height: 100),
          );
        },
      ),
    );
  }
}
