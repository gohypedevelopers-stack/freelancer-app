import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';

class SendProposalScreen extends StatefulWidget {
  const SendProposalScreen({super.key});

  @override
  State<SendProposalScreen> createState() => _SendProposalScreenState();
}

class _SendProposalScreenState extends State<SendProposalScreen> {
  final _apiClient = ApiClient();
  
  // State
  bool _isLoading = true;
  int _currentStep = 0; // 0: Select Project, 1: Select Freelancer
  
  List<Map<String, dynamic>> _myProjects = [];
  List<Map<String, dynamic>> _freelancers = [];
  
  // Selection
  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedFreelancer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch Client's Projects (Status: DRAFT or OPEN)
      final projects = await _apiClient.fetchProjects('CLIENT');
      // Filter for valid projects to assign
      final availableProjects = projects.where((p) {
        final status = (p['status'] ?? '').toString().toUpperCase();
        return status == 'OPEN' || status == 'DRAFT';
      }).toList();

      // 2. Fetch Freelancers
      final freelancers = await _apiClient.fetchUsers(role: 'FREELANCER');

      if (mounted) {
        setState(() {
          _myProjects = availableProjects;
          _freelancers = freelancers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }
  
  Future<void> _sendProposal() async {
    if (_selectedProject == null || _selectedFreelancer == null) return;
    
    setState(() => _isSending = true);
    
    try {
      final projectId = _selectedProject!['id'];
      final freelancerId = _selectedFreelancer!['id'];
      // Budget is stored as string in some places, extract digits
      final budgetStr = _selectedProject!['budget']?.toString() ?? '0';
      final budget = int.tryParse(budgetStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      
      await _apiClient.createProposal(
        projectId: projectId,
        freelancerId: freelancerId,
        coverLetter: "I would like to invite you to work on this project.",
        amount: budget,
        status: 'PENDING' // Or RECEIVED, but backend defaults PENDING
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal sent successfully!')),
        );
        
        // Reset or navigate
        setState(() {
           _currentStep = 0;
           _selectedProject = null;
           _selectedFreelancer = null;
           _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hire Freelancer'),
        backgroundColor: theme.cardColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Stepper / Progress
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.cardColor,
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'Select Project', theme),
                    Expanded(child: Divider(color: theme.dividerColor)),
                    _buildStepIndicator(1, 'Select Freelancer', theme),
                  ],
                ),
              ),
              
              Expanded(
                child: _currentStep == 0 
                  ? _buildProjectList(theme) 
                  : _buildFreelancerList(theme),
              ),
              
              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canProceed() 
                          ? (_currentStep == 0 ? () => setState(() => _currentStep++) : (_isSending ? null : _sendProposal))
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSending 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 0 ? 'Next: Pick Freelancer' : 'Send Proposal',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  
  bool _canProceed() {
    if (_currentStep == 0) return _selectedProject != null;
    if (_currentStep == 1) return _selectedFreelancer != null;
    return false;
  }
  
  Widget _buildStepIndicator(int step, String label, ThemeData theme) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isActive ? AppColors.primary : theme.disabledColor,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive 
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('${step + 1}', style: TextStyle(color: theme.disabledColor, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? theme.textTheme.bodyLarge?.color : theme.disabledColor,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectList(ThemeData theme) {
    if (_myProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('No Open/Draft Projects found.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 8),
            const Text('Create a project via Chat first.'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myProjects.length,
      itemBuilder: (context, index) {
        final project = _myProjects[index];
        final isSelected = _selectedProject == project;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedProject = project),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project['title'] ?? 'Untitled',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Budget: ₹${project['budget'] ?? 0}',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project['description'] ?? 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) 
                    Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFreelancerList(ThemeData theme) {
     if (_freelancers.isEmpty) {
      return const Center(child: Text('No Freelancers found.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _freelancers.length,
      itemBuilder: (context, index) {
        final user = _freelancers[index];
        final isSelected = _selectedFreelancer == user;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedFreelancer = user),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                   CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Text((user['fullName'] ?? 'U')[0].toUpperCase()),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['fullName'] ?? 'Unknown Freelancer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: (user['skills'] as List? ?? []).take(3).map<Widget>((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.dividerColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                skill.toString(),
                                style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                   ),
                   if (isSelected) 
                    Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
