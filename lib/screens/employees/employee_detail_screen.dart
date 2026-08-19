import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/employee.dart';
import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/common_widgets.dart';
import 'employee_form_screen.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(employee.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmployeeFormScreen(employee: employee),
                ),
              );
              ref.invalidate(employeesProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            tooltip: 'Delete',
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Delete Employee',
                message: 'Are you sure you want to delete ${employee.fullName}?',
                confirmText: 'Delete',
                isDanger: true,
              );
              if (confirmed) {
                try {
                  await ref.read(apiServiceProvider).deleteEmployee(employee.id);
                  if (context.mounted) {
                    showSnackBar(context, 'Employee deleted');
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    showSnackBar(context, 'Failed to delete: $e', isError: true);
                  }
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      employee.fullName.isNotEmpty
                          ? employee.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    employee.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (employee.designation != null)
                    Text(
                      employee.designation!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
                  StatusBadge(
                    status: employee.isActive ? 'active' : 'inactive',
                    small: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Employee details
          Card(
            child: Column(
              children: [
                _DetailTile(
                  icon: Icons.badge_outlined,
                  label: 'Employee Code',
                  value: employee.employeeCode,
                ),
                _DetailTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: Formatters.email(employee.email ?? ''),
                ),
                _DetailTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: Formatters.phone(employee.phone ?? ''),
                ),
                _DetailTile(
                  icon: Icons.work_outline,
                  label: 'Department',
                  value: employee.department ?? 'N/A',
                ),
                _DetailTile(
                  icon: Icons.attach_money,
                  label: 'Base Salary',
                  value: Formatters.currency(employee.baseSalary),
                ),
                _DetailTile(
                  icon: Icons.event_outlined,
                  label: 'Joining Date',
                  value: employee.joiningDate != null
                      ? Formatters.date(employee.joiningDate!)
                      : 'N/A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}