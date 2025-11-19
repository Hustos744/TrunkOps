import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset.dart';
import '../models/audit_log.dart';
import '../models/coverage_zone.dart';
import '../models/device_model.dart';
import '../models/maintenance_task.dart';
import '../models/network_node.dart';
import '../models/notification.dart';
import '../models/unit.dart';
import '../models/user_settings.dart';
import 'coverage_api_service.dart';

/// A simple service for interacting with the FastAPI backend.
///
/// This class provides methods for authentication and fetching domain data.
class ApiService {
  ApiService();

  /// The base URL of the backend.  Update this to point at your deployment.
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Perform user authentication.  Returns the access token on success.
  Future<String?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {
        // важливо: form-url-encoded, не JSON
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        // важливо: без jsonEncode, просто мапа
        'username': username,
        'password': password,
        // 'scope': '', // можна додати при бажанні
      },
    );

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return token;
      }
    }

    // Можеш для дебага кинути ексепшн, щоб бачити помилку в UI
    return null;
  }

  /// Log out the current user by removing the stored token.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Retrieve the stored access token from preferences.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetch all units from the backend.
  Future<List<Unit>> getUnits() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No auth token');
    }
    final url = Uri.parse('$baseUrl/units');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Unit.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch units: ${response.statusCode}');
  }

  /// Fetch all unit types.
  Future<List<String>> getUnitTypes() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/units/types');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e['name']?.toString() ?? '').toList();
    }
    throw Exception('Failed to fetch unit types: ${response.statusCode}');
  }

  /// Fetch all device models.
  Future<List<DeviceModel>> getDeviceModels() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/device-models');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch device models: ${response.statusCode}');
  }

  /// Fetch all network nodes.
  Future<List<NetworkNode>> getNetworkNodes() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/nodes');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => NetworkNode.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch network nodes: ${response.statusCode}');
  }

  /// Fetch coverage zones for a given node.
  Future<List<CoverageZone>> getCoverageZones(int nodeId) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/nodes/$nodeId/coverage');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => CoverageZone.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'Failed to fetch coverage zones for node $nodeId: ${response.statusCode}',
    );
  }

  /// Fetch all asset types.
  Future<List<String>> getAssetTypes() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/assets/types');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e['name']?.toString() ?? '').toList();
    }
    throw Exception('Failed to fetch asset types: ${response.statusCode}');
  }

  /// Fetch all assets.
  Future<List<Asset>> getAssets() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/assets');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Asset.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch assets: ${response.statusCode}');
  }

  /// Fetch all maintenance tasks.
  Future<List<MaintenanceTask>> getMaintenanceTasks() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/maintenance');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'Failed to fetch maintenance tasks: ${response.statusCode}',
    );
  }

  /// Fetch all audit logs.
  Future<List<AuditLogEntry>> getAuditLogs() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/audit');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch audit logs: ${response.statusCode}');
  }

  /// Fetch all notifications.
  Future<List<AppNotification>> getNotifications() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/notifications');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch notifications: ${response.statusCode}');
  }

  /// Fetch user settings for the current user.
  Future<UserSettings?> getUserSettings() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/settings');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserSettings.fromJson(data);
    }
    throw Exception('Failed to fetch settings: ${response.statusCode}');
  }

  /// Update user settings.
  Future<UserSettings?> updateUserSettings(UserSettings settings) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final url = Uri.parse('$baseUrl/settings');
    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(settings.toJson()),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserSettings.fromJson(data);
    }
    throw Exception('Failed to update settings: ${response.statusCode}');
  }
}

final coverageApi = CoverageApiService();
