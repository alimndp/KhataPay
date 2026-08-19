import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  Color _getColor() {
    switch (status) {
      case 'paid':
      case 'success':
      case 'approved':
      case 'present':
      case 'active':
        return Colors.green;
      case 'pending':
      case 'pending_approval':
      case 'initiated':
      case 'draft':
      case 'sent':
        return Colors.orange;
      case 'rejected':
      case 'failed':
      case 'cancelled':
      case 'absent':
        return Colors.red;
      case 'overdue':
        return Colors.deepOrange;
      case 'half_day':
      case 'leave':
      case 'holiday':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}