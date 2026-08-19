import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/api_providers.dart';
import '../accounts/accounts_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../salary/salary_screen.dart';
import '../employees/employees_screen.dart';
import '../reports/reports_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffProvider);
    final isOwner = ref.watch(isBusinessOwnerProvider);

    // Determine available tabs based on role
    final tabs = <Widget>[
      const DashboardScreen(),
      if (isStaff) const EmployeesScreen(),
      if (isStaff) const SalaryScreen(),
      if (isOwner || ref.watch(currentUserRoleProvider).valueOrNull == 'finance')
        const AccountsScreen(),
      const ReportsScreen(),
    ];

    final showAccounts = isOwner ||
        ref.watch(currentUserRoleProvider).valueOrNull == 'finance';

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      if (isStaff)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Employees',
        ),
      if (isStaff)
        const NavigationDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments),
          label: 'Salary',
        ),
      if (showAccounts)
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Accounts',
        ),
      const NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: 'Reports',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: destinations,
      ),
    );
  }
}
