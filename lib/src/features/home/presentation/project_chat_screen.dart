import 'dart:async';
import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';

class ProjectChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final String serviceKey;

  const ProjectChatScreen({
    super.key, 
    required this.conversationId, 
    required this.title,
    required this.serviceKey,
  });

  @override
  State<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
  final _apiClient = ApiClient();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadMessages();
    // Poll for new messages every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }
  
  Future<void> _loadUser() async {
    try {
      final user = await _apiClient.getUser();
      if (mounted) setState(() => _currentUserId = user.id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final messages = await _apiClient.fetchChatMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        if (!silent) _scrollToBottom();
      }
    } catch (e) {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    // Optimistic update
    final tempMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'role': 'user',
      'content': text,
      'createdAt': DateTime.now().toIso8601String(),
      'senderId': _currentUserId,
    };
    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      await _apiClient.sendChatMessage(
        conversationId: widget.conversationId,
        content: text,
        service: widget.serviceKey, // Required by backend
        senderId: _currentUserId,
        skipAssistant: true, // P2P chat
      );
      _loadMessages(silent: true); // Refresh to get real message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
      );
      setState(() {
        _messages.remove(tempMsg);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18)),
        backgroundColor: theme.cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(child: Text("No messages yet. Start the conversation!", style: TextStyle(color: theme.textTheme.bodyMedium?.color)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == _currentUserId || msg['role'] == 'user'; // Fallback logic
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : theme.cardColor,
                                borderRadius: BorderRadius.circular(20).copyWith(
                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                                  bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                                ),
                                border: isMe ? null : Border.all(color: theme.dividerColor),
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.cardColor,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
