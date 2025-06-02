import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:chatapp/tax_profile_model.dart';
import 'reports_widgets.dart';

class ReportsOverviewTab extends StatelessWidget {
  final String userId;
  final DateTimeRange dateRange;
  final VoidCallback onShowDatePicker;
  final Map<String, double> monthlyExpenses;
  final Map<String, double> monthlyIncome;
  final Map<String, double> dailySpending;
  final double avgDailySpending;
  final double projectedMonthlySpending;
  final BangladeshTaxProfile? taxProfile;
  final double estimatedTax;
  final double totalExpenses;
  final double totalIncome;
  final double netBalance;
  final Map<String, double> expenseCategories;
  final Map<String, double> incomeCategories;
  final AsyncSnapshot<QuerySnapshot> snapshot;

  const ReportsOverviewTab({
    super.key,
    required this.userId,
    required this.dateRange,
    required this.onShowDatePicker,
    required this.monthlyExpenses,
    required this.monthlyIncome,
    required this.dailySpending,
    required this.avgDailySpending,
    required this.projectedMonthlySpending,
    required this.taxProfile,
    required this.estimatedTax,
    required this.totalExpenses,
    required this.totalIncome,
    required this.netBalance,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    // Show empty state if no transactions
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return ReportsWidgets.buildEmptyState(
        icon: Icons.analytics_outlined,
        title: 'No transactions found',
        subtitle: 'Add some transactions to see your reports',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportsWidgets.buildDateRangeCard(dateRange, onShowDatePicker),
          const SizedBox(height: 16),
          _buildFinancialSummaryCards(),
          const SizedBox(height: 20),
          _buildQuickInsights(),
          const SizedBox(height: 20),
          ReportsWidgets.buildTaxInsightsCard(context, taxProfile, estimatedTax),
          const SizedBox(height: 20),
          _buildSpendingTrendsCard(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: ReportsWidgets.buildSummaryCard(
            title: 'Total Income',
            amount: totalIncome,
            icon: Icons.trending_up_rounded,
            color: Colors.green,
            subtitle: 'This period',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ReportsWidgets.buildSummaryCard(
            title: 'Total Expenses',
            amount: totalExpenses,
            icon: Icons.trending_down_rounded,
            color: Colors.red,
            subtitle: 'This period',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Quick Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ReportsWidgets.buildInsightRow(
              'Net Balance',
              '৳${netBalance.toStringAsFixed(2)}',
              netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
              netBalance >= 0 ? Colors.green : Colors.red,
            ),
            const Divider(),
            ReportsWidgets.buildInsightRow(
              'Avg Daily Spending',
              '৳${avgDailySpending.toStringAsFixed(2)}',
              Icons.receipt_long_rounded,
              Colors.orange,
            ),
            const Divider(),
            ReportsWidgets.buildInsightRow(
              'Projected Monthly',
              '৳${projectedMonthlySpending.toStringAsFixed(2)}',
              Icons.calendar_month_rounded,
              Colors.blue,
            ),
            if (estimatedTax > 0) ...[
              const Divider(),
              ReportsWidgets.buildInsightRow(
                'Est. Annual Tax',
                '৳${estimatedTax.toStringAsFixed(2)}',
                Icons.account_balance_rounded,
                Colors.deepPurple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendsCard() {
    if (monthlyExpenses.isEmpty && monthlyIncome.isEmpty) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Monthly Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toInt()}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = monthlyExpenses.keys.toList();
                          if (value.toInt() >= months.length) {
                            return const Text('');
                          }
                          return Text(
                            months[value.toInt()],
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
                    // Expenses line
                    LineChartBarData(
                      spots: monthlyExpenses.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.red[400],
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                    // Income line
                    LineChartBarData(
                      spots: monthlyIncome.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green[400],
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ReportsWidgets.buildLegendItem('Income', Colors.green[400]!),
                const SizedBox(width: 20),
                ReportsWidgets.buildLegendItem('Expenses', Colors.red[400]!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}