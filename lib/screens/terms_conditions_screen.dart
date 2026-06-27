import 'package:flutter/material.dart';
import '../utils/lucide_compat.dart';
import '../core/theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildDocHeader(context),
          const SizedBox(height: 20),
          ..._sections(context),
          const SizedBox(height: 32),
          _buildFooter(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Document header ───────────────────────────────────────────────────
  Widget _buildDocHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.scale, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'InsureBook CRM  •  Version 1.0.0',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last updated: 10 May 2026',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── All sections ──────────────────────────────────────────────────────
  List<Widget> _sections(BuildContext context) {
    final data = _sectionData();
    return data.map((s) => _buildSection(context, s)).toList();
  }

  Widget _buildSection(BuildContext context, _TermsSection s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeHelper.borderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s.icon, color: s.color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${s.number}. ${s.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppThemeHelper.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(height: 1, color: AppThemeHelper.dividerColor(context)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: s.items.map((line) => _buildLine(context, line, s.color)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(BuildContext context, _TermsLine line, Color accent) {
    switch (line.type) {
      case _LineType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            line.text,
            style: TextStyle(fontSize: 13, color: AppThemeHelper.textSecondary(context), height: 1.6),
          ),
        );

      case _LineType.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line.text,
                  style: TextStyle(fontSize: 13, color: AppThemeHelper.textSecondary(context), height: 1.6),
                ),
              ),
            ],
          ),
        );

      case _LineType.subheading:
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            line.text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppThemeHelper.textPrimary(context)),
          ),
        );

      case _LineType.contact:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.arrowRight, size: 12, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.text,
                    style: TextStyle(fontSize: 13, color: AppThemeHelper.textPrimary(context), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  // ── Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeHelper.surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            'InsureBook CRM v1.0.0',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppThemeHelper.textPrimary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'By using this application, you agree to all of the above terms and conditions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Static section data ───────────────────────────────────────────────
  List<_TermsSection> _sectionData() => [
    _TermsSection(
      number: 1, title: 'Introduction', icon: LucideIcons.info,
      color: const Color(0xFF4CAF50),
      items: [
        _p('Welcome to InsureBook — an advanced Insurance CRM and WhatsApp Reminder Application designed for professional insurance agents.'),
        _p('This application provides:'),
        _b('Insurance customer relationship management (CRM)'),
        _b('Policy creation, tracking, and renewal management'),
        _b('Automated WhatsApp reminder services'),
        _b('Insurance lead management and conversion tracking'),
      ],
    ),
    _TermsSection(
      number: 2, title: 'User Acceptance', icon: LucideIcons.checkCircle2,
      color: const Color(0xFF2196F3),
      items: [
        _p('By using InsureBook, you agree to these Terms & Conditions in full.'),
        _b('Users must review and accept all terms before using the application'),
        _b('Continued use of the application constitutes ongoing acceptance'),
        _b('Terms may be updated; continued use after updates implies acceptance'),
      ],
    ),
    _TermsSection(
      number: 3, title: 'User Responsibilities', icon: LucideIcons.user,
      color: const Color(0xFFFF9800),
      items: [
        _b('Provide accurate and up-to-date customer information at all times'),
        _b('Maintain the confidentiality of your account credentials'),
        _b('Do not share your login credentials with any third party'),
        _b('Do not misuse, sell, or transfer customer data'),
        _b('Do not send unsolicited or spam messages to customers'),
      ],
    ),
    _TermsSection(
      number: 4, title: 'Customer Data & Privacy', icon: LucideIcons.shield,
      color: const Color(0xFFE91E63),
      items: [
        _b('All customer data is securely stored with encryption'),
        _b('Information is used exclusively for insurance management services'),
        _b('Personal information will never be sold to third parties'),
        _b('Passwords are hashed and API communication is secured via HTTPS'),
        _b('Agents are responsible for the accuracy of data they enter'),
      ],
    ),
    _TermsSection(
      number: 5, title: 'WhatsApp Reminder Consent', icon: LucideIcons.messageSquare,
      color: const Color(0xFF25D366),
      items: [
        _p('By adding customers to InsureBook, you confirm that:'),
        _b('Customers have consented to receive WhatsApp messages from you'),
        _b('Messages may include policy renewal alerts, birthday wishes, and notifications'),
        _b('Customers can opt out at any time by informing you directly'),
        _b('You are responsible for obtaining WhatsApp communication consent'),
      ],
    ),
    _TermsSection(
      number: 6, title: 'Lead Management Policy', icon: LucideIcons.trendingUp,
      color: const Color(0xFF9C27B0),
      items: [
        _b('Leads represent customer enquiries prior to policy purchase'),
        _b('Lead information is to be used strictly for follow-up and sales management'),
        _b('Misuse of lead data for non-insurance purposes is prohibited'),
        _b('Leads must be handled professionally and with customer consent'),
      ],
    ),
    _TermsSection(
      number: 7, title: 'Payment & Premium Disclaimer', icon: LucideIcons.indianRupee,
      color: const Color(0xFFFF5722),
      items: [
        _p('InsureBook is a CRM and management platform only. It does not process or facilitate insurance payments.'),
        _b('Premium amounts displayed may vary based on insurer updates'),
        _b('Policy approval depends entirely on the respective insurance company'),
        _b('InsureBook holds no liability for payment disputes or premium errors'),
        _b('Always verify premiums directly with the insurance provider'),
      ],
    ),
    _TermsSection(
      number: 8, title: 'Account Security', icon: LucideIcons.lock,
      color: const Color(0xFF607D8B),
      items: [
        _b('You are fully responsible for maintaining your account password securely'),
        _b('Report any unauthorized access to your account immediately'),
        _b('InsureBook reserves the right to suspend accounts showing suspicious activity'),
        _b('Use strong passwords and do not reuse passwords from other services'),
      ],
    ),
    _TermsSection(
      number: 9, title: 'Prohibited Activities', icon: LucideIcons.ban,
      color: const Color(0xFFF44336),
      items: [
        _b('Sending spam or unsolicited WhatsApp messages to customers'),
        _b('Uploading malicious files or attempting to compromise system security'),
        _b('Accessing other agents\' accounts or customer data without authorization'),
        _b('Using the application for non-insurance commercial activities'),
        _b('Violation of any terms may result in immediate account suspension'),
      ],
    ),
    _TermsSection(
      number: 10, title: 'Limitation of Liability', icon: LucideIcons.scale,
      color: const Color(0xFF3F51B5),
      items: [
        _p('InsureBook is provided as a management software platform. We do not guarantee:'),
        _b('Availability or uptime of third-party APIs or WhatsApp services'),
        _b('Approval or issuance of any insurance policy by providers'),
        _b('Accuracy of premium calculations for all regions and providers'),
        _p('Our maximum liability is limited to the subscription fees paid for the service.'),
      ],
    ),
    _TermsSection(
      number: 11, title: 'Contact & Support', icon: LucideIcons.headphones,
      color: const Color(0xFF009688),
      items: [
        _p('For any questions, issues, or grievances, please contact us through:'),
        _c('📧  Email: support@insurebook.in'),
        _c('📱  WhatsApp: +91-7875024546'),
        _c('📞  Phone: +91-7875024546'),
        _c('🏢  Office: 123 Business Hub, Pune, Maharashtra'),
      ],
    ),
  ];

  static _TermsLine _p(String t) => _TermsLine(_LineType.paragraph, t);
  static _TermsLine _b(String t) => _TermsLine(_LineType.bullet, t);
  static _TermsLine _c(String t) => _TermsLine(_LineType.contact, t);
}

// ── Data models ───────────────────────────────────────────────────────────
enum _LineType { paragraph, bullet, subheading, contact }

class _TermsLine {
  final _LineType type;
  final String text;
  const _TermsLine(this.type, this.text);
}

class _TermsSection {
  final int number;
  final String title;
  final IconData icon;
  final Color color;
  final List<_TermsLine> items;
  const _TermsSection({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}
