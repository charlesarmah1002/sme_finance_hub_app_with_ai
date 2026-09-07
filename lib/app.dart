import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/accounts_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/reports_screen.dart';

class CashflowApp extends StatelessWidget {
  const CashflowApp({super.key, this.loadDashboard = true});

  final bool loadDashboard;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SME Cashflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF126B5B)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _AuthGate(loadDashboard: loadDashboard),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.loadDashboard});

  final bool loadDashboard;

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<AuthProvider>().status) {
      AuthStatus.loading => const SplashScreen(),
      AuthStatus.authenticated => AppShell(loadDashboard: loadDashboard),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.loadDashboard = true});

  final bool loadDashboard;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const destinations = [
    _Destination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _Destination('Transactions', Icons.receipt_long_outlined, Icons.receipt_long),
    _Destination('Accounts', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
    _Destination('Categories', Icons.category_outlined, Icons.category),
    _Destination('Reports', Icons.bar_chart_outlined, Icons.bar_chart),
    _Destination('Settings', Icons.settings_outlined, Icons.settings),
  ];
  static const mobileDestinations = [0, 1, 2, 4];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final destination = destinations[selectedIndex];
    final mobileSelectedIndex = mobileDestinations.indexOf(selectedIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(destination.label),
        actions: [
          if (!isDesktop)
            PopupMenuButton<int>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              onSelected: _selectDestination,
              itemBuilder: (context) => [
                _menuItem(3),
                _menuItem(5),
                const PopupMenuDivider(),
                const PopupMenuItem<int>(
                  value: -1,
                  child: ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
                ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: _selectDestination,
              labelType: NavigationRailLabelType.all,
              trailing: IconButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
              ),
              destinations: [
                for (final item in destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
          Expanded(
            child: switch (destination.label) {
              'Dashboard' => DashboardScreen(loadOnStart: widget.loadDashboard),
              'Accounts' => const AccountsScreen(),
              'Categories' => const CategoriesScreen(),
              'Transactions' => const TransactionsScreen(),
              'Reports' => const ReportsScreen(),
              'Settings' => const SettingsScreen(),
              _ => _PlaceholderScreen(title: destination.label),
            },
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
            selectedIndex: mobileSelectedIndex < 0 ? 0 : mobileSelectedIndex,
              onDestinationSelected: (index) => _selectDestination(mobileDestinations[index]),
              destinations: [
                for (final index in mobileDestinations)
                  NavigationDestination(
                    icon: Icon(destinations[index].icon),
                    selectedIcon: Icon(destinations[index].selectedIcon),
                    label: destinations[index].label,
                  ),
              ],
            ),
    );
  }

  PopupMenuItem<int> _menuItem(int index) {
    final item = destinations[index];
    return PopupMenuItem<int>(
      value: index,
      child: ListTile(leading: Icon(item.icon), title: Text(item.label)),
    );
  }

  void _selectDestination(int index) {
    if (index == -1) {
      context.read<AuthProvider>().logout();
      return;
    }
    setState(() => selectedIndex = index);
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('$title will be available in a future checkpoint.'),
            ],
          ),
        ),
      ),
    );
  }
}
