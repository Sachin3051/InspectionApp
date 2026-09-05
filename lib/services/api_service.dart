import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/form_model.dart';
import '../models/history_model.dart';
import '../models/answer_model.dart';

class ApiService {
  //static const String baseUrl = 'http://114.143.49.130:8006';
  static const String baseUrl = 'https://localhost:7265';
  //static const String baseUrl = 'https://192.168.1.4:7265';
  static const String apiBase = '$baseUrl/api/Inspection';

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // Agar Backend ne pehle se full URL bheja hai
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Relative path (/uploads/...) ke case me ApiService.baseUrl append karein
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  ApiService() {
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print(' [API DEBUG] $obj'),
    ));
  }

  Future<Map<String, dynamic>> login(String userName, String password) async {
    try {
      final response = await _dio.post('/Login', data: {
        'userName': userName,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print(' [API ERROR] login: ${e.response?.data}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<InspectionForm> getInspectionForm() async {
    try {
      final response = await _dio.get('/Form/1');
      return InspectionForm.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print(' [API ERROR] getInspectionForm: $e');
      final raw = await rootBundle.loadString('assets/mock/form_response.json');
      return InspectionForm.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  Future<List<InspectionHistory>> getInspectionHistory() async {
    try {
      final response = await _dio.get('/History');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => InspectionHistory.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print(' [API ERROR] getInspectionHistory: $e');
      final raw = await rootBundle.loadString('assets/mock/history_response.json');
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      return data.map((e) => InspectionHistory.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future saveInspection(
      Map<String, dynamic> payload,
      List<PickedImage> newImages,
      ) async {
    try {
      final formData = FormData();

      formData.fields.add(
        MapEntry("data", jsonEncode(payload)),
      );

      for (final image in newImages) {
        if (image.bytes != null) {
          formData.files.add(
            MapEntry(
              "files",
              MultipartFile.fromBytes(
                image.bytes!,
                filename: image.name,
              ),
            ),
          );
        }
      }

      final response = await _dio.post(
        "/Save",
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      print(e.response?.statusCode);
      print(e.response?.data);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInspectionEntry(String entryId) async {
    try {
      print(' [API DEBUG] getInspectionEntry: $entryId');
      final response = await _dio.get('/Edit/$entryId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print(' [API ERROR] getInspectionEntry: $e');
      throw 'Failed to load inspection details';
    }
  }
}
