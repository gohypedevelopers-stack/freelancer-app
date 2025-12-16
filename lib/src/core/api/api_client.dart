import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Production URL
  static const String baseUrl = 'https://freelancer-er4u.vercel.app/api'; 
  
  static const String _tokenKey = 'freelancer.accessToken';
  static const String _userKey = 'freelancer.user';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    String role = 'FREELANCER', // Default to Freelancer for now, or make selectable
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUser() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> fetchMetrics(String role) async {
    final token = await _getToken();
     if (token == null) throw Exception('No token found');
     
    // Mocking metrics response for now as endpoints might differ
    // React app calls /projects or /proposals based on role
    // For MVP, we'll return a basic structure to display UI
    
    // In a real app, you'd match the React logic: 
    // Client: GET /projects
    // Freelancer: GET /proposals?as=freelancer
    
    await Future.delayed(const Duration(milliseconds: 500)); // Sim network

    if (role == 'CLIENT') {
        return {
            'active_projects': '3',
            'completed_projects': '12',
            'proposals_sent': '5',
            'total_spend': '₹45,000',
        };
    } else {
         return {
            'active_projects': '2',
            'proposals_received': '8',
            'accepted_proposals': '4',
            'total_earnings': '₹24,000',
        };
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      final data = body['data'] ?? body; // Adjust based on API structure
      
      if (data != null && data['accessToken'] != null) {
        await _persistSession(data['accessToken'], data['user']);
      }
      return data;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['error'] ?? 'Request failed');
    }
  }

  Future<void> _persistSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }
}
