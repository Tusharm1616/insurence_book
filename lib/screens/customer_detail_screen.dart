import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/customer_detail_provider.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final customerDetailAsync = ref.watch(customerDetailProvider(widget.customerId));
    
    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: customerDetailAsync.when(
          data: (customer) => Text(
            customer.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          loading: () => const Text(
            'Customer Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          error: (err, st) => const Text(
            'Error',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit_customer',
                arguments: {'customerId': widget.customerId},
              );
            },
          ),
        ],
      ),
      body: customerDetailAsync.when(
        data: (customer) => _buildCustomerDetail(context, customer),
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildCustomerDetail(BuildContext context, CustomerDetail customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info Card
          _buildPersonalInfoCard(context, customer),
          
          const SizedBox(height: 24),
          
          // Policies Section
          _buildPoliciesSection(context, customer),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, CustomerDetail customer) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            
            // Customer details
            _buildInfoRow('Full Name', customer.fullName),
            _buildInfoRow('Phone', customer.phone),
            _buildInfoRow('Email', customer.email),
            _buildInfoRow('Date of Birth', customer.dob.isNotEmpty ? _formatDate(customer.dob) : 'N/A'),
            _buildInfoRow('Address', customer.address.isNotEmpty ? customer.address : 'N/A'),
            _buildInfoRow('City', customer.city.isNotEmpty ? customer.city : 'N/A'),
            _buildInfoRow('State', customer.state.isNotEmpty ? customer.state : 'N/A'),
            _buildInfoRow('Pincode', customer.pincode.isNotEmpty ? customer.pincode : 'N/A'),
            
            const SizedBox(height: 16),
            
            // Status chip
            Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: customer.status == 'active' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.status == 'active' ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: customer.status == 'active' ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
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

  Widget _buildPoliciesSection(BuildContext context, CustomerDetail customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Policies (${customer.policies.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
                fontFamily: 'Poppins',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/add_policy',
                  arguments: {'customerId': widget.customerId},
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Policies list
        ...customer.policies.map((policy) => _buildPolicyMiniCard(context, policy)),
      ],
    );
  }

  Widget _buildPolicyMiniCard(BuildContext context, PolicyDetail policy) {
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
            // Policy number and type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    policy.policyNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1C),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPolicyTypeColor(policy.policyType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    policy.policyType,
                    style: TextStyle(
                      color: _getPolicyTypeColor(policy.policyType),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Insurer and plan
            Text(
              '${policy.insurerName} — ${policy.planName}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Sum insured and premium
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sum Insured: ₹${_formatCurrency(policy.sumInsured)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1C1C1C),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium: ₹${_formatCurrency(policy.premiumAmount)}/yr',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1C1C1C),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Start and end dates
            Text(
              'Start: ${_formatDate(policy.startDate)} → End: ${_formatDate(policy.endDate)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Bottom row with status and days remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPolicyStatusColor(policy.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    policy.status,
                    style: TextStyle(
                      color: _getPolicyStatusColor(policy.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                
                // Days remaining badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDaysRemainingColor(policy.endDate).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDaysRemainingText(policy.endDate),
                    style: TextStyle(
                      color: _getDaysRemainingColor(policy.endDate),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1C1C1C),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.danger,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(customerDetailProvider(widget.customerId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+$)'),
      (match) => '${match[1]}${match[2] != null ? ',' : ''}${match[2] ?? ''}',
    );
  }

  Color _getPolicyTypeColor(String policyType) {
    switch (policyType.toLowerCase()) {
      case 'motor':
        return Colors.blue;
      case 'health':
        return Colors.green;
      case 'life':
        return Colors.purple;
      case 'term':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPolicyStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'lapsed':
        return Colors.orange;
      case 'paidup':
        return Colors.purple;
      case 'matured':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getDaysRemainingColor(String endDate) {
    if (endDate.isEmpty) return Colors.grey;
    
    try {
      final date = DateTime.parse(endDate);
      final now = DateTime.now();
      final daysDifference = date.difference(now).inDays;
      
      if (daysDifference < 0) {
        return Colors.red; // Expired
      } else if (daysDifference <= 30) {
        return Colors.orange; // Expiring within 30 days
      } else if (daysDifference <= 60) {
        return Colors.amber; // Expiring within 60 days
      } else {
        return Colors.green; // More than 60 days
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getDaysRemainingText(String endDate) {
    if (endDate.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(endDate);
      final now = DateTime.now();
      final daysDifference = date.difference(now).inDays;
      
      if (daysDifference < 0) {
        return 'Expired ${daysDifference.abs()} days ago';
      } else if (daysDifference == 0) {
        return 'Expires Today';
      } else {
        return '$daysDifference days left';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
