import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:trunk_ops_app/models/coverage_models.dart';

class CoverageApiService {
  /// Базовий URL бекенду.
  /// Якщо не передати вручну, вибираємо автоматично:
  /// - Android емулятор → 10.0.2.2
  /// - все інше → 127.0.0.1
  final String baseUrl;

  CoverageApiService({String? baseUrl})
    : baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    if (Platform.isAndroid) {
      // Android emulator → доступ до localhost хоста
      return 'http://10.0.2.2:8000';
    } else {
      // Desktop / iOS simulator / web (через проксі) → ваш локальний бек
      return 'http://127.0.0.1:8000';
    }
  }

  Future<CoverageResponse> calculateCoverage(CoverageRequest req) async {
    final url = Uri.parse('$baseUrl/coverage/calc');

    final resp = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );

    if (resp.statusCode != 200) {
      throw Exception('Помилка API (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return CoverageResponse.fromJson(data);
  }
}
