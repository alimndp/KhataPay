import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common_widgets.dart';
import 'transaction_form_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Income'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
            );
            ref.invalidate(transactionsProvider);
            ref.invalidate(dashboardSummaryProvider);
          },
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _TransactionList(type: null),
            _TransactionList(type: 'income'),
            _TransactionList(type: 'expense'),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  final String? type;

  const _TransactionList({this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = type == null
        ? ref.watch(transactionsProvider)
        : type == 'income'
            ? ref.watch(incomeTransactionsProvider)
            : ref.watch(expenseTransactionsProvider);

    return transactionsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () {
          if (type == null) {
            ref.invalidate(transactionsProvider);
          } else if (type == 'income') {
            ref.invalidate(incomeTransactionsProvider);
          } else {
            ref.invalidate(expenseTransactionsProvider);
          }
        },
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return EmptyStateWidget(
            message: type == null
                ? 'No transactions yet.\nTap + to add income or expense'
                : 'No ${type ?? ''} transactions yet',
            icon: Icons.receipt_long_outlined,
            action: type == null
                ? ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionFormScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                  )
                : null,
          );
        }

        // Calculate totals
        final total = transactions
            .where((t) => type == null || t.type == type)
            .fold<double>(0, (sum, t) => sum + t.amount);

        return Column(
          children: [
            // Total summary card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type == null ? 'Total Balance' : 'Total ${type}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        Formatters.currency(total),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: type == 'expense'
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Transaction list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (type == null) {
                    ref.invalidate(transactionsProvider);
                  } else if (type == 'income') {
                    ref.invalidate(incomeTransactionsProvider);
                  } else {
                    ref.invalidate(expenseTransactionsProvider);
                  }
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    return _TransactionTile(transaction: transactions[index]);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction.description ?? 'Transaction',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${transaction.category?.name ?? 'Uncategorized'} • ${Formatters.date(transaction.transactionDate)}',
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${Formatters.currency(transaction.amount)}',
        style: TextStyle(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}