import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';

/// Service for generating, downloading, and sharing policy PDFs.
class PolicyPdfService {
  /// Generate and share a policy PDF via native share sheet.
  /// Returns true on success, false on failure.
  static Future<bool> sharePolicyPdf({
    required BuildContext context,
    required String policyId,
    required String policyNumber,
    String? customerName,
  }) async {
    try {
      final filePath = await _downloadPolicyPdf(policyId, policyNumber);
      if (filePath == null) return false;

      final shareText = customerName != null
          ? 'Policy details for $customerName — $policyNumber'
          : 'Policy details — $policyNumber';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: shareText,
        ),
      );
      return true;
    } on DioException catch (e) {
      if (context.mounted) {
        _showRetryDialog(
          context,
          message: _getErrorMessage(e),
          onRetry: () => sharePolicyPdf(
            context: context,
            policyId: policyId,
            policyNumber: policyNumber,
            customerName: customerName,
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        _showRetryDialog(
          context,
          message: 'Failed to generate PDF. Please try again.',
          onRetry: () => sharePolicyPdf(
            context: context,
            policyId: policyId,
            policyNumber: policyNumber,
            customerName: customerName,
          ),
        );
      }
      return false;
    }
  }

  /// Generate and save a policy PDF to the Downloads folder.
  /// Returns the file path on success, null on failure.
  static Future<String?> downloadPolicyPdf({
    required BuildContext context,
    required String policyId,
    required String policyNumber,
  }) async {
    try {
      final tempPath = await _downloadPolicyPdf(policyId, policyNumber);
      if (tempPath == null) return null;

      // Copy to a more permanent location (app's documents directory)
      final docsDir = await getApplicationDocumentsDirectory();
      final filename = 'Policy_${policyNumber.replaceAll(' ', '_')}.pdf';
      final destPath = '${docsDir.path}/$filename';
      final destFile = File(destPath);
      await File(tempPath).copy(destFile.path);

      return destFile.path;
    } on DioException catch (e) {
      if (context.mounted) {
        _showRetryDialog(
          context,
          message: _getErrorMessage(e),
          onRetry: () => downloadPolicyPdf(
            context: context,
            policyId: policyId,
            policyNumber: policyNumber,
          ),
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _showRetryDialog(
          context,
          message: 'Failed to download PDF. Please try again.',
          onRetry: () => downloadPolicyPdf(
            context: context,
            policyId: policyId,
            policyNumber: policyNumber,
          ),
        );
      }
      return null;
    }
  }

  /// Downloads the PDF from the API and saves to temp directory.
  static Future<String?> _downloadPolicyPdf(String policyId, String policyNumber) async {
    final tempDir = await getTemporaryDirectory();
    final filename = 'Policy_${policyNumber.replaceAll(' ', '_')}.pdf';
    final filePath = '${tempDir.path}/$filename';

    await apiService.dio.download(
      '/api/policies/$policyId/generate-pdf',
      filePath,
      options: Options(responseType: ResponseType.bytes),
    );

    final file = File(filePath);
    if (await file.exists() && await file.length() > 0) {
      return filePath;
    }
    return null;
  }

  static String _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Check your internet and try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }
    if (e.response?.statusCode == 404) {
      return 'Policy not found. It may have been deleted.';
    }
    if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
      return 'Server error. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }

  static void _showRetryDialog(
    BuildContext context, {
    required String message,
    required Future<dynamic> Function() onRetry,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
