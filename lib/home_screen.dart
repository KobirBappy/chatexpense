import 'package:chatapp/account_screen_corrected.dart';
import 'package:chatapp/firebase_service.dart';
import 'package:chatapp/notification_service.dart';
import 'package:chatapp/subscription_provider.dart';
import 'package:chatapp/theme_config.dart';
import 'package:chatapp/transaction_provider.dart';
import 'package:chatapp/transaction_screen_corrected.dart';
import 'package:chatapp/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/dashboard_screen_corrected.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const TransactionScreen(),
    const DashboardScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncDailyReminderFromCurrentState();
    }
  }

  void _initializeData() async {
    final userProvider = context.read<UserProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    
    // Load user data
    final userId = userProvider.user?.id ?? FirebaseService.currentUser?.uid;
    if (userId != null) {
      await Future.wait([
        transactionProvider.loadTransactions(userId),
        subscriptionProvider.loadSubscription(userId),
      ]);
      _syncDailyReminderFromCurrentState();
    }
  }

  Future<void> _syncDailyReminderFromCurrentState() async {
    if (!mounted) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final settings = user.notificationSettings;
    final dailyReminders = settings['dailyReminders'] ?? true;
    final reminderTime = (settings['reminderTime'] ?? '12:01').toString();

    final parts = reminderTime.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 12;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;

    final transactions = context.read<TransactionProvider>().transactions;
    final now = DateTime.now();
    final hasLoggedToday = transactions.any((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day);

    await NotificationService.syncDailyTransactionReminder(
      enabled: dailyReminders,
      hour: hour,
      minute: minute,
      hasLoggedTransactionToday: hasLoggedToday,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep reminder schedule in sync with live user settings and transactions.
    final user = context.watch<UserProvider>().user;
    final transactions = context.watch<TransactionProvider>().transactions;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || user == null) return;

      final settings = user.notificationSettings;
      final dailyReminders = settings['dailyReminders'] ?? true;
      final reminderTime = (settings['reminderTime'] ?? '12:01').toString();
      final parts = reminderTime.split(':');
      final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 12;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;

      final now = DateTime.now();
      final hasLoggedToday = transactions.any((t) =>
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day);

      await NotificationService.syncDailyTransactionReminder(
        enabled: dailyReminders,
        hour: hour,
        minute: minute,
        hasLoggedTransactionToday: hasLoggedToday,
      );
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.receipt_long_outlined, 0),
              activeIcon: _buildNavIcon(Icons.receipt_long, 0, isActive: true),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.bar_chart_outlined, 1),
              activeIcon: _buildNavIcon(Icons.bar_chart, 1, isActive: true),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outline, 2),
              activeIcon: _buildNavIcon(Icons.person, 2, isActive: true),
              label: 'Account',
            ),
          ],
        ),
      ),
    //  floatingActionButton: _currentIndex == 0 ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildNavIcon(IconData icon, int index, {bool isActive = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 28,
          ),
        ),
        if (index == 0 && _hasUnloggedTransactions())
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  // Widget _buildFloatingActionButton() {
  //   return FloatingActionButton(
  //     onPressed: _showQuickAddMenu,
  //     backgroundColor: AppTheme.primaryColor,
  //     child: const Icon(Icons.add, size: 28),
  //   );
  // }

  void _showQuickAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Quick Add Transaction',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildQuickAddOption(
                    icon: Icons.mic,
                    title: 'Voice Command',
                    subtitle: 'Say your transaction',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      // Trigger voice input
                    },
                  ),
                  _buildQuickAddOption(
                    icon: Icons.camera_alt,
                    title: 'Scan Receipt',
                    subtitle: 'Take a photo of receipt',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      // Trigger camera
                    },
                  ),
                  _buildQuickAddOption(
                    icon: Icons.edit,
                    title: 'Manual Entry',
                    subtitle: 'Type transaction details',
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to manual entry
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  bool _hasUnloggedTransactions() {
    // Check if user has logged transactions today
    final transactions = context.watch<TransactionProvider>().transactions;
    final today = DateTime.now();
    return !transactions.any((t) => 
      t.date.year == today.year && 
      t.date.month == today.month && 
      t.date.day == today.day
    );
  }
}


