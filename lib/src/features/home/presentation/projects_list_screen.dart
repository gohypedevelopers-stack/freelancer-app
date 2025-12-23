import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/home/presentation/project_detail_screen.dart';

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
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08), // Colored shadow
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDetailScreen(project: project),
                                ),
                              ).then((_) => _loadProjects());
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.work_outline, color: AppColors.primary, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              project['title'] ?? 'Untitled',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: theme.textTheme.bodyLarge?.color,
                                                height: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            if (project['description'] != null)
                                              Text(
                                                project['description'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(project['status'] ?? 'ACTIVE'),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Metrics Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("BUDGET", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.disabledColor)),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${project['budget'] ?? 0}',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Vertical Divider
                                      Container(height: 30, width: 1, color: theme.dividerColor),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("PROGRESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.disabledColor)),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${project['progress'] ?? 0}%",
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (project['progress'] != null && (project['progress'] as num) > 0) ...[
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (project['progress'] as num).toDouble() / 100,
                                        backgroundColor: theme.dividerColor.withOpacity(0.3),
                                        color: AppColors.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),
                                  
                                  // Action Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProjectDetailScreen(project: project),
                                          ),
                                        ).then((_) => _loadProjects());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: AppColors.primary.withOpacity(0.4),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Text("Open Project Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;
    
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = Colors.green;
        bg = Colors.green.withOpacity(0.1);
        break;
      case 'IN_PROGRESS':
        color = Colors.blue; // Use AppColors.primary if available, but blue implies progress well
        bg = Colors.blue.withOpacity(0.1);
        break;
      case 'OPEN':
      case 'ACTIVE':
        color = AppColors.primary;
        bg = AppColors.primary.withOpacity(0.1);
        break;
      default:
        color = Colors.grey;
        bg = Colors.grey.withOpacity(0.1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
