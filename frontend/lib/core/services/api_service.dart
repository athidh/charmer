import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Centralized HTTP client for the CHARMER backend API.
/// All protected endpoints automatically include the JWT Bearer token.
class ApiService {
  static const String _baseUrl = 'http://localhost:5000/api';

  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ──────────────── Auth ────────────────

  /// POST /api/auth/signup
  Future<Map<String, dynamic>> signup(
    String username,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(res);
  }

  /// POST /api/auth/login → { token, username, role }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(res);
  }

  // ──────────────── AI Pipeline ────────────────

  /// POST /api/ai/voice-query — NDJSON streaming: yields STT phase then complete phase
  Stream<Map<String, dynamic>> voiceQueryStream(
    Uint8List audioBytes,
    String language,
  ) async* {
    final uri = Uri.parse('$_baseUrl/ai/voice-query');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields['language'] = language;
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'recording.wav',
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));

    // Read NDJSON: each line is a separate JSON object
    final body = await streamed.stream.bytesToString();
    final lines = body.split('\n').where((l) => l.trim().isNotEmpty);

    for (final line in lines) {
      try {
        final chunk = jsonDecode(line) as Map<String, dynamic>;
        // If it's an error phase, throw
        if (chunk['phase'] == 'error') {
          throw ApiException(
            statusCode: streamed.statusCode,
            message: chunk['error'] ?? 'Unknown error',
          );
        }
        yield chunk;
      } catch (e) {
        if (e is ApiException) rethrow;
        // Skip malformed lines
      }
    }
  }

  /// Convenience: non-streaming voiceQuery that returns the final 'complete' result
  Future<Map<String, dynamic>> voiceQuery(
    Uint8List audioBytes,
    String language,
  ) async {
    Map<String, dynamic> result = {};
    await for (final chunk in voiceQueryStream(audioBytes, language)) {
      result = chunk;
    }
    return result;
  }

  /// POST /api/ai/analyze-pdf — upload PDF for distillation
  Future<Map<String, dynamic>> analyzePdf(
    Uint8List pdfBytes,
    String filename,
    String language,
  ) async {
    final uri = Uri.parse('$_baseUrl/ai/analyze-pdf');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields['language'] = language;
    request.files.add(
      http.MultipartFile.fromBytes('file', pdfBytes, filename: filename),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return _handleResponse(res);
  }

  /// POST /api/ai/fertilizer-calc
  Future<Map<String, dynamic>> fertilizerCalc({
    required double acreage,
    required String cropType,
    required String district,
    required String soilType,
    required String language,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ai/fertilizer-calc'),
      headers: _headers,
      body: jsonEncode({
        'acreage': acreage,
        'crop_type': cropType,
        'district': district,
        'soil_type': soilType,
        'language': language,
      }),
    );
    return _handleResponse(res);
  }

  // ──────────────── Climate Data ────────────────

  /// GET /api/climate/district/:districtId
  Future<Map<String, dynamic>> getDistrictClimate(String districtId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/climate/district/$districtId'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ──────────────── Helpers ────────────────

  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      throw ApiException(
        statusCode: res.statusCode,
        message: body['message'] ?? body['error'] ?? 'Unknown error',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
