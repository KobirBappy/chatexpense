import 'package:chatapp/theme_config.dart';
import 'package:chatapp/firebase_service.dart';
import 'package:chatapp/transaction_model.dart';
import 'package:chatapp/transaction_provider.dart';
import 'package:chatapp/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'All';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userId = context.read<UserProvider>().user?.id ??
        FirebaseService.currentUser?.uid;
    if (userId != null) {
      context.read<TransactionProvider>().loadTransactionsByDateRange(
            userId,
            _startDate,
            _endDate,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('AI Financial Dashboard'),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor),
            onPressed: _showAIInsights,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Tabs
            _buildFilterTabs(),
            const SizedBox(height: 16),

            // Report Period
            _buildReportPeriod(),
            const SizedBox(height: 20),

            // Financial Overview Cards
            _buildFinancialOverview(),
            const SizedBox(height: 24),

            // Quick Insights
            _buildQuickInsights(),
            const SizedBox(height: 24),

            // Monthly Trends Chart
            _buildMonthlyTrends(),
            const SizedBox(height: 24),

            // Expense Analysis
            _buildExpenseAnalysis(),
            const SizedBox(height: 24),

            // Income Analysis
            _buildIncomeAnalysis(),
            const SizedBox(height: 24),

            // Loan Analysis
            _buildEnhancedLoanAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['All', 'Expenses', 'Income', 'Loans'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedFilter == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tab),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = tab;
                });
                _applyFilter(tab);
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color:
                    isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportPeriod() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Period',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.expand_more, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.filteredTransactions;

    // Calculate loan details
    double totalLoanGiven = 0;
    double totalLoanReceived = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.loanGiven) {
        totalLoanGiven += transaction.amount;
      } else if (transaction.type == TransactionType.loanReceived) {
        totalLoanReceived += transaction.amount;
      }
    }

    final netLoanBalance = totalLoanReceived - totalLoanGiven;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 380;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isCompact ? 0.95 : 1.4,
              children: [
                _buildOverviewCard(
                  title: 'Total Income',
                  amount: provider.totalIncome,
                  icon: Icons.trending_up,
                  color: Colors.green,
                  period: 'This period',
                ),
                _buildOverviewCard(
                  title: 'Total Expenses',
                  amount: provider.totalExpenses,
                  icon: Icons.trending_down,
                  color: Colors.red,
                  period: 'This period',
                ),
                _buildOverviewCard(
                  title: 'Net Balance',
                  amount: provider.netBalance,
                  icon: Icons.account_balance_wallet,
                  color: provider.netBalance >= 0 ? Colors.green : Colors.red,
                  period: provider.netBalance >= 0 ? 'Surplus' : 'Deficit',
                ),
                _buildOverviewCard(
                  title: 'Net Loans',
                  amount: netLoanBalance.abs(),
                  icon: Icons.credit_card,
                  color: Colors.blue,
                  period: netLoanBalance > 0
                      ? 'You owe'
                      : netLoanBalance < 0
                          ? 'Others owe you'
                          : 'Balanced',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required String period,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '?${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            period,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights() {
    final provider = context.watch<TransactionProvider>();
    final savingsRate = provider.savingsRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome,
                color: AppTheme.secondaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Quick Insights',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: savingsRate >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.savings,
                  color: savingsRate >= 0 ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings Rate',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: savingsRate.abs() / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              savingsRate >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${savingsRate >= 0 ? '' : '-'}${savingsRate.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: savingsRate >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrends() {
    final trends = _getEnhancedMonthlyTrends();

    if (trends.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart,
                color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Monthly Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final chartHeight = constraints.maxWidth < 450 ? 220.0 : 300.0;
            return Container(
              padding: const EdgeInsets.all(16),
              height: chartHeight,
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
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < trends.length) {
                            final month =
                                trends[value.toInt()]['month'] as String;
                            return Text(
                              month.substring(5),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Income line
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['income'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    // Expenses line
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['expenses'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                    // Loans Given line
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['loansGiven'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                    // Loans Received line
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['loansReceived'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('Income', Colors.green, false),
            _buildLegendItem('Expenses', Colors.red, false),
            _buildLegendItem('Loans Given', Colors.orange, true),
            _buildLegendItem('Loans Received', Colors.blue, true),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildExpenseAnalysis() {
    final categories = context.watch<TransactionProvider>().categoryExpenses;
    final totalExpenses = context.watch<TransactionProvider>().totalExpenses;

    if (categories.isEmpty) {
      return const SizedBox();
    }

    // Sort categories by amount
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Analysis',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
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
            children: [
              // Pie Chart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sortedCategories.map((entry) {
                      final percentage = (entry.value / totalExpenses * 100);
                      return PieChartSectionData(
                        value: entry.value,
                        title: percentage >= 5
                            ? '${percentage.toStringAsFixed(0)}%'
                            : '',
                        color: _getCategoryColor(entry.key),
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Category List
              ...sortedCategories.take(5).map((entry) {
                final percentage = (entry.value / totalExpenses * 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '?${entry.value.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeAnalysis() {
    final transactions =
        context.watch<TransactionProvider>().filteredTransactions;
    final incomeTransactions =
        transactions.where((t) => t.type == TransactionType.income).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income Analysis',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
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
          child: incomeTransactions.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No income found',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: incomeTransactions.take(5).map((transaction) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.attach_money, color: Colors.white),
                      ),
                      title: Text(transaction.description),
                      subtitle: Text(_formatDate(transaction.date)),
                      trailing: Text(
                        '+?${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLoanAnalysis() {
    final transactions =
        context.watch<TransactionProvider>().filteredTransactions;
    final loanGivenTransactions =
        transactions.where((t) => t.type == TransactionType.loanGiven).toList();
    final loanReceivedTransactions = transactions
        .where((t) => t.type == TransactionType.loanReceived)
        .toList();

    final totalLoanGiven =
        loanGivenTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalLoanReceived =
        loanReceivedTransactions.fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.credit_card,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loan Analysis',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary Cards
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 320,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(
                      'Money Lent',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '?${totalLoanGiven.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      '${loanGivenTransactions.length} transactions',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 320,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Money Borrowed',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '?${totalLoanReceived.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      '${loanReceivedTransactions.length} transactions',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Net Position
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Loan Position',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (totalLoanReceived - totalLoanGiven) > 0
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (totalLoanReceived - totalLoanGiven) > 0
                          ? 'You owe'
                          : (totalLoanReceived - totalLoanGiven) < 0
                              ? 'Others owe you'
                              : 'Balanced',
                      style: TextStyle(
                        color: (totalLoanReceived - totalLoanGiven) > 0
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '?${(totalLoanReceived - totalLoanGiven).abs().toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: (totalLoanReceived - totalLoanGiven) > 0
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Loan Transactions
        if (loanGivenTransactions.isNotEmpty ||
            loanReceivedTransactions.isNotEmpty)
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
                  'Recent Loan Transactions',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...([...loanGivenTransactions, ...loanReceivedTransactions]
                      ..sort((a, b) => b.date.compareTo(a.date)))
                    .take(5)
                    .map((transaction) {
                  final isLoanGiven =
                      transaction.type == TransactionType.loanGiven;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLoanGiven
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      child: Icon(
                        isLoanGiven ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isLoanGiven ? Colors.orange : Colors.blue,
                      ),
                    ),
                    title: Text(transaction.description),
                    subtitle: Text(
                      '${isLoanGiven ? "Lent" : "Borrowed"} • ${_formatDate(transaction.date)}',
                    ),
                    trailing: Text(
                      '?${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isLoanGiven ? Colors.orange : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _getEnhancedMonthlyTrends() {
    final transactions = context.read<TransactionProvider>().transactions;
    final Map<String, Map<String, double>> monthlyData = {};

    for (final transaction in transactions) {
      final monthKey =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'income': 0,
          'expenses': 0,
          'loansGiven': 0,
          'loansReceived': 0,
        };
      }

      switch (transaction.type) {
        case TransactionType.income:
          monthlyData[monthKey]!['income'] =
              (monthlyData[monthKey]!['income'] ?? 0) + transaction.amount;
          break;
        case TransactionType.expense:
          monthlyData[monthKey]!['expenses'] =
              (monthlyData[monthKey]!['expenses'] ?? 0) + transaction.amount;
          break;
        case TransactionType.loanGiven:
          monthlyData[monthKey]!['loansGiven'] =
              (monthlyData[monthKey]!['loansGiven'] ?? 0) + transaction.amount;
          break;
        case TransactionType.loanReceived:
          monthlyData[monthKey]!['loansReceived'] =
              (monthlyData[monthKey]!['loansReceived'] ?? 0) +
                  transaction.amount;
          break;
      }
    }

    final sortedMonths = monthlyData.keys.toList()..sort();

    return sortedMonths
        .map((month) => {
              'month': month,
              'income': monthlyData[month]!['income'] ?? 0,
              'expenses': monthlyData[month]!['expenses'] ?? 0,
              'loansGiven': monthlyData[month]!['loansGiven'] ?? 0,
              'loansReceived': monthlyData[month]!['loansReceived'] ?? 0,
            })
        .toList();
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Shopping': Colors.purple,
      'Bills': Colors.red,
      'Entertainment': Colors.pink,
      'Healthcare': Colors.teal,
      'Education': Colors.indigo,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  void _applyFilter(String filter) {
    final provider = context.read<TransactionProvider>();

    switch (filter) {
      case 'All':
        provider.filterTransactionsByType(null);
        break;
      case 'Expenses':
        provider.filterTransactionsByType(TransactionType.expense);
        break;
      case 'Income':
        provider.filterTransactionsByType(TransactionType.income);
        break;
      case 'Loans':
        // Provider does not support a combined loan filter yet.
        // Keep all data loaded; loan-specific widgets already segment loan types.
        provider.filterTransactionsByType(null);
        break;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  void _showAIInsights() {
    final provider = context.read<TransactionProvider>();
    final netLoans = provider.loanBalance;
    final topCategory = provider.categoryExpenses.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'AI Financial Insights',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInsightCard(
                    'Spending Pattern',
                    'Your expenses have increased by 15% this month compared to last month.',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                  _buildInsightCard(
                    'Top Category',
                    '${topCategory.key} accounts for ${(topCategory.value / provider.totalExpenses * 100).toStringAsFixed(0)}% of your total expenses. Consider budgeting for this category.',
                    Icons.restaurant,
                    Colors.red,
                  ),
                  if (provider.savingsRate > 0)
                    _buildInsightCard(
                      'Savings Opportunity',
                      'Great job! You\'re saving ${provider.savingsRate.toStringAsFixed(1)}% of your income. Consider investing this surplus.',
                      Icons.savings,
                      Colors.green,
                    ),
                  if (netLoans != 0)
                    _buildInsightCard(
                      'Loan Status',
                      netLoans > 0
                          ? 'You currently owe ?${netLoans.abs().toStringAsFixed(2)} in loans. Consider creating a repayment plan.'
                          : 'Others owe you ?${netLoans.abs().toStringAsFixed(2)}. Set reminders to follow up on repayments.',
                      Icons.credit_card,
                      netLoans > 0 ? Colors.red : Colors.blue,
                    ),
                  _buildInsightCard(
                    'Monthly Budget',
                    'Based on your spending patterns, consider setting a monthly budget of ?${(provider.totalExpenses * 1.1).toStringAsFixed(0)} to allow for savings.',
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    title,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
