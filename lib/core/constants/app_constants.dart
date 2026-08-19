class AppConstants {
  // TODO: Replace with your Supabase project credentials
  static const String supabaseUrl = 'https://ndsejkanautccabuwkkj.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_y8XFp5pQen7sj-jDBt2STg_wAenmS7j';

  // App info
  static const String appName = 'KhataPay';
  static const String appVersion = '1.0.0';

  // Currency
  static const String defaultCurrency = 'INR';

  // Roles
  static const String roleBusinessOwner = 'business_owner';
  static const String roleFinance = 'finance';
  static const String roleHr = 'hr';
  static const String roleEmployee = 'employee';

  // Transaction types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // Payment methods
  static const List<String> paymentMethods = [
    'cash',
    'bank',
    'upi',
    'card',
    'other',
  ];

  // Disbursement statuses
  static const List<String> disbursementStatuses = [
    'pending_approval',
    'approved',
    'rejected',
    'paid',
    'failed',
  ];

  // Invoice statuses
  static const List<String> invoiceStatuses = [
    'draft',
    'sent',
    'paid',
    'overdue',
    'cancelled',
  ];

  // Account types
  static const List<String> accountTypes = [
    'cash',
    'bank',
    'upi_wallet',
  ];
}