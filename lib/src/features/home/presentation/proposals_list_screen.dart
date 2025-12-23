import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/home/presentation/proposal_detail_screen.dart';

class ProposalsListScreen extends StatefulWidget {
  const ProposalsListScreen({super.key});

  @override
  State<ProposalsListScreen> createState() => _ProposalsListScreenState();
}

class _ProposalsListScreenState extends State<ProposalsListScreen> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _proposals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  Future<void> _loadProposals() async {
    try {
      final proposals = await _apiClient.fetchProposals();
      setState(() {
        _proposals = proposals;
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
        title: Text('My Proposals', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: theme.cardColor,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _proposals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(height: 16),
                      Text('No proposals sent yet', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProposals,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _proposals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final proposal = _proposals[index];
                      final status = (proposal['status'] ?? 'PENDING').toString().toUpperCase();
                      final projectTitle = proposal['project']?['title'] ?? proposal['projectId'] ?? 'Project';
                      final amount = proposal['amount'] ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          // Subtle gradient for premium feel
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.cardColor,
                              theme.cardColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
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
                                  builder: (context) => ProposalDetailScreen(proposal: proposal),
                                ),
                              ).then((_) => _loadProposals());
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Date and Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, size: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(proposal['createdAt']),
                                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Title
                                  Text(
                                    projectTitle,
                                    style: TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold, 
                                      color: theme.textTheme.bodyLarge?.color,
                                      height: 1.2,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Bid Amount (Compact badge)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("BID:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.disabledColor)),
                                        const SizedBox(width: 6),
                                        Text(
                                          "₹$amount",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  // Cover Letter Snippet
                                  if (proposal['coverLetter'] != null)
                                    Text(
                                      proposal['coverLetter'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                    ),
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
    
    switch (status) {
      case 'ACCEPTED':
        color = Colors.green;
        bg = Colors.green.withOpacity(0.2);
        break;
      case 'REJECTED':
        color = Colors.red;
        bg = Colors.red.withOpacity(0.2);
        break;
      case 'PENDING':
      default:
        color = Colors.orange;
        bg = Colors.orange.withOpacity(0.2);
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return '';
    }
  }
}
