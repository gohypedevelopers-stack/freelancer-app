import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/auth/presentation/auth_selection_screen.dart';
import 'package:freelancer_flutter/src/features/home/domain/service_model.dart';
import 'package:freelancer_flutter/src/features/home/presentation/earnings_screen.dart';
import 'package:freelancer_flutter/src/features/home/presentation/widgets/category_chip.dart';
import 'package:freelancer_flutter/src/features/home/presentation/widgets/premium_service_card.dart';
import 'package:freelancer_flutter/src/core/presentation/widgets/fade_slide_transition.dart';
import 'package:freelancer_flutter/src/features/home/presentation/projects_list_screen.dart';
import 'package:freelancer_flutter/src/features/home/presentation/proposals_list_screen.dart';
import 'package:freelancer_flutter/src/features/home/presentation/widgets/service_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiClient = ApiClient();
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _metrics;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _proposals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _apiClient.getUser();
      final role = user['role']?.toString().toUpperCase() ?? 'CLIENT';
      final metrics = await _apiClient.fetchMetrics(role);
      final projects = await _apiClient.fetchProjects(role);
      final proposals = await _apiClient.fetchProposals();
      
      if (mounted) {
        setState(() {
          _user = user;
          _metrics = metrics;
          _projects = projects;
          _proposals = proposals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final role = _user?['role']?.toString().toUpperCase() ?? 'CLIENT';
    final name = _user?['fullName'] ?? 'User';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header
              FadeSlideTransition(
                index: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to Profile
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              FadeSlideTransition(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                       BoxShadow(
                        color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search projects, services...',
                      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.tune, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Promo Banner
              const FadeSlideTransition(index: 2, child: _PromoBanner()),
              const SizedBox(height: 24),

              // Categories Scroll
              FadeSlideTransition(
                index: 3,
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    children: allServices.map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: _getShortIconLabel(service.title),
                          icon: service.icon,
                          onTap: () {},
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Metrics Grid
              FadeSlideTransition(
                index: 4,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: _buildMetrics(role),
                ),
              ),
              const SizedBox(height: 32),
              
              // Development Services (Horizontal Scroll)
              FadeSlideTransition(
                index: 5,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Development', style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color, 
                          fontWeight: FontWeight.w700, 
                          fontSize: 18,
                          letterSpacing: -0.5,
                        )),
                        TextButton(
                          onPressed: () {}, 
                          child: const Text('See All', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _getDevelopmentServices().length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                           return PremiumServiceCard(service: _getDevelopmentServices()[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // My Projects Section
              FadeSlideTransition(
                index: 6,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Projects', style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color, 
                          fontWeight: FontWeight.w700, 
                          fontSize: 18,
                          letterSpacing: -0.5,
                        )),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_projects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.folder_open, color: theme.textTheme.bodyMedium?.color, size: 40),
                              const SizedBox(height: 8),
                              Text('No projects yet', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _projects.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return _ProjectCard(project: project);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Recent Activity Section
              FadeSlideTransition(
                index: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color, 
                      fontWeight: FontWeight.w700, 
                      fontSize: 18,
                      letterSpacing: -0.5,
                    )),
                    const SizedBox(height: 12),
                    if (_proposals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.notifications_none, color: theme.textTheme.bodyMedium?.color, size: 40),
                              const SizedBox(height: 8),
                              Text('No recent activity', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _proposals.take(5).length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final proposal = _proposals[index];
                          return _ActivityItem(proposal: proposal);
                        },
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
        ),
      ),
      ),
    );
  }

  List<Widget> _buildMetrics(String role) {
    if (_metrics == null) return [];

    if (role == 'CLIENT') {
      return [
        _MetricCard(
          label: 'Active Projects',
          value: _metrics!['active_projects'],
          icon: Icons.work_outline,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectsListScreen(
                title: 'Active Projects',
                statusFilter: 'ACTIVE',
                isFreelancer: false,
              ),
            ),
          ),
        ),
        _MetricCard(
          label: 'Completed',
          value: _metrics!['completed_projects'],
          icon: Icons.check_circle_outline,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectsListScreen(
                title: 'Completed Projects',
                statusFilter: 'COMPLETED',
                isFreelancer: false,
              ),
            ),
          ),
        ),
        _MetricCard(
          label: 'Proposals',
          value: _metrics!['proposals_sent'],
          icon: Icons.send_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProposalsListScreen()),
          ),
        ),
        _MetricCard(
          label: 'Total Spend',
          value: _metrics!['total_spend'],
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EarningsScreen(isFreelancer: false)),
          ),
        ),
      ];
    } else {
      return [
        _MetricCard(
          label: 'Active Projects',
          value: _metrics!['active_projects'],
          icon: Icons.work_outline,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectsListScreen(
                title: 'Active Projects',
                statusFilter: 'ACTIVE',
                isFreelancer: true,
              ),
            ),
          ),
        ),
        _MetricCard(
          label: 'Proposals',
          value: _metrics!['proposals_received'],
          icon: Icons.mark_email_unread_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProposalsListScreen()),
          ),
        ),
        _MetricCard(
          label: 'Accepted',
          value: _metrics!['accepted_proposals'],
          icon: Icons.thumb_up_alt_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectsListScreen(
                title: 'Accepted Projects',
                statusFilter: 'ALL',
                isFreelancer: true,
              ),
            ),
          ),
        ),
        _MetricCard(
          label: 'Earnings',
          value: '${_metrics!['total_earnings'] ?? '0'}',
          icon: Icons.currency_rupee,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EarningsScreen(isFreelancer: true)),
          ),
        ),
      ];
    }
  }

  List<Service> _getDevelopmentServices() {
    return allServices.filter((s) => s.title.toLowerCase().contains('development')).toList();
  }

  List<Service> _getMajorServices() {
    // Return services that are NOT development, limited to first 3 for "Major" section
    return allServices.filter((s) => !s.title.toLowerCase().contains('development')).take(3).toList();
  }


  String _getShortIconLabel(String title) {
    if (title.contains('Website')) return 'Web';
    if (title.contains('App')) return 'App';
    if (title.contains('Software')) return 'Software';
    if (title.contains('Lead')) return 'Leads';
    if (title.contains('Video')) return 'Video';
    if (title.contains('SEO')) return 'SEO';
    if (title.contains('Social')) return 'Social';
    if (title.contains('Performance')) return 'Ads';
    if (title.contains('Creative')) return 'UI/UX'; 
    if (title.contains('Writing')) return 'Content';
    if (title.contains('Support')) return 'Support';
    if (title.contains('Audio')) return 'Audio';
    return title.split(' ')[0];
  }
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);


}


class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label, 
    required this.value, 
    required this.icon,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [theme.cardColor, theme.cardColor.withOpacity(0.8)] 
              : [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final title = project['title'] ?? 'Untitled Project';
    final status = (project['status'] ?? 'OPEN').toString().toUpperCase();
    final budget = project['budget']?.toString() ?? '0';
    final deadline = project['deadline'] ?? '';
    
    Color statusColor = AppColors.primary;
    if (status == 'COMPLETED') statusColor = Colors.green;
    if (status == 'CLOSED') statusColor = Colors.grey;

    final theme = Theme.of(context);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark ? Colors.black26 : Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (deadline.isNotEmpty)
                    Text(
                      deadline,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 11),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.monetization_on_outlined, color: AppColors.primary, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '₹$budget',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> proposal;

  const _ActivityItem({required this.proposal});

  @override
  Widget build(BuildContext context) {
    final status = (proposal['status'] ?? 'PENDING').toString().toUpperCase();
    final amount = proposal['amount']?.toString() ?? '0';
    final projectTitle = proposal['project']?['title'] ?? proposal['projectId'] ?? 'Project';
    final createdAt = proposal['createdAt'] ?? '';
    
    IconData icon = Icons.send_outlined;
    Color iconColor = AppColors.primary;
    String message = 'Proposal sent';
    
    if (status == 'ACCEPTED') {
      icon = Icons.check_circle_outline;
      iconColor = Colors.green;
      message = 'Proposal accepted';
    } else if (status == 'REJECTED') {
      icon = Icons.cancel_outlined;
      iconColor = Colors.red;
      message = 'Proposal rejected';
    } else if (status == 'PENDING') {
      icon = Icons.hourglass_empty;
      iconColor = Colors.orange;
      message = 'Proposal pending';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$projectTitle • ₹$amount',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), 
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), size: 18),
        ],
      ),
    );
  }
}



class _PromoBanner extends StatefulWidget {
  const _PromoBanner();

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> _images = [
    'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800&q=80', // Office/Freelance
    'https://images.unsplash.com/photo-1551434678-e076c223a692?w=800&q=80', // Coding
    'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800&q=80', // Collaboration
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(_images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Offer',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        index == 0 ? 'Get 20% off on your first project' : 
                        index == 1 ? 'Top rated developers ready to hire' : 
                        'Grow your business with expert freelancers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _images.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.primary : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


