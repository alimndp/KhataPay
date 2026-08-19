import 'employee.dart';

class SalaryDisbursement {
  final String id;
  final String employeeId;
  final double amount;
  final String currency;
  final DateTime periodMonth;
  final String status;
  final String initiationType;
  final String? requestedBy;
  final DateTime? requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? paymentReference;
  final String paymentStatus;
  final DateTime? paymentInitiatedAt;
  final String? notes;
  final DateTime? createdAt;
  final Employee? employee;

  SalaryDisbursement({
    required this.id,
    required this.employeeId,
    required this.amount,
    this.currency = 'INR',
    required this.periodMonth,
    this.status = 'pending_approval',
    this.initiationType = 'manual',
    this.requestedBy,
    this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.paymentReference,
    this.paymentStatus = 'not_initiated',
    this.paymentInitiatedAt,
    this.notes,
    this.createdAt,
    this.employee,
  });

  factory SalaryDisbursement.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? employeeData = json['employees'] as Map<String, dynamic>?;
    return SalaryDisbursement(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      periodMonth: DateTime.parse(json['period_month'] as String),
      status: json['status'] as String? ?? 'pending_approval',
      initiationType: json['initiation_type'] as String? ?? 'manual',
      requestedBy: json['requested_by'] as String?,
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String).toLocal()
          : null,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String).toLocal()
          : null,
      paymentReference: json['payment_reference'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'not_initiated',
      paymentInitiatedAt: json['payment_initiated_at'] != null
          ? DateTime.parse(json['payment_initiated_at'] as String).toLocal()
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      employee: employeeData != null ? Employee.fromJson(employeeData) : null,
    );
  }

  static List<SalaryDisbursement> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => SalaryDisbursement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'amount': amount,
      'currency': currency,
      'period_month': periodMonth.toIso8601String().substring(0, 10),
      'status': status,
      'initiation_type': initiationType,
      'requested_by': requestedBy,
      'payment_status': paymentStatus,
    };
  }
}