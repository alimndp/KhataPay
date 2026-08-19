import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee.dart';
import '../models/transaction.dart';
import '../models/attendance.dart';
import '../models/salary_disbursement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/invoice.dart';

class ApiService {
  final SupabaseClient _client;

  ApiService(this._client);

  // ============================================================
  // AUTH & PROFILES
  // ============================================================

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  Future<String?> getCurrentUserRole() async {
    final profile = await getCurrentProfile();
    return profile?['role'] as String?;
  }

  // ============================================================
  // EMPLOYEES
  // ============================================================

  Future<List<Employee>> getEmployees() async {
    final response = await _client.from('employees').select();
    return response.map((e) => Employee.fromJson(e)).toList();
  }

  Future<Employee> getEmployee(String id) async {
    final response = await _client
        .from('employees')
        .select()
        .eq('id', id)
        .single();
    return Employee.fromJson(response);
  }

  Future<Employee> createEmployee(Map<String, dynamic> data) async {
    final response = await _client.from('employees').insert(data).select().single();
    return Employee.fromJson(response);
  }

  Future<Employee> updateEmployee(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('employees')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Employee.fromJson(response);
  }

  Future<void> deleteEmployee(String id) async {
    await _client.from('employees').delete().eq('id', id);
  }

  // ============================================================
  // ATTENDANCE
  // ============================================================

  Future<List<Attendance>> getAttendance(String employeeId) async {
    final response = await _client
        .from('attendance_logs')
        .select()
        .eq('employee_id', employeeId)
        .order('attendance_date', ascending: false);
    return response.map((a) => Attendance.fromJson(a)).toList();
  }

  Future<Attendance> checkIn(String employeeId) async {
    final today = DateTime.now();
    final response = await _client.from('attendance_logs').insert({
      'employee_id': employeeId,
      'attendance_date': today.toIso8601String().substring(0, 10),
      'check_in_time': today.toIso8601String(),
      'status': 'present',
    }).select().single();
    return Attendance.fromJson(response);
  }

  Future<Attendance> checkOut(String attendanceId) async {
    final now = DateTime.now();
    final response = await _client
        .from('attendance_logs')
        .update({'check_out_time': now.toIso8601String()})
        .eq('id', attendanceId)
        .select()
        .single();
    return Attendance.fromJson(response);
  }

  // ============================================================
  // SALARY DISBURSEMENTS
  // ============================================================

  Future<List<SalaryDisbursement>> getDisbursements() async {
    final response = await _client
        .from('salary_disbursements')
        .select('*, employees(*)')
        .order('created_at', ascending: false);
    return response.map((d) => SalaryDisbursement.fromJson(d)).toList();
  }

  Future<List<SalaryDisbursement>> getPendingApprovals() async {
    final response = await _client
        .from('salary_disbursements')
        .select('*, employees(*)')
        .eq('status', 'pending_approval')
        .order('requested_at', ascending: true);
    return SalaryDisbursement.fromJsonList(response);
  }

  Future<SalaryDisbursement> createDisbursement(Map<String, dynamic> data) async {
    final response = await _client.from('salary_disbursements').insert(data).select().single();
    return SalaryDisbursement.fromJson(response);
  }

  Future<int> bulkCreateDisbursements(String periodMonth) async {
    final response = await _client.rpc(
      'bulk_create_disbursements',
      params: {'p_period_month': periodMonth},
    );
    return response as int;
  }

  Future<void> approveDisbursement(String approvalId, String disbursementId) async {
    await _client.from('disbursement_approvals').update({
      'status': 'approved',
    }).eq('id', approvalId);
  }

  Future<void> rejectDisbursement(String approvalId, String disbursementId, String comments) async {
    await _client.from('disbursement_approvals').update({
      'status': 'rejected',
      'comments': comments,
    }).eq('id', approvalId);
  }

  Future<String> generateUpiLink(String disbursementId) async {
    final response = await _client.rpc(
      'generate_upi_link',
      params: {'p_disbursement_id': disbursementId},
    );
    return response as String;
  }

  Future<void> markDisbursementPaid(String disbursementId, String? reference) async {
    await _client.rpc(
      'mark_disbursement_paid',
      params: {
        'p_disbursement_id': disbursementId,
        'p_payment_reference': reference ?? '',
      },
    );
  }

  Future<void> markDisbursementFailed(String disbursementId, String error) async {
    await _client.rpc(
      'mark_disbursement_failed',
      params: {
        'p_disbursement_id': disbursementId,
        'p_error': error,
      },
    );
  }

  // ============================================================
  // ACCOUNTS MODULE
  // ============================================================

  Future<List<Category>> getCategories({String? type}) async {
    dynamic query = _client.from('categories').select();
    if (type != null) {
      query = query.eq('type', type);
    }
    query = query.order('name');
    final response = await query;
    return response.map((c) => Category.fromJson(c)).toList();
  }

  Future<List<Account>> getAccounts() async {
    final response = await _client.from('accounts').select().order('name');
    return response.map((a) => Account.fromJson(a)).toList();
  }

  Future<Account> createAccount(Map<String, dynamic> data) async {
    final response = await _client.from('accounts').insert(data).select().single();
    return Account.fromJson(response);
  }

  Future<List<Transaction>> getTransactions({
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    dynamic query = _client
        .from('transactions')
        .select('*, categories(*)');

    if (type != null) query = query.eq('type', type);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (startDate != null) {
      query = query.gte('transaction_date', startDate.toIso8601String().substring(0, 10));
    }
    if (endDate != null) {
      query = query.lte('transaction_date', endDate.toIso8601String().substring(0, 10));
    }

    query = query.order('transaction_date', ascending: false);

    final response = await query;
    return response.map((t) => Transaction.fromJson(t)).toList();
  }

  Future<Transaction> createTransaction(Map<String, dynamic> data) async {
    final response = await _client.from('transactions').insert(data).select().single();
    return Transaction.fromJson(response);
  }

  Future<Transaction> updateTransaction(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('transactions')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Transaction.fromJson(response);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  // ============================================================
  // INVOICES
  // ============================================================

  Future<List<Invoice>> getInvoices({String? status}) async {
    dynamic query = _client.from('invoices').select();
    if (status != null) query = query.eq('status', status);
    query = query.order('issue_date', ascending: false);
    final response = await query;
    return response.map((i) => Invoice.fromJson(i)).toList();
  }

  Future<Invoice> createInvoice(Map<String, dynamic> data) async {
    final response = await _client.from('invoices').insert(data).select().single();
    return Invoice.fromJson(response);
  }

  Future<Invoice> updateInvoiceStatus(String id, String status) async {
    final data = {
      'status': status,
      if (status == 'paid') 'paid_at': DateTime.now().toIso8601String(),
    };
    final response = await _client
        .from('invoices')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Invoice.fromJson(response);
  }

  // ============================================================
  // REPORTS (Database Functions)
  // ============================================================

  Future<Map<String, dynamic>> getProfitLoss(DateTime start, DateTime end) async {
    final response = await _client.rpc('get_profit_loss_report', params: {
      'p_start_date': start.toIso8601String().substring(0, 10),
      'p_end_date': end.toIso8601String().substring(0, 10),
    });
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCashFlow(DateTime start, DateTime end) async {
    final response = await _client.rpc('get_cash_flow_report', params: {
      'p_start_date': start.toIso8601String().substring(0, 10),
      'p_end_date': end.toIso8601String().substring(0, 10),
    });
    return response as List<dynamic>;
  }

  Future<List<dynamic>> getAccountSummary() async {
    final response = await _client.rpc('get_account_summary');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _client.rpc('get_dashboard_summary');
    return response as Map<String, dynamic>;
  }

  // ============================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================

  RealtimeChannel subscribeToTable({
    required String table,
    String? filterColumn,
    String? filterValue,
    required void Function(String event, Map<String, dynamic> payload) onEvent,
  }) {
    var channel = _client.channel('realtime:$table:${DateTime.now().millisecondsSinceEpoch}');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      table: table,
      callback: (payload) {
        onEvent(payload.eventType.name, payload.newRecord);
      },
    );

    channel.subscribe();
    return channel;
  }

  void unsubscribe(String tableName) {
    _client.channel('realtime:$tableName').unsubscribe();
  }
}