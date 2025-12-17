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

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    if (role == 'CLIENT') {
      // Clients: fetch projects to calculate metrics
      final response = await http.get(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final List projects = body['data'] ?? [];
        
        final active = projects.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'OPEN').length;
        final completed = projects.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length;
        int proposalsSent = 0;
        int totalSpend = 0;
        
        for (var project in projects) {
          final proposals = project['proposals'] as List? ?? [];
          proposalsSent += proposals.length;
          final hasAccepted = proposals.any((pr) => (pr['status'] ?? '').toString().toUpperCase() == 'ACCEPTED');
          if (hasAccepted) {
            totalSpend += (int.tryParse(project['budget']?.toString() ?? '0') ?? 0);
          }
        }
        
        return {
          'active_projects': active.toString(),
          'completed_projects': completed.toString(),
          'proposals_sent': proposalsSent.toString(),
          'total_spend': '₹${totalSpend.toString()}',
        };
      }
    } else {
      // Freelancers: fetch proposals to calculate metrics
      final response = await http.get(
        Uri.parse('$baseUrl/proposals?as=freelancer'),
        headers: headers,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final List proposals = body['data'] ?? [];
        
        final pending = proposals.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING').length;
        final accepted = proposals.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'ACCEPTED').length;
        int earnings = 0;
        
        for (var proposal in proposals) {
          if ((proposal['status'] ?? '').toString().toUpperCase() == 'ACCEPTED') {
            earnings += (int.tryParse(proposal['amount']?.toString() ?? '0') ?? 0);
          }
        }
        
        return {
          'active_projects': accepted.toString(),
          'proposals_received': pending.toString(),
          'accepted_proposals': accepted.toString(),
          'total_earnings': '₹${earnings.toString()}',
        };
      }
    }
    
    // Fallback if API call fails
    return {
      'active_projects': '0',
      'completed_projects': '0',
      'proposals_sent': '0',
      'total_spend': '₹0',
    };
  }

  /// Fetch projects for the current user
  /// - Clients: All their created projects
  /// - Freelancers: Projects where their proposal was accepted
  Future<List<Map<String, dynamic>>> fetchProjects(String role) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    if (role == 'FREELANCER') {
      // Freelancers: Get accepted proposals and extract project info
      final response = await http.get(
        Uri.parse('$baseUrl/proposals'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final List proposals = body['data'] ?? body ?? [];
        
        // Filter accepted proposals and extract project data
        List<Map<String, dynamic>> acceptedProjects = [];
        for (var p in proposals) {
          if ((p['status'] ?? '').toString().toUpperCase() == 'ACCEPTED') {
            final project = p['project'] as Map<String, dynamic>? ?? {};
            acceptedProjects.add({
              'id': project['id'] ?? p['projectId'],
              'title': project['title'] ?? 'Assigned Project',
              'budget': p['amount'] ?? project['budget'] ?? 0,
              'status': project['status'] ?? 'ACTIVE',
              'deadline': project['deadline'] ?? '',
            });
          }
        }
        
        return acceptedProjects;
      }
      return [];
    } else {
      // Clients: Get their created projects
      final response = await http.get(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final List data = body['data'] ?? body ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    }
  }

  /// Fetch proposals (activity) for the current user
  Future<List<Map<String, dynamic>>> fetchProposals() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/proposals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      final List data = body['data'] ?? body ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetch profile stats (projects count, proposals count, etc.)
  Future<Map<String, dynamic>> fetchProfileStats(String role) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    int projectsCount = 0;
    int completedCount = 0;
    int proposalsCount = 0;

    try {
      // Fetch projects
      final projectsResponse = await http.get(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
      );
      
      if (projectsResponse.statusCode >= 200 && projectsResponse.statusCode < 300) {
        final body = jsonDecode(projectsResponse.body);
        final List projects = body['data'] ?? body ?? [];
        projectsCount = projects.length;
        completedCount = projects.where((p) => 
          (p['status'] ?? '').toString().toUpperCase() == 'COMPLETED'
        ).length;
      }

      // Fetch proposals
      final proposalsResponse = await http.get(
        Uri.parse('$baseUrl/proposals'),
        headers: headers,
      );
      
      if (proposalsResponse.statusCode >= 200 && proposalsResponse.statusCode < 300) {
        final body = jsonDecode(proposalsResponse.body);
        final List proposals = body['data'] ?? body ?? [];
        proposalsCount = proposals.length;
      }
    } catch (e) {
      // Silently fail, return zeros
    }

    return {
      'projects': projectsCount.toString(),
      'completed': completedCount.toString(),
      'proposals': proposalsCount.toString(),
    };
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
