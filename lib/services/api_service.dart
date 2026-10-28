import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

const String apiBaseUrl = 'https://quiz-yu-v2-cki8.vercel.app';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    final String baseUrl = _getBaseUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logger interceptor for debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[API Request] ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API Response] ${response.statusCode} from ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint('[API Error] ${e.message} from ${e.requestOptions.path}');
        return handler.next(e);
      },
    ));
  }

  // URL Backend Produksi Vercel
  static const bool _useLocalServer = false; // Ubah ke true jika ingin memakai server lokal

  String _getBaseUrl() {
    if (!_useLocalServer) {
      return apiBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    // Android emulator loops back to localhost via 10.0.2.2
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Helper to extract clean user-friendly network and offline error messages.
  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        (e.error != null && e.error.toString().contains('SocketException'))) {
      debugPrint('🌐 [LOG TIDAK ADA KONEKSI INTERNET] Perangkat offline / jaringan terputus (Path: ${e.requestOptions.path})');
      return '[OFFLINE] Tidak ada koneksi internet. Silakan periksa jaringan Anda dan coba lagi.';
    }

    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('error_message')) {
        final msg = data['error_message'].toString();
        if (msg.contains('429') || msg.contains('Rate Limit') || msg.contains('kuota')) {
          debugPrint('⏳ [LOG BATAS KUOTA AI GEMINI TERLAMPAUI] Pemanggilan AI melebihi kuota 429 pada path ${e.requestOptions.path}');
          return '[QUOTA_EXCEEDED] Batas Kuota Gratis AI Gemini Terlampaui (Rate Limit 429). Silakan tunggu 30 detik lalu tekan Coba Lagi.';
        }
        return msg;
      }
    }

    final String msg = e.response?.data?.toString() ?? e.message ?? 'Unknown error';

    if (msg.contains('[OFFLINE]') || msg.contains('[QUOTA_EXCEEDED]') || msg.contains('[SYSTEM_ERROR]')) {
      return msg;
    }

    if (msg.contains('Connection refused') || msg.toLowerCase().contains('failed to connect')) {
      debugPrint('🌐 [LOG SERVER BACKEND MATI] Koneksi ditolak pada path ${e.requestOptions.path}');
      return '[OFFLINE] Server backend Express belum berjalan di port 3000. Pastikan server backend (npm start) sudah dinyalakan.';
    }

    if (msg.contains('429') || msg.contains('Quota exceeded') || msg.contains('Rate Limit')) {
      debugPrint('⏳ [LOG BATAS KUOTA AI GEMINI TERLAMPAUI] Kuota pemanggilan AI terlampaui pada path ${e.requestOptions.path}');
      return '[QUOTA_EXCEEDED] Batas Kuota Gratis AI Gemini Terlampaui (Rate Limit 429). Silakan tunggu 30 detik lalu tekan Coba Lagi.';
    }

    final cleanMsg = msg.length > 120 ? '${msg.substring(0, 120)}...' : msg;
    debugPrint('❌ [LOG KESALAHAN SISTEM] $cleanMsg');
    return '[SYSTEM_ERROR] Terjadi kesalahan sistem: $cleanMsg';
  }

  /// Calls POST /api/generate-quiz to get a list of structured questions.
  Future<Map<String, dynamic>> generateQuiz({
    required String topic,
    required int count,
    required String difficulty,
    required String modelVersion,
  }) async {
    try {
      final response = await _dio.post(
        '/api/generate-quiz',
        data: {
          'topic': topic,
          'count': count,
          'difficulty': difficulty,
          'modelVersion': modelVersion,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw Exception('Format respon tidak sesuai. Diharapkan JSON object.');
      }
    } on DioException catch (e) {
      final String errMsg = _parseDioError(e);
      throw Exception(errMsg);
    }
  }

  /// Calls POST /api/generate-study-guide to generate a Markdown guide based on wrong answers.
  Future<String> generateStudyGuide({
    required String topic,
    required List<Map<String, dynamic>> incorrectQuestions,
  }) async {
    try {
      final response = await _dio.post(
        '/api/generate-study-guide',
        data: {
          'topic': topic,
          'incorrectQuestions': incorrectQuestions,
        },
        options: Options(
          responseType: ResponseType.plain, // Return text/markdown directly
        ),
      );

      return response.data?.toString() ?? '';
    } on DioException catch (e) {
      final String errMsg = _parseDioError(e);
      throw Exception(errMsg);
    }
  }
}
