import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Lead Model ───────────────────────────────────────────────────────────────

enum LeadStatus { newLead, followup, converted, lost, unassigned }

extension LeadStatusLabel on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.newLead:    return 'New';
      case LeadStatus.followup:   return 'Follow-up';
      case LeadStatus.converted:  return 'Converted';
      case LeadStatus.lost:       return 'Lost';
      case LeadStatus.unassigned: return 'Unassigned';
    }
  }
}

class Lead {
  final int id;
  final String name;
  final String mobile;
  final String email;
  final String insuranceType;
  final String notes;
  final LeadStatus status;
  final DateTime createdAt;
  final DateTime? followupDate;
  final String source; // Walk-in, Referral, Online, Call, Other

  const Lead({
    required this.id,
    required this.name,
    required this.mobile,
    this.email = '',
    required this.insuranceType,
    this.notes = '',
    required this.status,
    required this.createdAt,
    this.followupDate,
    this.source = 'Walk-in',
  });

  Lead copyWith({
    String? name,
    String? mobile,
    String? email,
    String? insuranceType,
    String? notes,
    LeadStatus? status,
    DateTime? followupDate,
    String? source,
  }) => Lead(
    id: id,
    name: name ?? this.name,
    mobile: mobile ?? this.mobile,
    email: email ?? this.email,
    insuranceType: insuranceType ?? this.insuranceType,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    createdAt: createdAt,
    followupDate: followupDate ?? this.followupDate,
    source: source ?? this.source,
  );
}

// ─── Lead Provider ────────────────────────────────────────────────────────────

final leadProvider = NotifierProvider<LeadNotifier, List<Lead>>(() => LeadNotifier());

class LeadNotifier extends Notifier<List<Lead>> {
  @override
  List<Lead> build() {
    return [];
  }

  void addLead(Lead lead) => state = [...state, lead];

  void updateStatus(int id, LeadStatus status) {
    state = state.map((l) => l.id == id ? l.copyWith(status: status) : l).toList();
  }

  void deleteLead(int id) => state = state.where((l) => l.id != id).toList();
}

// Derived providers
final newLeadsProvider = Provider<List<Lead>>((ref) => ref.watch(leadProvider).where((l) => l.status == LeadStatus.newLead).toList());
final unassignedLeadsProvider = Provider<List<Lead>>((ref) => ref.watch(leadProvider).where((l) => l.status == LeadStatus.unassigned).toList());
final convertedLeadsProvider = Provider<List<Lead>>((ref) => ref.watch(leadProvider).where((l) => l.status == LeadStatus.converted).toList());
final lostLeadsProvider = Provider<List<Lead>>((ref) => ref.watch(leadProvider).where((l) => l.status == LeadStatus.lost).toList());
final todayFollowupsProvider = Provider<List<Lead>>((ref) {
  final today = DateTime.now();
  return ref.watch(leadProvider).where((l) {
    if (l.followupDate == null) return false;
    final f = l.followupDate!;
    return f.year == today.year && f.month == today.month && f.day == today.day;
  }).toList();
});
final overdueFollowupsProvider = Provider<List<Lead>>((ref) {
  final today = DateTime.now();
  return ref.watch(leadProvider).where((l) {
    if (l.followupDate == null) return false;
    return l.followupDate!.isBefore(DateTime(today.year, today.month, today.day)) && l.status == LeadStatus.followup;
  }).toList();
});
