import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:chatapp/tax_profile_model.dart';
import 'reports_widgets.dart';

// Add the missing Recommendation class
class Recommendation {
  final String message;
  final IconData icon;
  final Color color;

  Recommendation(this.message, this.icon, this.color);
}

class ReportsAnalyticsTab extends StatelessWidget {
  final String userId;
  final DateTimeRange dateRange;
  final Map<String, double> expenseCategories;
  final Map<String, double> incomeCategories;
  final Map<String, double> dailySpending;
  final double totalExpenses;
  final double totalIncome;
  final double avgDailySpending;
  final BangladeshTaxProfile? taxProfile;
  final double estimatedTax;
  final AsyncSnapshot<QuerySnapshot> snapshot;

  const ReportsAnalyticsTab({
    super.key,
    required this.userId,
    required this.dateRange,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.dailySpending,
    required this.totalExpenses,
    required this.totalIncome,
    required this.avgDailySpending,
    required this.taxProfile,
    required this.estimatedTax,
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
        title: 'No analytics available',
        subtitle: 'Add transactions to see detailed analytics',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Spending Patterns
          _buildSpendingPatternsCard(),
          const SizedBox(height: 20),
          // Financial Health Score
          _buildFinancialHealthCard(),
          const SizedBox(height: 20),
          // Budget Recommendations
          _buildBudgetRecommendationsCard(),
          const SizedBox(height: 20),
          // Weekly Spending Chart
          if (dailySpending.isNotEmpty) _buildWeeklySpendingChart(),
        ],
      ),
    );
  }

  Widget _buildSpendingPatternsCard() {
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
                Icon(Icons.pattern_rounded, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Spending Patterns',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAnalyticsMetric(
              'Savings Rate',
              totalIncome > 0
                  ? '${((totalIncome - totalExpenses) / totalIncome * 100).toStringAsFixed(1)}%'
                  : '0%',
              totalIncome > totalExpenses ? Colors.green : Colors.red,
              Icons.savings_rounded,
            ),
            const SizedBox(height: 12),
            _buildAnalyticsMetric(
              'Expense Ratio',
              totalIncome > 0
                  ? '${(totalExpenses / totalIncome * 100).toStringAsFixed(1)}%'
                  : '0%',
              Colors.orange,
              Icons.pie_chart_rounded,
            ),
            const SizedBox(height: 12),
            _buildAnalyticsMetric(
              'Top Expense Category',
              expenseCategories.isNotEmpty
                  ? expenseCategories.entries
                      .reduce((a, b) => a.value > b.value ? a : b)
                      .key
                  : 'None',
              Colors.red,
              Icons.category_rounded,
            ),
            const SizedBox(height: 12),
            _buildAnalyticsMetric(
              'Daily Average Spend',
              '৳${avgDailySpending.toStringAsFixed(2)}',
              Colors.blue,
              Icons.today_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsMetric(
      String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHealthCard() {
    double healthScore = _calculateFinancialHealthScore();
    Color scoreColor = _getHealthScoreColor(healthScore);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scoreColor.withOpacity(0.1),
              scoreColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.health_and_safety_rounded, color: scoreColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: healthScore / 100,
                          backgroundColor: scoreColor.withOpacity(0.2),
                          color: scoreColor,
                          strokeWidth: 8,
                        ),
                        Text(
                          '${healthScore.toInt()}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${healthScore.toInt()}/100',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getHealthScoreLabel(healthScore),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getHealthScoreDescription(healthScore),
              style: const TextStyle(fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetRecommendationsCard() {
    final recommendations = _generateRecommendations();
    
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
                Icon(Icons.lightbulb_rounded, color: Colors.amber[600]),
                const SizedBox(width: 8),
                const Text(
                  'Smart Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recommendations.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Great! Your financial habits look healthy.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recommendations.map((recommendation) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: recommendation.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: recommendation.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(recommendation.icon,
                          color: recommendation.color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recommendation.message,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySpendingChart() {
    if (dailySpending.isEmpty) return const SizedBox();

    final sortedDays = dailySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    double maxSpending = dailySpending.values.isNotEmpty 
      ? dailySpending.values.reduce((a, b) => a > b ? a : b) 
      : 0;

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
                Icon(Icons.calendar_view_week_rounded, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                const Text(
                  'Last 7 Days Spending',
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
              child: BarChart(
                BarChartData(
                  barGroups: sortedDays.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final amount = entry.value.value;
                    
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          color: Colors.indigo[400],
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedDays.length) return const Text('');
                          final date = DateTime.parse(sortedDays[value.toInt()].key);
                          return Text(
                            DateFormat('E').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1000) {
                            return Text(
                              '৳${(value / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(fontSize: 10),
                            );
                          } else {
                            return Text(
                              '৳${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxSpending > 0 ? maxSpending / 4 : 1000,
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      // getTooltipColor: (group) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = DateTime.parse(sortedDays[group.x.toInt()].key);
                        return BarTooltipItem(
                          '${DateFormat('MMM dd').format(date)}\n৳${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  double _calculateFinancialHealthScore() {
    double score = 0;

    // Savings rate (40 points max)
    if (totalIncome > 0) {
      double savingsRate = (totalIncome - totalExpenses) / totalIncome;
      if (savingsRate >= 0.2) {
        score += 40;
      } else if (savingsRate >= 0.1) {
        score += 30;
      } else if (savingsRate >= 0.05) {
        score += 20;
      } else if (savingsRate >= 0) {
        score += 10;
      }
    }

    // Expense diversification (20 points max)
    if (expenseCategories.length >= 5) {
      score += 20;
    } else if (expenseCategories.length >= 3) {
      score += 15;
    } else if (expenseCategories.length >= 2) {
      score += 10;
    }

    // Income stability (20 points max)
    if (incomeCategories.isNotEmpty) {
      if (incomeCategories.length == 1) {
        score += 10; // Single income source
      } else if (incomeCategories.length >= 2) {
        score += 20; // Multiple income sources
      }
    }

    // Tax planning (20 points max)
    if (taxProfile != null) {
      score += 10;
      if (estimatedTax > 0) score += 10;
    }

    return score.clamp(0, 100);
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getHealthScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  String _getHealthScoreDescription(double score) {
    if (score >= 80) {
      return 'Your financial health is excellent! You\'re saving well and managing expenses effectively.';
    } else if (score >= 60) {
      return 'Good financial health! Consider increasing savings and diversifying income sources.';
    } else if (score >= 40) {
      return 'Fair financial health. Focus on reducing expenses and increasing savings rate.';
    } else {
      return 'Your financial health needs attention. Consider budgeting and expense tracking.';
    }
  }

  List<Recommendation> _generateRecommendations() {
    List<Recommendation> recommendations = [];

    // Savings rate recommendation
    if (totalIncome > 0) {
      double savingsRate = (totalIncome - totalExpenses) / totalIncome;
      if (savingsRate < 0.1) {
        recommendations.add(Recommendation(
          'Try to save at least 10% of your income. Consider reducing non-essential expenses.',
          Icons.savings_rounded,
          Colors.orange,
        ));
      }
    }

    // Top expense category recommendation
    if (expenseCategories.isNotEmpty && totalExpenses > 0) {
      final topExpense =
          expenseCategories.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topExpense.value / totalExpenses > 0.5) {
        recommendations.add(Recommendation(
          '${topExpense.key} takes up ${((topExpense.value / totalExpenses) * 100).toStringAsFixed(1)}% of your expenses. Consider ways to reduce this.',
          Icons.trending_down_rounded,
          Colors.red,
        ));
      }
    }

    // Tax optimization recommendation
    if (taxProfile == null) {
      recommendations.add(Recommendation(
        'Set up your tax profile to get personalized tax optimization advice.',
        Icons.account_balance_rounded,
        Colors.blue,
      ));
    }

    // Emergency fund recommendation
    double netBalance = totalIncome - totalExpenses;
    if (netBalance < totalExpenses && totalExpenses > 0) {
      recommendations.add(Recommendation(
        'Build an emergency fund covering 3-6 months of expenses for financial security.',
        Icons.security_rounded,
        Colors.purple,
      ));
    }

    return recommendations;
  }
}