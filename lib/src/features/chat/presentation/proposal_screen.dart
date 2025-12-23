import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/auth/presentation/auth_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProposalScreen extends StatefulWidget {
  final String proposalContent;

  const ProposalScreen({
    super.key,
    required this.proposalContent,
  });

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  late TextEditingController _controller;
  bool _isEditing = false;
  late String _currentContent;
  final _apiClient = ApiClient();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentContent = _cleanContent(widget.proposalContent);
    _controller = TextEditingController(text: _currentContent);
  }

  String _cleanContent(String content) {
    // Remove the [PROPOSAL_DATA] tags
    return content
        .replaceAll('[PROPOSAL_DATA]', '')
        .replaceAll('[/PROPOSAL_DATA]', '')
        .trim();
  }
  
  // Helper to extract value by key (e.g. "Project Title: Website")
  String _extractValue(String text, String key) {
    final regex = RegExp('$key:\\s*(.*)', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  Future<void> _acceptProposal() async {
    // 1. Check if user is logged in
    final hasToken = await _apiClient.hasToken();
    if (!hasToken) {
      // Save state before redirecting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_proposal', _isEditing ? _controller.text : _currentContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to accept the proposal. Your draft will be saved.')),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    
    // Parse the content
    final text = _isEditing ? _controller.text : _currentContent;
    
    String title = _extractValue(text, 'Project Title');
    if (title.isEmpty) title = _extractValue(text, 'Service');
    if (title.isEmpty) title = 'New Project';
    
    String budget = _extractValue(text, 'Budget');
    if (budget.isEmpty) budget = _extractValue(text, 'Estimated Price');
    
    // Sanitize budget (remove currency symbols, commas, etc.)
    budget = budget.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Use the whole text as description/summary
    String description = text;

    try {
      await _apiClient.createProject(
        title: title, 
        description: description, 
        budget: budget,
        status: 'OPEN', // Set key status to OPEN so it shows up
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal Accepted! Project created.')),
        );
        // Navigate to Profile/Dashboard (pop until home then switch tab if needed, or just pop)
        // Ideally we want to go back to the Home Screen -> Profile Tab.
        // For now, let's pop to root.
         Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save project: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Project Proposal'),
        backgroundColor: AppColors.card,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _currentContent = _controller.text;
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        height: 1.5,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _currentContent,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          height: 1.5,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _acceptProposal,
                    child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                      'Accept Proposal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
