class Account {
  final String id;
  final String name;
  final String accountType; // 'cash', 'bank', 'upi_wallet'
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Account({
    required this.id,
    required this.name,
    this.accountType = 'bank',
    this.openingBalance = 0,
    this.currentBalance = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['account_type'] as String? ?? 'bank',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
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
      'name': name,
      'account_type': accountType,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'is_active': isActive,
    };
  }
}