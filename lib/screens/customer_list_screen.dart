import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name or mobile...',
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
              : null,
          fillColor: Colors.white,
          filled: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No customers found for "$_searchQuery"' : 'No customers yet',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create_customer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('Add First Customer'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Header Row ──────────────────────────────────────
            Row(children: [
              CircleAvatar(
                backgroundColor: customer.isActive ? AppColors.primary : Colors.grey,
                child: Text(customer.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${customer.gender ?? 'N/A'} • ${customer.city ?? customer.state ?? 'N/A'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (customer.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  customer.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(color: customer.isActive ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]),

            const Divider(height: 24),

            // ── Mobile Row ──────────────────────────────────────
            Row(children: [
              const Icon(LucideIcons.phone, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(customer.mobileNumber, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
              if (customer.email != null && customer.email!.isNotEmpty) ...[
                const Icon(LucideIcons.mail, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(child: Text(customer.email!, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ]),

            // ── Location Row ────────────────────────────────────
            if ((customer.state != null && customer.state!.isNotEmpty) || (customer.city != null && customer.city!.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  [customer.city, customer.state].where((e) => e != null && e.isNotEmpty).join(', '),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ]),
            ],

            const SizedBox(height: 12),

            // ── Credentials Box ─────────────────────────────────
            _buildCredentialsBox(customer),

            const SizedBox(height: 16),

            // ── Action Buttons Row 1 ────────────────────────────
            Row(children: [
              Expanded(child: _outlineButton(
                'WhatsApp',
                LucideIcons.messageCircle,
                Colors.green,
                () => _openWhatsApp(context, customer.mobileNumber),
              )),
              const SizedBox(width: 12),
              Expanded(child: _outlineButton(
                'Call',
                LucideIcons.phone,
                Colors.blue,
                () => _makeCall(context, customer.mobileNumber),
              )),
            ]),
            const SizedBox(height: 8),

            // ── Action Buttons Row 2 ────────────────────────────
            Row(children: [
              Expanded(child: _filledButton(
                customer.isActive ? 'Deactivate' : 'Activate',
                customer.isActive ? LucideIcons.ban : LucideIcons.checkCircle,
                customer.isActive ? AppColors.warning : Colors.green,
                () => _deactivateOrActivate(context, customer),
              )),
              const SizedBox(width: 12),
              Expanded(child: _filledButton(
                'All Policy',
                LucideIcons.shield,
                AppColors.primary,
                () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CustomerPolicyScreen(
                    customerId: customer.id,
                    customerName: customer.fullName,
                  ),
                )),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsBox(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.user, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('ID: ${customer.generatedUsername ?? 'N/A'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(LucideIcons.lock, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Pass: ${customer.generatedPassword ?? 'N/A'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ])),
        ElevatedButton.icon(
          onPressed: () {
            final text = 'ID: ${customer.generatedUsername}, Pass: ${customer.generatedPassword}';
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Credentials copied to clipboard!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ));
          },
          icon: const Icon(LucideIcons.copy, size: 14),
          label: const Text('Copy'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            minimumSize: const Size(80, 32), padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ]),
    );
  }

  Widget _outlineButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _filledButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
