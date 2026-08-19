import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/employee.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common_widgets.dart';
import 'employee_form_screen.dart';
import 'employee_detail_screen.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
          );
          ref.invalidate(employeesProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: employeesAsync.when(
        loading: () => const LoadingWidget(message: 'Loading employees...'),
        error: (e, _) => ErrorStateWidget(
          error: e.toString(),
          onRetry: () => ref.invalidate(employeesProvider),
        ),
        data: (employees) {
          if (employees.isEmpty) {
            return const EmptyStateWidget(
              message: 'No employees yet.\nTap + to add your first employee',
              icon: Icons.people_outline,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(employeesProvider);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _EmployeeCard(employee: employees[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends ConsumerWidget {
  final Employee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(
            employee.fullName.isNotEmpty
                ? employee.fullName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee.designation != null)
              Text(employee.designation!),
            Text(
              '${employee.employeeCode} • ${Formatters.compactCurrency(employee.baseSalary)}/mo',
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employee: employee),
            ),
          );
          ref.invalidate(employeesProvider);
        },
      ),
    );
  }
}