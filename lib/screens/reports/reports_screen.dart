import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _reportType = 'profit_loss';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Report type selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Report',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'profit_loss',
                        label: Text('P&L'),
                        icon: Icon(Icons.trending_up),
                      ),
                      ButtonSegment(
                        value: 'cash_flow',
                        label: Text('Cash Flow'),
                        icon: Icon(Icons.swap_vert),
                      ),
                      ButtonSegment(
                        value: 'accounts',
                        label: Text('Accounts'),
                        icon: Icon(Icons.account_balance),
                      ),
                    ],
                    selected: {_reportType},
                    onSelectionChanged: (selection) {
                      setState(() => _reportType = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date range
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateRange(context),
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            '${Formatters.date(_startDate)} - ${Formatters.date(_endDate)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_reportType != 'accounts') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Date range applies to P&L and Cash Flow reports',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Report content
          if (_reportType == 'profit_loss')
            _ProfitLossReport(
              startDate: _startDate,
              endDate: _endDate,
            )
          else if (_reportType == 'cash_flow')
            _CashFlowReport(
              startDate: _startDate,
              endDate: _endDate,
            )
          else
            const _AccountSummaryReport(),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }
}

// ============================================================
// PROFIT & LOSS REPORT
// ============================================================
class _ProfitLossReport extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _ProfitLossReport({
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      profitLossReportProvider((startDate, endDate)),
    );

    return reportAsync.when(
      loading: () => const LoadingWidget(message: 'Generating P&L report...'),
      error: (e, _) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(profitLossReportProvider),
      ),
      data: (data) {
        final income = (data['total_income'] as num?)?.toDouble() ?? 0;
        final expense = (data['total_expense'] as num?)?.toDouble() ?? 0;
        final net = (data['net_profit'] as num?)?.toDouble() ?? 0;
        final incomeByCategory = data['income_by_category'] as List? ?? [];
        final expenseByCategory = data['expense_by_category'] as List? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Income',
                    value: Formatters.compactCurrency(income),
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Total Expense',
                    value: Formatters.compactCurrency(expense),
                    icon: Icons.trending_down,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatCard(
              title: 'Net Profit',
              value: Formatters.compactCurrency(net),
              icon: Icons.account_balance_wallet,
              color: net >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
              subtitle: '${Formatters.date(startDate)} - ${Formatters.date(endDate)}',
            ),
            const SizedBox(height: 24),

            // Income by category chart
            const SectionHeader(title: 'Income by Category'),
            if (incomeByCategory.isEmpty)
              const EmptyStateWidget(
                message: 'No income data',
                icon: Icons.pie_chart_outline,
              )
            else
              _CategoryPieChart(
                data: incomeByCategory,
                colors: const [
                  Colors.green,
                  Colors.teal,
                  Colors.lightGreen,
                  Colors.lime,
                ],
              ),
            const SizedBox(height: 24),

            // Expense by category chart
            const SectionHeader(title: 'Expense by Category'),
            if (expenseByCategory.isEmpty)
              const EmptyStateWidget(
                message: 'No expense data',
                icon: Icons.pie_chart_outline,
              )
            else
              _CategoryPieChart(
                data: expenseByCategory,
                colors: const [
                  Colors.red,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.pink,
                ],
              ),
          ],
        );
      },
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<dynamic> data;
  final List<Color> colors;

  const _CategoryPieChart({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
    );

    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(data.length, (index) {
                    final item = data[index] as Map<String, dynamic>;
                    final value = (item['amount'] as num?)?.toDouble() ?? 0;
                    return PieChartSectionData(
                      value: value,
                      title:
                          '${(value / total * 100).toStringAsFixed(0)}%',
                      color: colors[index % colors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            ...data.asMap().entries.map((entry) {
              final item = entry.value as Map<String, dynamic>;
              return ListTile(
                dense: true,
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[entry.key % colors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                title: Text(item['category'] ?? 'Unknown'),
                trailing: Text(
                  Formatters.currency(
                    (item['amount'] as num?)?.toDouble() ?? 0,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CASH FLOW REPORT
// ============================================================
class _CashFlowReport extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _CashFlowReport({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(cashFlowReportProvider((startDate, endDate)));

    return reportAsync.when(
      loading: () => const LoadingWidget(message: 'Generating cash flow...'),
      error: (e, _) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(cashFlowReportProvider),
      ),
      data: (data) {
        if (data.isEmpty) {
          return const EmptyStateWidget(
            message: 'No data for selected period',
            icon: Icons.bar_chart,
          );
        }

        final months = data.map((d) => d['month'] as String).toList();
        final incomes =
            data.map((d) => (d['income'] as num?)?.toDouble() ?? 0).toList();
        final expenses =
            data.map((d) => (d['expense'] as num?)?.toDouble() ?? 0).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bar chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY([...incomes, ...expenses]),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = months[groupIndex];
                            final isIncome = rodIndex == 0;
                            return BarTooltipItem(
                              '$label\n${isIncome ? "Income" : "Expense"}: '
                              '${Formatters.compactCurrency(rod.toY)}',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= months.length) {
                                return const SizedBox.shrink();
                              }
                              // Show short month label
                              final monthStr = months[index];
                              final parts = monthStr.split('-');
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  parts.length == 2
                                      ? '${parts[1]}/${parts[0].substring(2)}'
                                      : monthStr,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: incomes[index],
                              color: Colors.green,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: expenses[index],
                              color: Colors.red,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
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
                _LegendItem(color: Colors.green, label: 'Income'),
                const SizedBox(width: 24),
                _LegendItem(color: Colors.red, label: 'Expense'),
              ],
            ),
            const SizedBox(height: 16),
            // Data table
            Card(
              child: Column(
                children: [
                  ...data.map((d) => ListTile(
                        dense: true,
                        title: Text(d['month'] as String),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'In: ${Formatters.compactCurrency((d['income'] as num?)?.toDouble() ?? 0)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Out: ${Formatters.compactCurrency((d['expense'] as num?)?.toDouble() ?? 0)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Net: ${Formatters.compactCurrency((d['net'] as num?)?.toDouble() ?? 0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  double _getMaxY(List<double> values) {
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    return max * 1.2 > 0 ? max * 1.2 : 100;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
        Text(label),
      ],
    );
  }
}

// ============================================================
// ACCOUNT SUMMARY REPORT
// ============================================================
class _AccountSummaryReport extends ConsumerWidget {
  const _AccountSummaryReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(accountSummaryProvider);

    return summaryAsync.when(
      loading: () => const LoadingWidget(message: 'Loading accounts...'),
      error: (e, _) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(accountSummaryProvider),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const EmptyStateWidget(
            message: 'No accounts found',
            icon: Icons.account_balance_outlined,
          );
        }

        return Column(
          children: [
            ...accounts.map((account) {
              final acc = account as Map<String, dynamic>;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getAccountIcon(acc['account_type'] as String?),
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            acc['account_name'] as String? ?? 'Account',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Current Balance: ${Formatters.currency((acc['current_balance'] as num?)?.toDouble() ?? 0)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Opening: ${Formatters.currency((acc['opening_balance'] as num?)?.toDouble() ?? 0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Income: ${Formatters.currency((acc['total_income'] as num?)?.toDouble() ?? 0)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Expense: ${Formatters.currency((acc['total_expense'] as num?)?.toDouble() ?? 0)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  IconData _getAccountIcon(String? type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'upi_wallet':
        return Icons.phone_android;
      default:
        return Icons.account_balance_wallet;
    }
  }
}