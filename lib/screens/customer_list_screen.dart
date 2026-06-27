import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/lucide_compat.dart';
import '../core/theme.dart';
import '../providers/customer_provider.dart';
import '../models/customer_model.dart';
import 'customer_policy_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';

  void _openWhatsApp(BuildContext context, String mobile) {
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    final number = clean.startsWith('91') ? clean : '91$clean';
    final url = 'https://wa.me/$number';
    _launchAction(context, url, 'WhatsApp', mobile);
  }

  void _makeCall(BuildContext context, String mobile) {
    final url = 'tel:$mobile';
    _launchAction(context, url, 'Call', mobile);
  }

  /// Shows a dialog with the action info (replaces url_launcher without the package)
  void _launchAction(BuildContext context, String url, String type, String mobile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(type == 'WhatsApp' ? LucideIcons.messageCircle : LucideIcons.phone,
              color: type == 'WhatsApp' ? Colors.green : AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(type),
        ]),
        content: Text(type == 'WhatsApp'
            ? 'Open WhatsApp for $mobile?\n\n$url'
            : 'Call $mobile?'),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$type link copied: $url'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Copy Link'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deactivateOrActivate(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(customer.isActive ? 'Deactivate Customer?' : 'Activate Customer?'),
        content: Text(customer.isActive
            ? 'Are you sure you want to deactivate ${customer.fullName}?'
            : 'Are you sure you want to activate ${customer.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(customerProvider.notifier).toggleActive(customer.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${customer.fullName} ${customer.isActive ? 'deactivated' : 'activated'}'),
                backgroundColor: customer.isActive ? Colors.orange : Colors.green,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: customer.isActive ? AppColors.warning : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(customer.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer?'),
        content: Text('Are you sure you want to completely delete ${customer.fullName}? This action cannot be undone and will delete all their policies.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(customerProvider.notifier).deleteCustomer(customer.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${customer.fullName} deleted successfully.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Failed to delete customer.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final allCustomers = customerState.asData?.value ?? [];
    final filtered = _searchQuery.isEmpty
        ? allCustomers
        : allCustomers.where((c) => c.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) || c.mobileNumber.contains(_searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${allCustomers.length} Total', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (filtered.isEmpty)
            Expanded(child: _buildEmpty())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildCustomerCard(context, filtered[index]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create_customer'),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.userPlus, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or phone…',
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No customers yet' : 'No customers match your search',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    final initials = customer.fullName.trim().isEmpty
        ? 'C'
        : customer.fullName
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/customer_detail',
                      arguments: {'customerId': customer.id.toString()},
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppThemeHelper.textPrimary(context),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.mobileNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppThemeHelper.textSecondary(context),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (customer.email != null && customer.email!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            customer.email!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppThemeHelper.textSecondary(context),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                        if ((customer.city ?? '').isNotEmpty || (customer.state ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${customer.city ?? ''}${(customer.city ?? '').isNotEmpty && (customer.state ?? '').isNotEmpty ? ', ' : ''}${customer.state ?? ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppThemeHelper.textSecondary(context),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: customer.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: customer.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _deleteCustomer(context, customer),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _outlineButton(
                    'WhatsApp',
                    LucideIcons.messageCircle,
                    Colors.green,
                    () => _openWhatsApp(context, customer.mobileNumber),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _outlineButton(
                    'Call',
                    LucideIcons.phone,
                    Colors.blue,
                    () => _makeCall(context, customer.mobileNumber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _filledButton(
                    customer.isActive ? 'Deactivate' : 'Activate',
                    customer.isActive ? LucideIcons.ban : LucideIcons.checkCircle,
                    customer.isActive ? AppColors.warning : Colors.green,
                    () => _deactivateOrActivate(context, customer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filledButton(
                    'All Policy',
                    LucideIcons.shield,
                    AppColors.primary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerPolicyScreen(
                          customerId: customer.id,
                          customerName: customer.fullName,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _filledButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
