class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String? customerPhone;
  final double amount;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    required this.amount,
    this.status = 'draft',
    required this.issueDate,
    this.dueDate,
    this.paidAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'draft',
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String).toLocal()
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'amount': amount,
      'status': status,
      'issue_date': issueDate.toIso8601String().substring(0, 10),
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
    };
  }

  bool get isOverdue {
    if (status == 'paid' || status == 'cancelled') return false;
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  String get statusLabel {
    if (isOverdue) return 'overdue';
    return status;
  }
}