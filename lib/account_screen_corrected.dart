import 'package:chatapp/notification_service.dart';
import 'package:chatapp/subscription_model.dart';
import 'package:chatapp/subscription_provider.dart';
import 'package:chatapp/theme_config.dart';
import 'package:chatapp/transaction_provider.dart';
import 'package:chatapp/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedTabIndex = 0;
  bool _dailyRemindersEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 12, minute: 1);

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  void _loadUserSettings() {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      final timeStr = (user.notificationSettings['reminderTime'] ?? '12:01').toString();
      final parts = timeStr.split(':');
      final parsedHour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 12;
      final parsedMinute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;

      setState(() {
        _dailyRemindersEnabled = user.notificationSettings['dailyReminders'] ?? true;
        _reminderTime = TimeOfDay(
          hour: parsedHour,
          minute: parsedMinute,
        );
      });
      _syncDailyReminderNow();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Text('Help'),
              ),
              const PopupMenuItem(
                value: 'signout',
                child: Text('Sign Out'),
              ),
            ],
            onSelected: (value) {
              if (value == 'signout') {
                _handleSignOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _buildRedesignedTabs(),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: IndexedStack(
                key: ValueKey(_selectedTabIndex),
                index: _selectedTabIndex,
                children: [
                  _buildProfileTab(),
                  _buildUsageTab(),
                  _buildPlansTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedesignedTabs() {
    const tabs = [
      (icon: Icons.person_outline, label: 'Profile'),
      (icon: Icons.insights_outlined, label: 'Usage'),
      (icon: Icons.workspace_premium_outlined, label: 'Plans'),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final item = tabs[index];
          final isActive = _selectedTabIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = context.watch<UserProvider>().user;
    final subscription = context.watch<SubscriptionProvider>().subscription;
    final transactions = context.watch<TransactionProvider>().transactions;
    final now = DateTime.now();
    final hasLoggedToday = transactions.any((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withOpacity(0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'No name set',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'user@example.com',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.phoneNumber ?? 'No phone number',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickProfileStat(
                        icon: Icons.workspace_premium,
                        label: 'Plan',
                        value: context.read<SubscriptionProvider>().getPlanName(
                          subscription?.plan ?? SubscriptionPlan.free,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickProfileStat(
                        icon: Icons.verified_user,
                        label: 'Verified',
                        value: user?.emailVerified ?? false ? 'Yes' : 'No',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Status',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildStatusItem(
                  'Current Plan',
                  context.read<SubscriptionProvider>().getPlanName(
                    subscription?.plan ?? SubscriptionPlan.free,
                  ),
                  color: AppTheme.secondaryColor,
                ),
                _buildStatusItem(
                  'Member Since',
                  _formatDate(user?.memberSince ?? DateTime.now()),
                ),
                _buildStatusItem(
                  'Email Verified',
                  user?.emailVerified ?? false ? 'Yes' : 'No',
                  color: user?.emailVerified ?? false ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNotificationItem(
                  'Daily Reminders',
                  _dailyRemindersEnabled,
                  (value) {
                    setState(() {
                      _dailyRemindersEnabled = value;
                    });
                    _updateNotificationSettings();
                  },
                ),
                _buildTimePickerItem(
                  'Reminder Time',
                  _reminderTime,
                  () => _selectReminderTime(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (hasLoggedToday ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (hasLoggedToday ? Colors.green : Colors.orange).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasLoggedToday ? Icons.check_circle_outline : Icons.info_outline,
                        color: hasLoggedToday ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasLoggedToday
                              ? 'You already logged a transaction today'
                              : 'No transactions logged today',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageTab() {
    final subscription = context.watch<SubscriptionProvider>().subscription;

    if (subscription == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Current Usage Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Usage',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Resets ${_getNextResetDate()}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Usage Items
          _buildUsageItem(
            'Chat Messages',
            Icons.chat,
            Colors.blue,
            subscription.usage['chatMessages'] ?? 0,
            subscription.limits['chatMessages'] ?? 0,
          ),
          _buildUsageItem(
            'Image Entries',
            Icons.image,
            Colors.green,
            subscription.usage['imageEntries'] ?? 0,
            subscription.limits['imageEntries'] ?? 0,
          ),
          _buildUsageItem(
            'Voice Entries',
            Icons.mic,
            Colors.orange,
            subscription.usage['voiceEntries'] ?? 0,
            subscription.limits['voiceEntries'] ?? 0,
          ),
          _buildUsageItem(
            'AI Queries',
            Icons.auto_awesome,
            AppTheme.secondaryColor,
            subscription.usage['aiQueries'] ?? 0,
            subscription.limits['aiQueries'] ?? 0,
          ),
          const SizedBox(height: 24),

          // Usage Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Usage Tips',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Voice entries save time for quick expense logging\n'
                  '• Use image capture for receipts to track details\n'
                  '• AI queries help analyze spending patterns',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlansTab() {
    final currentPlan = context.watch<SubscriptionProvider>().subscription?.plan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Upgrade anytime to unlock more features',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Free Plan
          _buildPlanCard(
            plan: SubscriptionPlan.free,
            name: 'Free',
            price: 'Forever Free',
            color: AppTheme.primaryColor,
            features: [
              '60 Chat Messages / Month',
              '10 Image Entries / Month',
              '10 Voice Entries / Month',
              '3 Custom Categories',
              'Unlimited Manual Entries',
              'Data retention limit is 90 days',
              '10 AI Queries / Month',
              'Basic Daily Reminders',
              'Transaction Notifications',
            ],
            isActive: currentPlan == SubscriptionPlan.free,
          ),
          const SizedBox(height: 16),

          // Pro Plan
          _buildPlanCard(
            plan: SubscriptionPlan.pro,
            name: 'Pro',
            price: '\$5.99 / month',
            color: Colors.blue,
            features: [
              '250 Chat Messages / Month',
              '50 Image Entries / Month',
              '50 Voice Entries / month',
              '10 Custom Categories',
              'Unlimited Manual Entries',
              'Data retention limit is 180 days',
              '30 AI Queries / Month',
              'Smart Daily Reminders',
              'Budget Alert Notifications',
              'Weekly Financial Reports',
              'Achievement Badges',
              'Priority Support',
            ],
            isActive: currentPlan == SubscriptionPlan.pro,
            isRecommended: true,
          ),
          const SizedBox(height: 16),

          // Power User Plan
          _buildPlanCard(
            plan: SubscriptionPlan.powerUser,
            name: 'Power User',
            price: '\$12.99 / month',
            color: AppTheme.secondaryColor,
            features: [
              '1000 Chat Messages / month',
              '200 Image Entries / month',
              '200 Voice Entries / month',
              '25 Custom Categories',
              'Unlimited Manual Entries',
              'No data retention limit',
              'Data export in CSV format',
              '75 AI Queries / Month',
              'Advanced Analytics',
              'All Notification Features',
              'Custom Reminder Times',
              'Multiple Budget Alerts',
              'Financial Goal Tracking',
              'Premium Support',
            ],
            isActive: currentPlan == SubscriptionPlan.powerUser,
            subtitle: 'For Heavy Users',
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickProfileStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTimePickerItem(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time.format(context),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageItem(
    String label,
    IconData icon,
    Color color,
    int used,
    int limit,
  ) {
    final percentage = limit > 0 ? (used / limit) : 0.0;
    final isUnlimited = limit == -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      isUnlimited ? '$used used' : '$used / $limit used',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isUnlimited ? '∞' : '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  color: percentage > 0.8 ? Colors.red : color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isUnlimited) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.8 ? Colors.red : color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String name,
    required String price,
    required Color color,
    required List<String> features,
    required bool isActive,
    bool isRecommended = false,
    String? subtitle,
  }) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isActive ? null : () => _selectPlan(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.grey.shade300 : color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isActive ? 'Current Plan' : 'Select Plan',
                    style: TextStyle(
                      color: isActive ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getNextResetDate() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return '${_getMonthName(nextMonth.month)} 1';
  }

  String _getMonthName(int month) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _editProfile() {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    final imageUrlController = TextEditingController(text: user?.profileImageUrl ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Profile Image URL',
                                prefixIcon: Icon(Icons.image_outlined),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }

                                        setSheetState(() {
                                          isSaving = true;
                                        });

                                        final success = await userProvider.updateProfile(
                                          name: nameController.text.trim(),
                                          phoneNumber: phoneController.text.trim(),
                                          profileImageUrl: imageUrlController.text.trim().isEmpty
                                              ? null
                                              : imageUrlController.text.trim(),
                                        );

                                        if (!mounted) return;

                                        setSheetState(() {
                                          isSaving = false;
                                        });

                                        if (success) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Profile updated successfully'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            SnackBar(
                                              content: Text(userProvider.error.isNotEmpty
                                                  ? userProvider.error
                                                  : 'Failed to update profile'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(isSaving ? 'Saving...' : 'Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
      _updateNotificationSettings();
    }
  }

  Future<void> _updateNotificationSettings() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.updateNotificationSettings({
      'dailyReminders': _dailyRemindersEnabled,
      'reminderTime': '${_reminderTime.hour}:${_reminderTime.minute.toString().padLeft(2, '0')}',
      'budgetAlerts': true,
      'transactionNotifications': true,
    });

    await _syncDailyReminderNow();
  }

  Future<void> _syncDailyReminderNow() async {
    final transactions = context.read<TransactionProvider>().transactions;
    final now = DateTime.now();
    final hasLoggedToday = transactions.any((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day);

    await NotificationService.syncDailyTransactionReminder(
      enabled: _dailyRemindersEnabled,
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
      hasLoggedTransactionToday: hasLoggedToday,
    );
  }

  void _selectPlan(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to ${context.read<SubscriptionProvider>().getPlanName(plan)}'),
        content: Text(
          'Are you sure you want to upgrade to the ${context.read<SubscriptionProvider>().getPlanName(plan)} plan for \$${context.read<SubscriptionProvider>().getPlanPrice(plan)}/month?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SubscriptionProvider>().updateSubscriptionPlan(plan);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan updated successfully!')),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<UserProvider>().signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
