import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';

class ProjectsListScreen extends StatefulWidget {
  final String title;
  final String statusFilter; // 'ACTIVE', 'COMPLETED', etc.
  final bool isFreelancer;

  const ProjectsListScreen({
    super.key, 
    required this.title, 
    required this.statusFilter,
    required this.isFreelancer,
  });

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final role = widget.isFreelancer ? 'FREELANCER' : 'CLIENT';
      final allProjects = await _apiClient.fetchProjects(role);
      
      setState(() {
        _projects = allProjects.where((p) {
          final status = (p['status'] ?? '').toString().toUpperCase();
          // Simple filtering logic
          if (widget.statusFilter == 'ALL') return true;
          if (widget.statusFilter == 'COMPLETED') return status == 'COMPLETED';
          if (widget.statusFilter == 'ACTIVE') return status != 'COMPLETED' && status != 'CLOSED';
          return true;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: theme.cardColor,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _projects.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off, size: 64, color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(height: 16),
                      Text('No ${widget.title.toLowerCase()} found', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    project['title'] ?? 'Untitled',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    project['status'] ?? 'Active',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Budget: ₹${project['budget'] ?? 0}',
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
