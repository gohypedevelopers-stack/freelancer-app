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
                // Premium Total Earnings Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E1E1E),
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: AppColors.primary.withOpacity(0.1),
                           shape: BoxShape.circle,
                           border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                         ),
                         child: Icon(
                           widget.isFreelancer ? Icons.currency_rupee : Icons.account_balance_wallet_outlined, 
                           size: 40, 
                           color: AppColors.primary
                         ),
                       ),
                       const SizedBox(height: 16),
                       Text(title.toUpperCase(), 
                         style: TextStyle(
                           color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), 
                           fontSize: 12, 
                           letterSpacing: 1.2,
                           fontWeight: FontWeight.bold
                         )
                       ),
                       const SizedBox(height: 8),
                       Text(
                         '₹${_totalAmount.toStringAsFixed(2)}',
                         style: const TextStyle(
                           color: Colors.white, 
                           fontSize: 42, // Larger and bolder
                           fontWeight: FontWeight.w900,
                           height: 1.1,
                         ),
                       ),
                    ],
                  ),
                ),
                
                // Transactions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "TRANSACTION HISTORY", 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: theme.disabledColor, 
                        letterSpacing: 1.1
                      )
                    ),
                  ),
                ),

                Expanded(
                  child: _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: theme.disabledColor.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text('No transaction history', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _transactions[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {}, // Future: Show transaction details
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: currencyColor.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              widget.isFreelancer ? Icons.arrow_downward : Icons.arrow_upward,
                                              size: 18,
                                              color: currencyColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['title'],
                                                style: TextStyle(
                                                  color: theme.textTheme.bodyLarge?.color, 
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (item['date'] != '')
                                                Text(
                                                  item['date'].toString().split('T')[0], 
                                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 12),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${widget.isFreelancer ? '+' : '-'} ₹${item['amount']}',
                                        style: TextStyle(color: currencyColor, fontWeight: FontWeight.bold, fontSize: 18),
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
              ],
            ),
          ),
    );
  }
}
