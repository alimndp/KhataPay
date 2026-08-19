import 'category.dart';

class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final String? categoryId;
  final String? accountId;
  final double amount;
  final String currency;
  final String? description;
  final DateTime transactionDate;
  final String paymentMethod;
  final String? reference;
  final String? linkedDisbursementId;
  final String? createdBy;
  final DateTime? createdAt;
  final Category? category;

  Transaction({
    required this.id,
    required this.type,
    this.categoryId,
    this.accountId,
    required this.amount,
    this.currency = 'INR',
    this.description,
    required this.transactionDate,
    this.paymentMethod = 'cash',
    this.reference,
    this.linkedDisbursementId,
    this.createdBy,
    this.createdAt,
    this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? categoryData = json['categories'] as Map<String, dynamic>?;
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      categoryId: json['category_id'] as String?,
      accountId: json['account_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      description: json['description'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : DateTime.now(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      reference: json['reference'] as String?,
      linkedDisbursementId: json['linked_disbursement_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      category: categoryData != null ? Category.fromJson(categoryData) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category_id': categoryId,
      'account_id': accountId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'payment_method': paymentMethod,
      'reference': reference,
      'linked_disbursement_id': linkedDisbursementId,
      'created_by': createdBy,
    };
  }

  bool get isIncome => type == 'income';
}