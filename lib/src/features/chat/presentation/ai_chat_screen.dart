import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/chat/presentation/proposal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIChatScreen extends StatefulWidget {
  final String serviceTitle;
  final String serviceDescription;

  const AIChatScreen({
    super.key,
    required this.serviceTitle,
    required this.serviceDescription,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiClient = ApiClient();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _conversationId;
  final Set<String> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      // 1. Try to recover existing conversation for this service
      // In a real app, you might store conversation IDs locally per service
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('chat_conversation_${widget.serviceTitle}');

      if (storedId != null) {
        _conversationId = storedId;
        await _loadMessages();
      } else {
        await _startNewConversation();
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      if (_conversationId == null) {
        await _startNewConversation();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startNewConversation() async {
    try {
      final response = await _apiClient.createChatConversation(widget.serviceTitle);
      if (response['id'] != null) {
        _conversationId = response['id'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('chat_conversation_${widget.serviceTitle}', _conversationId!);
        
        // Add initial greeting locally if needed, or wait for server history
        if (_messages.isEmpty) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': 'Hi! I see you\'re interested in ${widget.serviceTitle}. How can I help you with that?'
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error creating conversation: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    try {
      final messages = await _apiClient.fetchChatMessages(_conversationId!);
      if (mounted) {
        setState(() {
          _messages.clear();
          // Sort or ensure order? Usually API returns sorted, but let's be safe if needed
          // Assuming API returns chronological order or reverse.
          // Based on React code, it sorts by createdAt.
          _messages.addAll(messages);
           // If empty managed to fetch but no messages, maybe add greeting
           if (_messages.isEmpty) {
             _messages.add({
              'role': 'assistant',
              'content': 'Hi! I see you\'re interested in ${widget.serviceTitle}. How can I help you with that?'
            });
           }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage([String? content]) async {
    final text = content ?? _inputController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    if (content == null) _inputController.clear();

    // Client-side validation
    final questionKey = _getLastQuestionKey();
    if (questionKey != null && !_validateInput(text, questionKey)) {
      return;
    }

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'createdAt': DateTime.now().toIso8601String(), // Temporary
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _apiClient.sendChatMessage(
        conversationId: _conversationId!,
        content: text,
        service: widget.serviceTitle,
        skipAssistant: false,
      );

      // The API returns the user message (echo) and the assistant response
      // React code logic: "response.data.message" (user) and "response.data.assistant" (bot)
      
      final assistantMsg = response['assistant'] ?? response['data']?['assistant'];
      
      if (mounted && assistantMsg != null) {
        // Sync conversation ID if server changed it or we didn't have the right one
        final newConversationId = assistantMsg['conversationId'];
        if (newConversationId != null && newConversationId != _conversationId) {
           _conversationId = newConversationId;
           final prefs = await SharedPreferences.getInstance();
           await prefs.setString('chat_conversation_${widget.serviceTitle}', _conversationId!);
           debugPrint('Updated local conversation ID to: $_conversationId');
        }

        setState(() {
          _messages.add(assistantMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // Helper to parse suggestions like [SUGGESTIONS: Option 1 | Option 2]
  List<String> _extractSuggestions(String content) {
    // Prioritize Multi-Select if present, effectively hiding suggestions if mixed (rare but possible)
    final regex = RegExp(r'\[SUGGESTIONS:\s*(.*?)\]', caseSensitive: false);
    final match = regex.firstMatch(content);
    if (match != null) {
      return match.group(1)!.split('|').map((s) => s.trim()).toList();
    }
    return [];
  }

  // Helper to parse multi-select like [MULTI_SELECT: Option 1 | Option 2]
  List<String> _extractMultiSelect(String content) {
    final regex = RegExp(r'\[MULTI_SELECT:\s*(.*?)\]', caseSensitive: false);
    final match = regex.firstMatch(content);
    if (match != null) {
      return match.group(1)!.split('|').map((s) => s.trim()).toList();
    }
    return [];
  }

  bool _hasProposal(String content) {
    return content.contains('[PROPOSAL_DATA]');
  }

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'\[SUGGESTIONS:.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[MULTI_SELECT:.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[MAX_SELECT:.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[QUESTION_KEY:.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[PROPOSAL_DATA\][\s\S]*?\[\/PROPOSAL_DATA\]', caseSensitive: false), '') // Remove proposal body
        .trim();
  }

  String? _getLastQuestionKey() {
    if (_messages.isEmpty) return null;
    // Find last assistant message
    for (int i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg['role'] == 'assistant') {
        final content = msg['content'] as String;
        final regex = RegExp(r'\[QUESTION_KEY:\s*(.*?)\]', caseSensitive: false);
        final match = regex.firstMatch(content);
        if (match != null) {
          return match.group(1)?.trim().toLowerCase();
        }
        // If we hit a user message before an assistant message with a key, 
        // it means the last thing the bot said didn't have a key (or we went too far back).
        // But typically the last message IS the assistant question.
        return null; 
      }
    }
    return null;
  }

  bool _validateInput(String text, String key) {
    if (key == 'budget') {
      // Allow "flexible", "skip", or digits
      final lower = text.toLowerCase();
      if (lower.contains('flexible') || lower.contains('skip')) return true;
      
      final hasDigits = RegExp(r'\d').hasMatch(text);
      if (!hasDigits) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid amount (e.g., 50000) or say "Flexible".'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    } else if (key == 'timeline') {
      if (text.length < 3) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid timeline (e.g., 2 weeks).'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    } else if (key == 'name' || key == 'company') {
       if (text.trim().length < 2) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid name.'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.serviceTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('AI Assistant', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: AppColors.card,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reset Logic
              _messages.clear();
              _startNewConversation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = (msg['role'] ?? '').toString().toLowerCase() == 'user';
                final content = msg['content'] ?? '';
                final isLastMessage = index == _messages.length - 1;

                final suggestions = isUser ? <String>[] : _extractSuggestions(content);
                final multiSelectOptions = isUser ? <String>[] : _extractMultiSelect(content);
                final hasProposal = _hasProposal(content);
                
                String cleanText = _cleanContent(content);
                if (hasProposal && cleanText.isEmpty) {
                  cleanText = "I've generated a proposal for you. Click below to view.";
                }

                return Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cleanText,
                            style: TextStyle(
                              color: isUser ? Colors.black : Colors.white, 
                              fontSize: 15,
                            ),
                          ),
                          if (hasProposal) ...[
                             const SizedBox(height: 10),
                             ElevatedButton(
                               onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => ProposalScreen(proposalContent: content),
                                   ),
                                 );
                               },
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: isUser ? Colors.black : AppColors.primary,
                                 foregroundColor: isUser ? Colors.white : Colors.black,
                               ),
                               child: const Text("View Proposal"),
                             )
                          ]
                        ],
                      ),
                    ),
                    
                    // Render Single-Select Suggestions
                    if (suggestions.isNotEmpty && !_isLoading && isLastMessage)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestions.map((suggestion) {
                          return ActionChip(
                            label: Text(suggestion),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            onPressed: () => _sendMessage(suggestion),
                          );
                        }).toList(),
                      ),

                    // Render Multi-Select Options
                    if (multiSelectOptions.isNotEmpty && !_isLoading && isLastMessage)
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: multiSelectOptions.map((option) {
                              final isSelected = _selectedOptions.contains(option);
                              return FilterChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedOptions.add(option);
                                    } else {
                                      _selectedOptions.remove(option);
                                    }
                                  });
                                },
                                backgroundColor: AppColors.card,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontSize: 12
                                ),
                                side: isSelected ? BorderSide.none : const BorderSide(color: Colors.white24),
                                shape: const StadiumBorder(),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedOptions.isNotEmpty)
                            ElevatedButton(
                              onPressed: () {
                                final text = _selectedOptions.join(', ');
                                _sendMessage(text);
                                _selectedOptions.clear(); // Clear after sending
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text("Done", style: TextStyle(color: Colors.black)),
                            ),
                         ],
                       ),
                    
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: () => _sendMessage(),
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
