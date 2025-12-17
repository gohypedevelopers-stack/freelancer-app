import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';

class EarningsScreen extends StatefulWidget {
  final bool isFreelancer;
  const EarningsScreen({super.key, required this.isFreelancer});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _transactions = [];
  double _totalAmount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancials();
  }

  Future<void> _loadFinancials() async {
    try {
      final role = widget.isFreelancer ? 'FREELANCER' : 'CLIENT';
      List<Map<String, dynamic>> transactions = [];
      double total = 0;

      if (widget.isFreelancer) {
        // Freelancers: Calculate from Accepted Proposals
        final proposals = await _apiClient.fetchProposals();
        final accepted = proposals.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'ACCEPTED');
        
        for (var p in accepted) {
          final amount = double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
          total += amount;
          
          final project = p['project'] as Map<String, dynamic>? ?? {};
          transactions.add({
            'title': project['title'] ?? 'Project Payment',
            'date': project['updatedAt'] ?? p['updatedAt'] ?? '',
            'amount': amount,
            'status': 'RECEIVED',
          });
        }
      } else {
        // Clients: Calculate from Projects with Accepted Proposals
        // Note: Ideally API should provide this. Using fetchProjects('CLIENT') which returns all created projects.
        // We'll estimate spend based on project budget if status is NOT open, or strictly check proposals if available.
        // The fetchProjects for CLIENT returns raw project data.
        final projects = await _apiClient.fetchProjects('CLIENT');
        
        for (var p in projects) {
          // Assuming if status is CLOSED or COMPLETED or has accepted proposals, it counts as spend.
           // For simplicity in this demo, summing budget of non-open projects.
           final status = (p['status'] ?? '').toString().toUpperCase();
           if (status != 'OPEN') {
              final amount = double.tryParse(p['budget']?.toString() ?? '0') ?? 0;
              total += amount;
              transactions.add({
                'title': p['title'] ?? 'Project Budget',
                'date': p['updatedAt'] ?? '',
                'amount': amount,
                'status': 'SPENT',
              });
           }
        }
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _totalAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.isFreelancer ? 'Total Earnings' : 'Total Spend';
    final currencyColor = widget.isFreelancer ? Colors.green : Colors.redAccent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isFreelancer ? 'Earnings' : 'Financials', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: theme.cardColor,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _loadFinancials,
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                       Icon(
                         widget.isFreelancer ? Icons.currency_rupee : Icons.account_balance_wallet_outlined, 
                         size: 64, 
                         color: AppColors.primary
                       ),
                       const SizedBox(height: 16),
                       Text(title, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16)),
                       const SizedBox(height: 8),
                       Text(
                         '₹${_totalAmount.toStringAsFixed(2)}',
                         style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 36, fontWeight: FontWeight.bold),
                       ),
                    ],
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                    ? Center(
                        child: Text('No transaction history', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _transactions[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                                    ),
                                    if (item['date'] != '')
                                      Text(
                                        item['date'].toString().split('T')[0], // Simple date formatting
                                        style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                                      ),
                                  ],
                                ),
                                Text(
                                  '${widget.isFreelancer ? '+' : '-'} ₹${item['amount']}',
                                  style: TextStyle(color: currencyColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
}
