import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/lead_service.dart';
import '../services/notification_service.dart';

// ─── Lead Status ──────────────────────────────────────────────────────────────

enum LeadStatus {
  newLead,
  contacted,
  followupScheduled,
  proposalSent,
  negotiation,
  converted,
  lost,
  unassigned,
}

extension LeadStatusLabel on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.followupScheduled:
        return 'Follow-up Scheduled';
      case LeadStatus.proposalSent:
        return 'Proposal Sent';
      case LeadStatus.negotiation:
        return 'Negotiation';
      case LeadStatus.converted:
        return 'Converted';
      case LeadStatus.lost:
        return 'Lost';
      case LeadStatus.unassigned:
        return 'Unassigned';
    }
  }

  String get apiValue {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.followupScheduled:
        return 'Follow-up Scheduled';
      case LeadStatus.proposalSent:
        return 'Proposal Sent';
      case LeadStatus.negotiation:
        return 'Negotiation';
      case LeadStatus.converted:
        return 'Converted';
      case LeadStatus.lost:
        return 'Lost';
      case LeadStatus.unassigned:
        return 'Unassigned';
    }
  }

  static LeadStatus fromApi(String value) {
    switch (value) {
      case 'New':
        return LeadStatus.newLead;
      case 'Contacted':
        return LeadStatus.contacted;
      case 'Follow-up Scheduled':
        return LeadStatus.followupScheduled;
      case 'Proposal Sent':
        return LeadStatus.proposalSent;
      case 'Negotiation':
        return LeadStatus.negotiation;
      case 'Converted':
        return LeadStatus.converted;
      case 'Lost':
        return LeadStatus.lost;
      case 'Unassigned':
        return LeadStatus.unassigned;
      default:
        return LeadStatus.newLead;
    }
  }
}

// ─── Lead Model ───────────────────────────────────────────────────────────────

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
  final String source;
  final int? convertedCustomerId;

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
    this.convertedCustomerId,
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
    int? convertedCustomerId,
  }) =>
      Lead(
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
        convertedCustomerId: convertedCustomerId ?? this.convertedCustomerId,
      );

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      mobile: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      insuranceType: json['insurance_type'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: LeadStatusLabel.fromApi(json['status'] as String? ?? 'New'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      followupDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      source: json['source'] as String? ?? 'Walk-in',
      convertedCustomerId: json['converted_customer_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': mobile,
      'email': email,
      'insurance_type': insuranceType,
      'notes': notes,
      'status': status.apiValue,
      'source': source,
      if (followupDate != null) 'follow_up_date': followupDate!.toIso8601String(),
    };
  }
}

// ─── Lead Provider (API-backed) ───────────────────────────────────────────────

final leadProvider =
    AsyncNotifierProvider<LeadNotifier, List<Lead>>(() => LeadNotifier());

class LeadNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() async {
    return await fetchLeads();
  }

  Future<List<Lead>> fetchLeads() async {
    try {
      final data = await leadService.getLeads();
      return data.map((json) => Lead.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await fetchLeads());
  }

  Future<Lead?> addLead(Map<String, dynamic> data) async {
    try {
      final result = await leadService.createLead(data);
      final newLead = Lead.fromJson(result);
      final current = state.value ?? [];
      state = AsyncValue.data([newLead, ...current]);

      // Schedule follow-up notification if applicable
      if (newLead.followupDate != null) {
        NotificationService().scheduleFollowupNotification(
          leadId: newLead.id,
          leadName: newLead.name,
          followupDate: newLead.followupDate!,
        );
      }

      return newLead;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateLead(int id, Map<String, dynamic> data) async {
    try {
      final result = await leadService.updateLead(id, data);
      final updatedLead = Lead.fromJson(result);
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((l) => l.id == id ? updatedLead : l).toList(),
      );

      // Schedule/cancel follow-up notification
      if (updatedLead.followupDate != null) {
        NotificationService().scheduleFollowupNotification(
          leadId: updatedLead.id,
          leadName: updatedLead.name,
          followupDate: updatedLead.followupDate!,
        );
      } else {
        NotificationService().cancelFollowupNotification(id);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLead(int id) async {
    try {
      await leadService.deleteLead(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((l) => l.id != id).toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> convertLead(int id) async {
    try {
      final result = await leadService.convertLead(id);
      // Refresh the list to get updated status
      await refresh();
      return result;
    } catch (e) {
      return null;
    }
  }
}

// ─── Derived providers ────────────────────────────────────────────────────────

final leadsListProvider = Provider<List<Lead>>((ref) {
  return ref.watch(leadProvider).value ?? [];
});

final newLeadsProvider = Provider<List<Lead>>((ref) {
  return ref.watch(leadsListProvider).where((l) => l.status == LeadStatus.newLead).toList();
});

final unassignedLeadsProvider = Provider<List<Lead>>((ref) {
  return ref.watch(leadsListProvider).where((l) => l.status == LeadStatus.unassigned).toList();
});

final convertedLeadsProvider = Provider<List<Lead>>((ref) {
  return ref.watch(leadsListProvider).where((l) => l.status == LeadStatus.converted).toList();
});

final lostLeadsProvider = Provider<List<Lead>>((ref) {
  return ref.watch(leadsListProvider).where((l) => l.status == LeadStatus.lost).toList();
});

final todayFollowupsProvider = Provider<List<Lead>>((ref) {
  final today = DateTime.now();
  return ref.watch(leadsListProvider).where((l) {
    if (l.followupDate == null) return false;
    final f = l.followupDate!;
    return f.year == today.year && f.month == today.month && f.day == today.day;
  }).toList();
});

final overdueFollowupsProvider = Provider<List<Lead>>((ref) {
  final today = DateTime.now();
  return ref.watch(leadsListProvider).where((l) {
    if (l.followupDate == null) return false;
    return l.followupDate!.isBefore(DateTime(today.year, today.month, today.day)) &&
        l.status == LeadStatus.followupScheduled;
  }).toList();
});
