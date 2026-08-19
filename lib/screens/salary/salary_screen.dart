import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/salary_disbursement.dart';
import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/status_badge.dart';
import 'disbursement_detail_screen.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Salary'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Disbursements'),
              Tab(text: 'Approvals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DisbursementListTab(),
            _ApprovalsTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DISBURSEMENTS TAB
// ============================================================
class _DisbursementListTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disbursementsAsync = ref.watch(disbursementsProvider);

    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final employees = employeesAsync.valueOrNull ?? [];
          if (employees.isEmpty) {
            showSnackBar(
              context,
              'Add employees before creating disbursements',
              isError: true,
            );
            return;
          }
          // Show bulk create dialog
          final periodMonth = await _showBulkCreateDialog(context);
          if (periodMonth != null) {
            try {
              final count = await ref
                  .read(apiServiceProvider)
                  .bulkCreateDisbursements(periodMonth);
              if (context.mounted) {
                showSnackBar(context, 'Created $count disbursements');
                ref.invalidate(disbursementsProvider);
                ref.invalidate(pendingApprovalsProvider);
              }
            } catch (e) {
              if (context.mounted) {
                showSnackBar(context, 'Failed: $e', isError: true);
              }
            }
          }
        },
        icon: const Icon(Icons.playlist_add),
        label: const Text('Bulk Create'),
      ),
      body: disbursementsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          error: e.toString(),
          onRetry: () => ref.invalidate(disbursementsProvider),
        ),
        data: (disbursements) {
          if (disbursements.isEmpty) {
            return const EmptyStateWidget(
              message: 'No salary disbursements yet',
              icon: Icons.payments_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(disbursementsProvider);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: disbursements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _DisbursementCard(disbursement: disbursements[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showBulkCreateDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Create Disbursements'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Period Month (YYYY-MM-DD)',
            helperText: 'e.g., 2024-08-01',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    return result;
  }
}

class _DisbursementCard extends StatelessWidget {
  final SalaryDisbursement disbursement;

  const _DisbursementCard({required this.disbursement});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            disbursement.employee?.fullName.isNotEmpty == true
                ? disbursement.employee!.fullName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          disbursement.employee?.fullName ?? 'Unknown Employee',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${Formatters.monthYear(disbursement.periodMonth)} • ${disbursement.initiationType}',
            ),
            const SizedBox(height: 4),
            StatusBadge(status: disbursement.status, small: true),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.currency(disbursement.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            if (disbursement.paymentStatus != 'not_initiated')
              Text(
                disbursement.paymentStatus,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DisbursementDetailScreen(
                disbursement: disbursement,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// APPROVALS TAB
// ============================================================
class _ApprovalsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(pendingApprovalsProvider);

    return approvalsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(pendingApprovalsProvider),
      ),
      data: (approvals) {
        if (approvals.isEmpty) {
          return const EmptyStateWidget(
            message: 'No pending approvals',
            icon: Icons.check_circle_outline,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingApprovalsProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: approvals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final approval = approvals[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.accentColor,
                    child: Icon(Icons.pending_actions, color: Colors.white),
                  ),
                  title: Text(
                    approval.employee?.fullName ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${Formatters.currency(approval.amount)} for ${Formatters.monthYear(approval.periodMonth)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => _handleApproval(context, ref, approval, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
                        tooltip: 'Reject',
                        onPressed: () => _handleApproval(context, ref, approval, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleApproval(
    BuildContext context,
    WidgetRef ref,
    SalaryDisbursement disbursement,
    bool approve,
  ) async {
    try {
      if (approve) {
        await ref
            .read(apiServiceProvider)
            .approveDisbursement(disbursement.id, disbursement.id);
      } else {
        final comments = await _showRejectDialog(context);
        if (comments == null) return;
        await ref
            .read(apiServiceProvider)
            .rejectDisbursement(disbursement.id, disbursement.id, comments);
      }
      if (context.mounted) {
        showSnackBar(context, approve ? 'Approved' : 'Rejected');
        ref.invalidate(pendingApprovalsProvider);
        ref.invalidate(disbursementsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Failed: $e', isError: true);
      }
    }
  }

  Future<String?> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Disbursement'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comments (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    return result;
  }
}