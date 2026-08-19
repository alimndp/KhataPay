import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/employee.dart';
import '../models/salary_disbursement.dart';
import '../models/transaction.dart';
import 'api_providers.dart';

// ============================================================
// EMPLOYEES
// ============================================================

final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  return ref.watch(apiServiceProvider).getEmployees();
});

final employeeProvider =
    FutureProvider.family<Employee, String>((ref, id) async {
  return ref.watch(apiServiceProvider).getEmployee(id);
});

// ============================================================
// TRANSACTIONS
// ============================================================

final transactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  return ref.watch(apiServiceProvider).getTransactions();
});

final incomeTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  return ref.watch(apiServiceProvider).getTransactions(type: 'income');
});

final expenseTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  return ref.watch(apiServiceProvider).getTransactions(type: 'expense');
});

// ============================================================
// SALARY DISBURSEMENTS
// ============================================================

final disbursementsProvider =
    FutureProvider.autoDispose<List<SalaryDisbursement>>((ref) async {
  return ref.watch(apiServiceProvider).getDisbursements();
});

final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<SalaryDisbursement>>((ref) async {
  return ref.watch(apiServiceProvider).getPendingApprovals();
});

// ============================================================
// ACCOUNTS MODULE
// ============================================================

final categoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  return ref.watch(apiServiceProvider).getCategories();
});

final incomeCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  return ref.watch(apiServiceProvider).getCategories(type: 'income');
});

final expenseCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  return ref.watch(apiServiceProvider).getCategories(type: 'expense');
});

final accountsProvider = FutureProvider.autoDispose<List<Account>>((ref) async {
  return ref.watch(apiServiceProvider).getAccounts();
});

// ============================================================
// REPORTS
// ============================================================

final dashboardSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(apiServiceProvider).getDashboardSummary();
});

// Provider for profit & loss report with date range
final profitLossReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, (DateTime, DateTime)>((ref, dates) async {
  return ref
      .watch(apiServiceProvider)
      .getProfitLoss(dates.$1, dates.$2);
});

// Provider for cash flow report with date range
final cashFlowReportProvider = FutureProvider.autoDispose
    .family<List<dynamic>, (DateTime, DateTime)>((ref, dates) async {
  return ref.watch(apiServiceProvider).getCashFlow(dates.$1, dates.$2);
});

final accountSummaryProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(apiServiceProvider).getAccountSummary();
});