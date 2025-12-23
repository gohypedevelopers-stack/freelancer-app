import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:freelancer_flutter/src/features/auth/domain/user_model.dart';

class ApiClient {
  // Production URL
  static const String baseUrl = 'https://catalance-backend.vercel.app/api'; 
  // Local Android Emulator URL
  // static const String baseUrl = 'http://10.0.2.2:5000/api'; 
  
  static const String _tokenKey = 'freelancer.accessToken';
  static const String _userKey = 'freelancer.user';

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = await _handleResponse(response);
    return UserModel.fromJson(data['user'] ?? data);
  }

  Future<UserModel> signup({
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

    final data = await _handleResponse(response);
    return UserModel.fromJson(data['user'] ?? data);
  }

  Future<UserModel> getUser() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = await _handleResponse(response);
    return UserModel.fromJson(data['user'] ?? data);
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
        
        final active = projects.where((p) {
          final status = (p['status'] ?? '').toString().toUpperCase();
          return status != 'COMPLETED' && status != 'CLOSED';
        }).length;
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

  /// Get a single project by ID
  Future<Map<String, dynamic>> getProject(String projectId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }
  
  /// Create a new project
  Future<Map<String, dynamic>> createProject({
    required String title,
    required String description,
    required String budget,
    String status = 'DRAFT',
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    // Simple logging for terminal visibility as requested
    print('Creating Project: $title, Budget: $budget');

    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'budget': budget,
        'status': status,
      }),
    );
    
    print('Create Project Response: ${response.statusCode} ${response.body}');

    return _handleResponse(response);
  }

  /// Update an existing project (e.g. progress, tasks)
  Future<Map<String, dynamic>> updateProject(String projectId, Map<String, dynamic> updates) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    print('Updating Project $projectId: $updates');

    final response = await http.patch(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    print('Update Project Response: ${response.statusCode} ${response.body}');
    return _handleResponse(response);
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
              'progress': project['progress'] ?? 0,
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

  /// Create a proposal (or invite from client to freelancer)
  Future<Map<String, dynamic>> createProposal({
    required String projectId,
    required String freelancerId,
    required String coverLetter,
    required int amount,
    String status = 'PENDING',
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    print('Creating Proposal: Project=$projectId, Freelancer=$freelancerId, Amount=$amount');

    final response = await http.post(
      Uri.parse('$baseUrl/proposals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'projectId': projectId,
        'freelancerId': freelancerId,
        'coverLetter': coverLetter,
        'amount': amount,
        'status': status,
      }),
    );

    print('Create Proposal Response: ${response.statusCode} ${response.body}');
    return _handleResponse(response);
  }

  /// Update proposal status (e.g. ACCEPTED, REJECTED)
  Future<Map<String, dynamic>> updateProposalStatus(String proposalId, String status) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    print('Updating Proposal Status: $proposalId -> $status');

    final response = await http.patch(
      Uri.parse('$baseUrl/proposals/$proposalId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    print('Update Proposal Response: ${response.statusCode} ${response.body}');
    return _handleResponse(response);
  }

  /// Fetch users (e.g. to list freelancers)
  Future<List<Map<String, dynamic>>> fetchUsers({String? role}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    String url = '$baseUrl/users';
    if (role != null) url += '?role=$role';

    final response = await http.get(
      Uri.parse(url),
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
      'proposals': proposalsCount.toString(),
    };
  }

  // --- CHAT METHODS ---

  /// Create a new chat conversation
  Future<Map<String, dynamic>> createChatConversation(String service) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: headers,
      body: jsonEncode({
        'service': service,
        'mode': 'assistant',
        // 'ephemeral': true // Optional: replicate React logic if needed
      }),
    );

    return _handleResponse(response);
  }

  /// Send a message to the chat
  Future<Map<String, dynamic>> sendChatMessage({
    required String conversationId,
    required String content,
    required String service,
    String? senderId,
    String? senderRole,
    String? senderName,
    bool skipAssistant = false, // Defaults to false usually, but React client defaults true in one function? No, false in usage.
    // React client 'sendChatMessage' defaults skipAssistant=true but 'handleSend' passes false.
    // We should probably default to false if we want AI response.
  }) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Log for terminal visibility
    print('Sending Chat Message: $content');

    final response = await http.post(
      Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
      headers: headers,
      body: jsonEncode({
        'content': content,
        'service': service,
        'senderId': senderId,
        'senderRole': senderRole,
        'senderName': senderName,
        'skipAssistant': skipAssistant,
      }),
    );

    return _handleResponse(response);
  }

  /// Fetch messages for a conversation
  Future<List<Map<String, dynamic>>> fetchChatMessages(String conversationId) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      final List messages = body['data']?['messages'] ?? body['messages'] ?? []; // Adjust based on API return
      return messages.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    // Log for terminal visibility
    print('API Request: ${response.request?.method} ${response.request?.url}');
    print('API Response: ${response.statusCode}');
    print('API Response Body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      final data = body['data'] ?? body; // Adjust based on API structure
      
      if (data != null) {
        // Persist token if present
        if (data['accessToken'] != null) {
             final userMap = data['user'];
             if (userMap != null) {
                // If we have a user object, we can persist it to keep session up to date
                // We don't strictly *need* to parse it here, but we can to save it.
                // However, avoid returning it as the main result if the caller expects Map.
                final user = UserModel.fromJson(userMap);
                await _persistSession(data['accessToken'], user);
             }
        }
      }
      return data is Map<String, dynamic> ? data : {'data': data};
    } else {
      print('API Error Body: ${response.body}');
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['error'] ?? 'Request failed');
    }
  }

  Future<void> _persistSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
