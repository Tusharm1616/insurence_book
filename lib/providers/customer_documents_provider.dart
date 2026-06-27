import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ── Data Model ───────────────────────────────────────────────────────────────

class CustomerDocument {
  final String id;
  final String documentType;
  final String documentName;
  final String fileUrl;
  final int fileSize;
  final String uploadedAt;

  CustomerDocument({
    required this.id,
    required this.documentType,
    required this.documentName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory CustomerDocument.fromJson(Map<String, dynamic> json) {
    return CustomerDocument(
      id: json['id']?.toString() ?? '',
      documentType: json['document_type'] ?? 'Other',
      documentName: json['document_name'] ?? '',
      fileUrl: json['file_url'] ?? '',
      fileSize: json['file_size'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
    );
  }

  /// Returns true if the file is a PDF based on name
  bool get isPdf {
    final lower = documentName.toLowerCase();
    return lower.endsWith('.pdf');
  }

  /// Returns true if the file is an image
  bool get isImage {
    final lower = documentName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  /// Human-readable file size
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Provider to fetch documents ──────────────────────────────────────────────

final customerDocumentsProvider =
    FutureProvider.family<List<CustomerDocument>, String>((ref, customerId) async {
  final response = await apiService.dio.get('/api/customers/$customerId/documents');
  final List<dynamic> data = response.data as List<dynamic>;
  return data.map((d) => CustomerDocument.fromJson(d as Map<String, dynamic>)).toList();
});

// ── Upload progress provider ─────────────────────────────────────────────────

final uploadProgressProvider = NotifierProvider<UploadProgressNotifier, double?>(
  UploadProgressNotifier.new,
);

class UploadProgressNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  void setProgress(double value) => state = value;
  void clear() => state = null;
}

// ── Service functions for mutations ──────────────────────────────────────────

Future<bool> uploadCustomerDocument({
  required String customerId,
  required String documentType,
  required String filePath,
  required String fileName,
  required WidgetRef ref,
}) async {
  try {
    ref.read(uploadProgressProvider.notifier).setProgress(0.0);

    final formData = FormData.fromMap({
      'document_type': documentType,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    await apiService.dio.post(
      '/api/customers/$customerId/documents',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) {
          ref.read(uploadProgressProvider.notifier).setProgress(sent / total);
        }
      },
    );

    ref.read(uploadProgressProvider.notifier).clear();
    // Invalidate to refresh the list
    ref.invalidate(customerDocumentsProvider(customerId));
    return true;
  } catch (e) {
    ref.read(uploadProgressProvider.notifier).clear();
    return false;
  }
}

Future<bool> deleteCustomerDocument({
  required String customerId,
  required String documentId,
  required WidgetRef ref,
}) async {
  try {
    await apiService.dio.delete('/api/customers/$customerId/documents/$documentId');
    ref.invalidate(customerDocumentsProvider(customerId));
    return true;
  } catch (e) {
    return false;
  }
}
