import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'reports_widgets.dart';

class ReportsExpensesTab extends StatelessWidget {
  final String userId;
  final DateTimeRange dateRange;
  final Map<String, double> expenseCategories;
  final double totalExpenses;
  final AsyncSnapshot<QuerySnapshot> snapshot;

  const ReportsExpensesTab({
    super.key,
    required this.userId,
    required this.dateRange,
    required this.expenseCategories,
    required this.totalExpenses,
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

    return _buildCategoryAnalysisTab(
      categories: expenseCategories,
      total: totalExpenses,
      color: Colors.red,
      title: 'Expense Analysis',
      emptyIcon: Icons.money_off_rounded,
      emptyText: 'No expenses found',
      emptySubtext: 'Add some expense transactions to see analysis',
    );
  }

  Widget _buildCategoryAnalysisTab({
    required Map<String, double> categories,
    required double total,
    required Color color,
    required String title,
    required IconData emptyIcon,
    required String emptyText,
    required String emptySubtext,
  }) {
    if (categories.isEmpty) {
      return ReportsWidgets.buildEmptyState(
        icon: emptyIcon,
        title: emptyText,
        subtitle: emptySubtext,
      );
    }

    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Pie Chart
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: ReportsWidgets.buildEnhancedPieSections(
                            categories, total, color),
                        sectionsSpace: 3,
                        centerSpaceRadius: 60,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ReportsWidgets.buildEnhancedLegend(categories, total),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Category Breakdown
          ...sortedCategories.map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ReportsWidgets.getCategoryIcon(entry.key),
                    color: color,
                  ),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: total > 0 ? entry.value / total : 0,
                      backgroundColor: color.withOpacity(0.1),
                      color: color,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text('${percentage.toStringAsFixed(1)}% of total'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}