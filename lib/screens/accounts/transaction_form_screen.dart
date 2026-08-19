import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common_widgets.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();

  String _type = AppConstants.typeExpense;
  String? _categoryId;
  String? _accountId;
  String _paymentMethod = 'cash';
  DateTime _transactionDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      showSnackBar(context, 'Please select a category', isError: true);
      return;
    }
    if (_accountId == null) {
      showSnackBar(context, 'Please select an account', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider)?.id;

    final data = {
      'type': _type,
      'category_id': _categoryId,
      'account_id': _accountId,
      'amount': double.parse(_amountController.text.trim()),
      'currency': 'INR',
      'description': _descriptionController.text.trim(),
      'transaction_date':
          _transactionDate.toIso8601String().substring(0, 10),
      'payment_method': _paymentMethod,
      'reference': _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      'created_by': user,
    };

    try {
      await ref.read(apiServiceProvider).createTransaction(data);
      if (!mounted) return;
      showSnackBar(context, 'Transaction added');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeCategoriesAsync = ref.watch(incomeCategoriesProvider);
    final expenseCategoriesAsync = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type selector
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: AppConstants.typeExpense,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: AppConstants.typeIncome,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _type = selection.first;
                      _categoryId = null;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category dropdown
                _type == AppConstants.typeIncome
                    ? incomeCategoriesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (categories) =>
                            _buildCategoryDropdown(categories),
                      )
                    : expenseCategoriesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (categories) =>
                            _buildCategoryDropdown(categories),
                      ),
                const SizedBox(height: 16),

                // Account dropdown
                accountsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (accounts) => _buildAccountDropdown(accounts),
                ),
                const SizedBox(height: 16),

                // Payment method
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: AppConstants.paymentMethods
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentMethod = value);
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Reference
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference (invoice/note)',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),

                // Date picker
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Transaction Date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      '${_transactionDate.day}/${_transactionDate.month}/${_transactionDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _type == AppConstants.typeIncome
                        ? Colors.green
                        : AppTheme.errorColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _type == AppConstants.typeIncome
                              ? 'Add Income'
                              : 'Add Expense',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<String>(
      initialValue: _categoryId,
      decoration: const InputDecoration(
        labelText: 'Category *',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (value) => setState(() => _categoryId = value),
    );
  }

  Widget _buildAccountDropdown(List<Account> accounts) {
    return DropdownButtonFormField<String>(
      initialValue: _accountId,
      decoration: const InputDecoration(
        labelText: 'Account *',
        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
      ),
      items: accounts
          .where((a) => a.isActive)
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: (value) => setState(() => _accountId = value),
    );
  }
}