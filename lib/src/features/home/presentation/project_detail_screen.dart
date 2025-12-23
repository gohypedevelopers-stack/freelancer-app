import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/home/data/project_phases_data.dart';
import 'package:freelancer_flutter/src/features/home/presentation/project_chat_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late Map<String, dynamic> _project;
  bool _isLoading = false;
  List<String> _completedTaskIds = [];
  String? _currentUserId;
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _tabController = TabController(length: 4, vsync: this);
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    try {
      final userModel = await _apiClient.getUser();
      // Fetch fresh project data to ensure sync with web/backend
      final freshProject = await _apiClient.getProject(widget.project['id']);
      
      setState(() {
        _currentUserId = userModel.id;
        // Merge fresh data
        _project = {..._project, ...freshProject}; 
        
        _notesController.text = _project['notes'] ?? ''; 

        
        // Parse completed tasks from JSON string or List
        final completedTasksRaw = _project['completedTasks'];
        if (completedTasksRaw is String) {
          try {
             _completedTaskIds = List<String>.from(jsonDecode(completedTasksRaw));
          } catch (_) {
             _completedTaskIds = [];
          }
        } else if (completedTasksRaw is List) {
          _completedTaskIds = List<String>.from(completedTasksRaw);
        } else {
          _completedTaskIds = [];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotes() async {
    try {
      FocusScope.of(context).unfocus();
      await _apiClient.updateProject(_project['id'], {
        'notes': _notesController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved successfully')));
      _project['notes'] = _notesController.text;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save notes: $e')));
    }
  }

  Future<void> _toggleTask(String taskId, bool? value) async {
    if (value == null) return;

    // 1. Optimistic Update Local State
    setState(() {
      if (value) {
        if (!_completedTaskIds.contains(taskId)) {
          _completedTaskIds.add(taskId);
        }
      } else {
        _completedTaskIds.remove(taskId);
      }
      
      // Update the main map so other tabs (Dashboard) see changes immediately
      _project['completedTasks'] = _completedTaskIds;
      
      // Calculate new progress
      final totalTasks = kProjectPhases.fold<int>(0, (sum, phase) => sum + phase.tasks.length);
      final completionPercentage = (totalTasks > 0) ? (_completedTaskIds.length / totalTasks * 100) : 0.0;
      _project['progress'] = completionPercentage.round();
    });

    try {
      // 2. Persist to Backend
      // Convert list to JSON string/list as expected by backend.
      // Assuming backend handles List<String> or JSON string.
      // Based on previous code, it seems to accept list directly.
      
      await _apiClient.updateProject(_project['id'], {
        'completedTasks': _completedTaskIds, 
        'progress': _project['progress'],
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress saved: ${_project['progress']}%'), 
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          )
        );
      }
    } catch (e) {
      // 3. Revert on Failure
      setState(() {
        if (value) {
          _completedTaskIds.remove(taskId);
        } else {
          _completedTaskIds.add(taskId);
        }
        _project['completedTasks'] = _completedTaskIds;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    }
  }
  
  String get _serviceKey {
    final ownerId = _project['ownerId'] ?? '';
    // Service Key Format: CHAT:PROJECT_ID:CLIENT_ID:FREELANCER_ID
    // If I am freelancer, I use my ID. If client, I need freelancer's.
    // For this specific requested flow (Freelancer View), we can use current ID + Owner.
    return 'CHAT:${_project['id']}:$ownerId:$_currentUserId'; 
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_project['title'] ?? 'Project Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Dashboard"),
            Tab(text: "Tasks"),
            Tab(text: "Chat"),
            Tab(text: "Documents"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(theme),
          _buildTasksTab(theme),
          _buildChatTab(theme),
          _buildDocumentsTab(theme),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ThemeData theme) {
    final totalBudget = _project['budget'] ?? 0;
    final progress = _project['progress'] ?? 0;
    // Mock spent calculation based on progress
    final spent = (totalBudget * ((progress is int ? progress : double.tryParse(progress.toString()) ?? 0) / 100)).round(); 
    final remaining = totalBudget - spent;
    
    final completedPhases = kProjectPhases.where((p) => p.tasks.every((t) => _completedTaskIds.contains(t.id))).length;
    final progressDouble = (progress is int ? progress.toDouble() : (double.tryParse(progress.toString()) ?? 0.0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Overall Progress", theme),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                  blurRadius: 4,
                )
              ],
            ),
            child: Column(
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     // Force integer display
                     Text("${(_project['progress'] ?? 0).toInt()}%", 
                       style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)
                     ),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text("$completedPhases/${kProjectPhases.length}", style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                         Text("phases completed", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                       ],
                     ),
                   ],
                 ),
                 const SizedBox(height: 10),
                 ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((_project['progress'] ?? 0).toInt() / 100).clamp(0.0, 1.0), 
                      backgroundColor: theme.dividerColor, 
                      color: AppColors.primary, 
                      minHeight: 12
                    ),
                 ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader("Budget Summary", theme),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildBudgetCard("Total Budget", "₹$totalBudget", Colors.blue, theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildBudgetCard("Spent", "₹$spent", Colors.orange, theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildBudgetCard("Remaining", "₹$remaining", Colors.green, theme)),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("Project Phases", theme),
          const SizedBox(height: 10),
          ...kProjectPhases.map((phase) {
             final phaseTasks = phase.tasks;
             final completedCount = phaseTasks.where((t) => _completedTaskIds.contains(t.id)).length;
             final percent = phaseTasks.isNotEmpty ? (completedCount / phaseTasks.length) * 100 : 0;
             final isDone = completedCount == phaseTasks.length;
             
             return Card(
               margin: const EdgeInsets.only(bottom: 12),
               elevation: 0,
               color: theme.cardColor,
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(10),
                 side: BorderSide(color: theme.dividerColor),
               ),
               child: ListTile(
                 title: Text(phase.title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                 subtitle: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(phase.description, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                     const SizedBox(height: 4),
                     Text("${percent.round()}% complete", style: TextStyle(fontSize: 12, color: isDone ? Colors.green : Colors.orange)),
                   ],
                 ),
                 trailing: isDone ? const Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.circle_outlined, color: theme.disabledColor),
               ),
             );
          }).toList(),

          const SizedBox(height: 24),
          _buildSectionHeader("Project Notes", theme),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                  blurRadius: 4,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Add your personal notes for this project here...",
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const Divider(),
                TextButton.icon(
                  onPressed: _updateNotes,
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text("Save Notes"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildBudgetCard(String label, String amount, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTasksTab(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: kProjectPhases.length,
      itemBuilder: (context, index) {
        final phase = kProjectPhases[index];
        final completedCount = phase.tasks.where((t) => _completedTaskIds.contains(t.id)).length;
        
        return ExpansionTile(
          collapsedIconColor: theme.iconTheme.color,
          iconColor: AppColors.primary,
          title: Text(phase.title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          subtitle: Text("$completedCount of ${phase.tasks.length} tasks completed", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
          initiallyExpanded: index == 0,
          children: phase.tasks.map((task) {
            final isChecked = _completedTaskIds.contains(task.id);
            return CheckboxListTile(
              title: Text(task.title, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              value: isChecked,
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              onChanged: (val) => _toggleTask(task.id, val),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChatTab(ThemeData theme) {
    // If we don't have conversation ID yet, fetch it.
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiClient.createChatConversation(_serviceKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
           return Center(child: Text("Chat unavailable. ${_currentUserId == null ? 'Loading user...' : ''}", style: TextStyle(color: theme.textTheme.bodyMedium?.color)));
        }
        final conversation = snapshot.data!;
        return ProjectChatScreen(
          conversationId: conversation['id'],
          title: _project['title'] ?? 'Chat',
          serviceKey: _serviceKey,
        );
      },
    );
  }

  Widget _buildDocumentsTab(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text("No documents attached yet.", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Documentation"),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color));
  }
}
