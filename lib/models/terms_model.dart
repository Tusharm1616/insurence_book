class TermsSection {
  final int id;
  final String title;
  final String icon;
  final List<String> content;

  TermsSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.content,
  });

  factory TermsSection.fromJson(Map<String, dynamic> json) {
    return TermsSection(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      icon: json['icon'] ?? 'info',
      content: List<String>.from(json['content'] ?? []),
    );
  }
}

class TermsModel {
  final int id;
  final String title;
  final String version;
  final List<TermsSection> sections;
  final DateTime updatedAt;

  TermsModel({
    required this.id,
    required this.title,
    required this.version,
    required this.sections,
    required this.updatedAt,
  });

  factory TermsModel.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    return TermsModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Terms and Conditions',
      version: json['version'] ?? '1.0.0',
      sections: contentList.map((s) => TermsSection.fromJson(s)).toList(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
