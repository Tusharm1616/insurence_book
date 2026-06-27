import 'package:dio/dio.dart';
import 'api_service.dart';

class LeadService {
  final Dio _dio = apiService.dio;

  Future<List<Map<String, dynamic>>> getLeads() async {
    final response = await _dio.get('/leads/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createLead(Map<String, dynamic> data) async {
    final response = await _dio.post('/leads/', data: data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> updateLead(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/leads/$id', data: data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> deleteLead(int id) async {
    await _dio.delete('/leads/$id');
  }

  Future<Map<String, dynamic>> convertLead(int id) async {
    final response = await _dio.post('/leads/$id/convert');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getTodayFollowups() async {
    final response = await _dio.get('/leads/today-followups');
    return Map<String, dynamic>.from(response.data);
  }
}

final leadService = LeadService();
