import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/salary_disbursement.dart';
import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(supabaseServiceProvider).signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final dashboardAsync = ref.watch(dashboardSummaryProvider);
    final pendingApprovalsAsync = ref.watch(pendingApprovalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KhataPay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          error: e.toString(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(pendingApprovalsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome section
              Text(
                'Welcome, ${profile?['full_name'] ?? user?.email ?? 'User'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _getRoleLabel(profile?['role'] as String?),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Dashboard stats
              dashboardAsync.when(
                loading: () => const LoadingWidget(),
                error: (e, _) => ErrorStateWidget(
                  error: e.toString(),
                  onRetry: () => ref.invalidate(dashboardSummaryProvider),
                ),
                data: (summary) => _buildDashboardContent(
                  context,
                  ref,
                  summary,
                  pendingApprovalsAsync,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> summary,
    AsyncValue<List<SalaryDisbursement>> pendingApprovals,
  ) {
    final income = (summary['month_income'] as num?)?.toDouble() ?? 0;
    final expense = (summary['month_expense'] as num?)?.toDouble() ?? 0;
    final net = (summary['month_net'] as num?)?.toDouble() ?? 0;
    final totalIncome = (summary['total_income'] as num?)?.toDouble() ?? 0;
    final totalExpense = (summary['total_expense'] as num?)?.toDouble() ?? 0;
    final pendingCount = (summary['pending_approvals'] as num?)?.toInt() ?? 0;
    final pendingInvoices = (summary['pending_invoices'] as num?)?.toInt() ?? 0;
    final recentTx = summary['recent_transactions'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Income & Expense cards
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Income (Month)',
                value: Formatters.compactCurrency(income),
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: 'Total: ${Formatters.compactCurrency(totalIncome)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Expense (Month)',
                value: Formatters.compactCurrency(expense),
                icon: Icons.trending_down,
                color: Colors.red,
                subtitle: 'Total: ${Formatters.compactCurrency(totalExpense)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Net profit card
        StatCard(
          title: 'Net Profit',
          value: Formatters.compactCurrency(net),
          icon: Icons.account_balance_wallet,
          color: net >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
          subtitle: 'Current month',
        ),
        const SizedBox(height: 24),

        // Pending approvals section
        const SectionHeader(
          title: 'Pending Approvals',
          trailing: Icon(Icons.notifications_active_outlined),
        ),
        pendingApprovals.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => Text('Error: $e'),
          data: (approvals) => approvals.isEmpty
              ? const EmptyStateWidget(
                  message: 'No pending approvals',
                  icon: Icons.check_circle_outline,
                )
              : Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.accentColor,
                      child: Icon(Icons.pending, color: Colors.white),
                    ),
                    title: Text('$pendingCount disbursement(s) pending'),
                    subtitle: const Text('Tap to review'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to salary approval screen
                    },
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // Income/Expense pie chart
        const SectionHeader(title: 'Income vs Expense'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieSections(income, expense),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(context, 'Income', Colors.green),
            const SizedBox(width: 24),
            _buildLegendItem(context, 'Expense', Colors.red),
          ],
        ),
        const SizedBox(height: 24),

        // Recent transactions
        const SectionHeader(title: 'Recent Transactions'),
        if (recentTx.isEmpty)
          const EmptyStateWidget(
            message: 'No transactions yet',
            icon: Icons.receipt_long_outlined,
          )
        else
          ...recentTx.take(5).map(
                (tx) => _buildTransactionTile(context, tx as Map<String, dynamic>),
              ),
        const SizedBox(height: 16),

        // Pending invoices
        if (pendingInvoices > 0) ...[
          const SectionHeader(title: 'Invoices'),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentColor,
                child: Icon(Icons.receipt_outlined, color: Colors.white),
              ),
              title: Text('$pendingInvoices pending invoice(s)'),
              subtitle: const Text('Draft, sent, or overdue'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(double income, double expense) {
    final total = income + expense;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          color: Colors.grey,
          radius: 40,
        ),
      ];
    }
    return [
      PieChartSectionData(
        value: income,
        title: '${(income / total * 100).toStringAsFixed(0)}%',
        color: Colors.green,
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: expense,
        title: '${(expense / total * 100).toStringAsFixed(0)}%',
        color: Colors.red,
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> tx) {
    final isIncome = tx['type'] == 'income';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(tx['description'] ?? 'Transaction'),
        subtitle: Text(
          Formatters.date(
            DateTime.parse(tx['date'] as String),
          ),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${Formatters.currency(amount)}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'business_owner':
        return 'Business Owner';
      case 'finance':
        return 'Finance';
      case 'hr':
        return 'HR';
      case 'employee':
        return 'Employee';
      default:
        return 'User';
    }
  }
}