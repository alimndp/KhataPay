import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/salary_disbursement.dart';
import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/status_badge.dart';

class DisbursementDetailScreen extends ConsumerWidget {
  final SalaryDisbursement disbursement;

  const DisbursementDetailScreen({super.key, required this.disbursement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApproved = disbursement.status == 'approved';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disbursement Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      disbursement.employee?.fullName.isNotEmpty == true
                          ? disbursement.employee!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    disbursement.employee?.fullName ?? 'Unknown Employee',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(disbursement.amount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusBadge(status: disbursement.status),
                      const SizedBox(width: 8),
                      if (disbursement.paymentStatus != 'not_initiated')
                        StatusBadge(status: disbursement.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details card
          Card(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Period',
                  value: Formatters.monthYear(disbursement.periodMonth),
                ),
                _DetailRow(
                  label: 'Initiation',
                  value: disbursement.initiationType,
                ),
                _DetailRow(
                  label: 'Requested At',
                  value: disbursement.requestedAt != null
                      ? Formatters.dateTime(disbursement.requestedAt!)
                      : 'N/A',
                ),
                _DetailRow(
                  label: 'Approved At',
                  value: disbursement.approvedAt != null
                      ? Formatters.dateTime(disbursement.approvedAt!)
                      : 'Not yet approved',
                ),
                if (disbursement.paymentReference != null)
                  _DetailRow(
                    label: 'Payment Ref',
                    value: disbursement.paymentReference!,
                  ),
                if (disbursement.notes != null)
                  _DetailRow(
                    label: 'Notes',
                    value: disbursement.notes!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons for approved disbursements
          if (isApproved) ...[
            ElevatedButton.icon(
              onPressed: () => _processPayment(context, ref),
              icon: const Icon(Icons.payment),
              label: const Text('Process UPI Payment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _markAsPaid(context, ref),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Paid Manually'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, WidgetRef ref) async {
    try {
      // Generate UPI link via database function
      final upiLink = await ref
          .read(apiServiceProvider)
          .generateUpiLink(disbursement.id);

      if (!context.mounted) return;

      // Launch UPI app
      final uri = Uri.parse(upiLink);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (launched) {
        showSnackBar(context, 'UPI app opened');
      } else {
        showSnackBar(context, 'Could not open UPI app', isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'Failed to generate UPI link: $e', isError: true);
    }
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(apiServiceProvider)
          .markDisbursementPaid(disbursement.id, null);

      if (!context.mounted) return;
      showSnackBar(context, 'Disbursement marked as paid');
      ref.invalidate(disbursementsProvider);
      ref.invalidate(pendingApprovalsProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'Failed: $e', isError: true);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }
}