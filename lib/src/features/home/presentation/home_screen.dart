import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/auth/presentation/auth_selection_screen.dart';
import 'package:freelancer_flutter/src/features/home/domain/service_model.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _apiClient.getUser();
      final metrics = await _apiClient.fetchMetrics(user['role'] ?? 'CLIENT');
      
      if (mounted) {
        setState(() {
          _user = user;
          _metrics = metrics;
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final role = _user?['role']?.toString().toUpperCase() ?? 'CLIENT';
    final name = _user?['fullName'] ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$role Dashboard', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Metrics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: _buildMetrics(role),
            ),
            const SizedBox(height: 32),
            
            // Development Services (Horizontal Scroll)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Development', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: () {
                     // TODO: Navigate to Services Tab via MainScreen controller if possible, or just push ServicesScreen
                  }, 
                  child: const Text('See All', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _getDevelopmentServices().length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                   return ServiceCard(service: _getDevelopmentServices()[index], compact: true);
                },
              ),
            ),

             const SizedBox(height: 32),
            
            // Major Services (Vertical List)
            const Text('Major Services', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _getMajorServices().length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                 return ServiceCard(service: _getMajorServices()[index]);
              },
            ),
            
            const SizedBox(height: 24),
            // Recent Activity Placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Activity', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.history, color: AppColors.textSecondary, size: 48),
                        const SizedBox(height: 8),
                        Text('No recent activity found.', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetrics(String role) {
    if (_metrics == null) return [];

    if (role == 'CLIENT') {
      return [
        _MetricCard(label: 'Active Projects', value: _metrics!['active_projects'], icon: Icons.work_outline),
        _MetricCard(label: 'Completed', value: _metrics!['completed_projects'], icon: Icons.check_circle_outline),
        _MetricCard(label: 'Proposals Sent', value: _metrics!['proposals_sent'], icon: Icons.send_outlined),
        _MetricCard(label: 'Total Spend', value: _metrics!['total_spend'], icon: Icons.account_balance_wallet_outlined),
      ];
    } else {
      return [
        _MetricCard(label: 'Active Projects', value: _metrics!['active_projects'], icon: Icons.work_outline),
        _MetricCard(label: 'Proposals', value: _metrics!['proposals_received'], icon: Icons.mark_email_unread_outlined),
        _MetricCard(label: 'Accepted', value: _metrics!['accepted_proposals'], icon: Icons.thumb_up_alt_outlined),
        _MetricCard(label: 'Earnings', value: _metrics!['total_earnings'], icon: Icons.monetization_on_outlined),
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
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}


class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(icon, color: AppColors.primary, size: 18),
            ],
          ),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
