import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/terms_model.dart';
import '../services/api_service.dart';

final termsProvider = FutureProvider<TermsModel>((ref) async {
  final response = await apiService.dio.get('/terms/');
  return TermsModel.fromJson(response.data);
});
