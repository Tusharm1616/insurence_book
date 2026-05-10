import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/terms_provider.dart';
import '../models/terms_model.dart';

class TermsConditionsScreen extends ConsumerStatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  ConsumerState<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends ConsumerState<TermsConditionsScreen> {
  String _searchQuery = '';
  bool _hasAccepted = false;
  final _searchController = TextEditingController();
  final Set<int> _expandedSections = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'info': return LucideIcons.info;
      case 'check_circle': return LucideIcons.checkCircle2;
      case 'person': return LucideIcons.user;
      case 'shield': return LucideIcons.shield;
      case 'message': return LucideIcons.messageSquare;
      case 'trending_up': return LucideIcons.trendingUp;
      case 'currency_rupee': return LucideIcons.indianRupee;
      case 'cloud': return LucideIcons.cloud;
      case 'lock': return LucideIcons.lock;
      case 'block': return LucideIcons.ban;
      case 'gavel': return LucideIcons.scale;
      case 'extension': return LucideIcons.puzzle;
      case 'update': return LucideIcons.refreshCw;
      case 'support_agent': return LucideIcons.headphones;
      default: return LucideIcons.fileText;
    }
  }

  Color _getSectionColor(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF25D366),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF607D8B),
      const Color(0xFF795548),
      const Color(0xFFF44336),
      const Color(0xFF3F51B5),
      const Color(0xFF00BCD4),
      const Color(0xFF8BC34A),
      const Color(0xFF009688),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final termsAsync = ref.watch(termsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: termsAsync.when(
        loading: () => _buildFallbackTerms(), // Show fallback terms immediately for "instant" load
        error: (e, _) => _buildFallbackTerms(),
        data: (terms) => _buildTermsBody(terms),
      ),
    );
  }

  Widget _buildTermsBody(TermsModel terms) {
    final filteredSections = _searchQuery.isEmpty
        ? terms.sections
        : terms.sections.where((s) {
            final q = _searchQuery.toLowerCase();
            if (s.title.toLowerCase().contains(q)) return true;
            return s.content.any((c) => c.toLowerCase().contains(q));
          }).toList();

    return Column(
      children: [
        // Header Banner
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Text(terms.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          'Version ${terms.version} | Updated: ${_formatDate(terms.updatedAt)}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search terms...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(LucideIcons.search, size: 20, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sections List
        Expanded(
          child: filteredSections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.searchX, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No sections match your search', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: filteredSections.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredSections.length) {
                      return _buildAcceptanceCard();
                    }
                    final section = filteredSections[index];
                    final color = _getSectionColor(section.id - 1);
                    final isExpanded = _expandedSections.contains(section.id);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: isExpanded
                            ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                            : null,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: ValueKey(section.id),
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              if (expanded) {
                                _expandedSections.add(section.id);
                              } else {
                                _expandedSections.remove(section.id);
                              }
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getIcon(section.icon), color: color, size: 20),
                          ),
                          title: Text(
                            '${section.id}. ${section.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1D26)),
                          ),
                          trailing: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(LucideIcons.chevronDown, color: color, size: 20),
                          ),
                          children: section.content.map((line) => _buildContentLine(line, color)).toList(),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildContentLine(String line, Color accentColor) {
    final isBullet = line.startsWith('\u2022');
    final isEmoji = line.startsWith('\u{1F4E7}') || line.startsWith('\u{1F4F1}') || line.startsWith('\u{1F4DE}') || line.startsWith('\u{1F3E2}');

    if (isBullet) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                line.substring(2),
                style: const TextStyle(fontSize: 13, color: Color(0xFF444654), height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    if (isEmoji) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(line, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
        ),
      );
    }

    final isHeading = line.endsWith(':');
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        line,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeading ? FontWeight.w600 : FontWeight.normal,
          color: isHeading ? const Color(0xFF1A1D26) : const Color(0xFF444654),
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildAcceptanceCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Agreement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1D26))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _hasAccepted = !_hasAccepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _hasAccepted,
                    onChanged: (v) => setState(() => _hasAccepted = v ?? false),
                    activeColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'I have read and agree to the Terms & Conditions, Privacy Policy, and WhatsApp Communication Consent of InsureBook.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF444654), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasAccepted
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Terms accepted successfully!'),
                          ]),
                          backgroundColor: const Color(0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('Accept Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'InsureBook CRM v1.0.0',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackTerms() {
    final fallback = TermsModel(
      id: 0,
      title: 'Terms and Conditions',
      version: '1.0.0',
      updatedAt: DateTime.now(),
      sections: _fallbackSections(),
    );
    return _buildTermsBody(fallback);
  }

  List<TermsSection> _fallbackSections() {
    return [
      TermsSection(id: 1, title: 'Introduction', icon: 'info', content: [
        'Welcome to InsureBook \u2014 an advanced Insurance CRM and WhatsApp Reminder Application.',
        'This application provides:',
        '\u2022 Insurance customer relationship management (CRM)',
        '\u2022 Policy creation, tracking, and renewal management',
        '\u2022 Automated WhatsApp reminder services',
        '\u2022 Insurance lead management and conversion tracking',
      ]),
      TermsSection(id: 2, title: 'User Acceptance', icon: 'check_circle', content: [
        'By using InsureBook, you agree to these Terms & Conditions.',
        '\u2022 Users must agree to all terms before using the application',
        '\u2022 Continued use constitutes ongoing acceptance',
      ]),
      TermsSection(id: 3, title: 'User Responsibilities', icon: 'person', content: [
        '\u2022 Provide accurate customer information',
        '\u2022 Maintain account confidentiality',
        '\u2022 Do not misuse customer data',
        '\u2022 Do not send spam messages',
      ]),
      TermsSection(id: 4, title: 'Customer Data & Privacy', icon: 'shield', content: [
        '\u2022 Customer data is securely stored',
        '\u2022 Information used only for insurance services',
        '\u2022 Personal information will not be sold to third parties',
        '\u2022 Encrypted passwords and secure APIs',
      ]),
      TermsSection(id: 5, title: 'WhatsApp Reminder Consent', icon: 'message', content: [
        '\u2022 Customers agree to receive WhatsApp reminders',
        '\u2022 Messages include renewal alerts, birthday wishes, and notifications',
        '\u2022 Users can opt out anytime',
      ]),
      TermsSection(id: 6, title: 'Lead Management Policy', icon: 'trending_up', content: [
        '\u2022 Leads are customer enquiries before policy purchase',
        '\u2022 Lead information used for follow-up and sales management',
      ]),
      TermsSection(id: 7, title: 'Payment & Premium Disclaimer', icon: 'currency_rupee', content: [
        '\u2022 Premium amounts may vary',
        '\u2022 Insurance approval depends on insurance company policies',
        '\u2022 Application acts as CRM and management platform only',
      ]),
      TermsSection(id: 8, title: 'Account Security', icon: 'lock', content: [
        '\u2022 Users are responsible for password security',
        '\u2022 Unauthorized access must be reported immediately',
      ]),
      TermsSection(id: 9, title: 'Prohibited Activities', icon: 'block', content: [
        '\u2022 No spam WhatsApp messages',
        '\u2022 No malicious file uploads',
        '\u2022 No unauthorized data access',
        '\u2022 Violation may lead to account suspension',
      ]),
      TermsSection(id: 10, title: 'Limitation of Liability', icon: 'gavel', content: [
        '\u2022 App is provided as management software',
        '\u2022 Not responsible for external API downtime',
        '\u2022 Insurance decisions depend on insurance providers',
      ]),
      TermsSection(id: 11, title: 'Contact & Support', icon: 'support_agent', content: [
        'Email: support@insurebook.in',
        'WhatsApp: +91-7875024546',
        'Phone: +91-7875024546',
      ]),
    ];
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
