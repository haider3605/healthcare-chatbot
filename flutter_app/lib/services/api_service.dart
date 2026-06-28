import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://healthcare-chatbot-production-ee7e.up.railway.app',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<List<String>> extractSymptoms(String message) async {
    final response = await _dio.post(
      '/extract-symptoms',
      data: {'message': message},
    );
    return List<String>.from(response.data['extracted_symptoms']);
  }

  Future<Map<String, dynamic>> predictSymptoms(List<String> symptoms) async {
    final response = await _dio.post(
      '/predict/symptoms',
      data: {'symptoms': symptoms},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> predictDiabetes(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/predict/diabetes', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> predictHeart(Map<String, dynamic> data) async {
    final response = await _dio.post('/predict/heart', data: data);
    return response.data;
  }

  Future<String> explainDisease(String disease, double confidence) async {
    final response = await _dio.post(
      '/explain',
      data: {'disease': disease, 'confidence': confidence},
    );
    return response.data['explanation'];
  }

  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    final response = await _dio.post(
      '/chat',
      data: {'message': message, 'history': history},
    );
    return response.data['response'];
  }

  Future<void> savePrediction({
    required String userId,
    required String diseaseType,
    required List<String> symptoms,
    required String predictedDisease,
    required double confidence,
    required String explanation,
  }) async {
    await _dio.post(
      '/save-prediction',
      data: {
        'user_id': userId,
        'disease_type': diseaseType,
        'symptoms': symptoms,
        'predicted_disease': predictedDisease,
        'confidence': confidence,
        'explanation': explanation,
      },
    );
  }

  Future<void> saveChat({
    required String userId,
    required String message,
    required String response,
  }) async {
    await _dio.post(
      '/save-chat',
      data: {'user_id': userId, 'message': message, 'response': response},
    );
  }

  Future<Map<String, dynamic>> getHistory(String userId) async {
    final response = await _dio.get('/history/$userId');
    return response.data;
  }
}
