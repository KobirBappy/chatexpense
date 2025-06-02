// // reports_screen.dart
// import 'package:chatapp/tax_calculator.dart';
// import 'package:chatapp/tax_profile_model.dart';
// import 'package:chatapp/tax_profile_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';

// class ReportsScreen extends StatefulWidget {
//   const ReportsScreen({super.key});

//   @override
//   State<ReportsScreen> createState() => _ReportsScreenState();
// }

// class _ReportsScreenState extends State<ReportsScreen> {
//   Map<String, double> expenseCategories = {};
//   Map<String, double> incomeCategories = {};
//   Map<String, double> monthlyExpenses = {};
//   Map<String, double> monthlyIncome = {};

//   double totalExpenses = 0;
//   double totalIncome = 0;
//   double netBalance = 0;

//   // Add to _ReportsScreenState class
// BangladeshTaxProfile? _taxProfile;
// double _estimatedTax = 0;

// Future<void> _loadTaxProfile() async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) return;

//   try {
//     final doc = await FirebaseFirestore.instance
//         .collection('taxProfiles')
//         .doc(user.uid)
//         .get();

//     if (doc.exists) {
//       setState(() {
//         _taxProfile = BangladeshTaxProfile.fromJson(doc.data()!);
//         _estimatedTax = BangladeshTaxCalculator.calculateTax(_taxProfile!);
//       });
//     }
//   } catch (e) {
//     print("Error loading tax profile: $e");
//   }
// }

//   DateTimeRange _dateRange = DateTimeRange(
//     start: DateTime.now().subtract(const Duration(days: 30)),
//     end: DateTime.now(),
//   );
//   int _activeTab = 0; // 0 = Summary, 1 = Expenses, 2 = Income

// @override
// void initState() {
//   super.initState();
//   _loadHistoricalData();
//   _loadTaxProfile();
// }

//   Future<void> _loadHistoricalData() async {
//     setState(() {
//     });

//     try {
//       // Load historical data for bar chart
//       final now = DateTime.now();
//       final historicalExpenses = <String, double>{};
//       final historicalIncome = <String, double>{};

//       for (int i = 5; i >= 0; i--) {
//         final month = now.month - i;
//         final year = now.year + (month <= 0 ? -1 : 0);
//         final adjustedMonth = month <= 0 ? month + 12 : month;

//         final monthStart = DateTime(year, adjustedMonth, 1);
//         final monthEnd = DateTime(year, adjustedMonth + 1, 1).subtract(const Duration(days: 1));

//         final monthKey = DateFormat('MMM yyyy').format(monthStart);

//         final monthSnapshot = await FirebaseFirestore.instance
//             .collection('transactions')
//             .where('date', isGreaterThanOrEqualTo: monthStart)
//             .where('date', isLessThanOrEqualTo: monthEnd)
//             .get();

//         double monthExpenses = 0;
//         double monthIncome = 0;

//         for (var doc in monthSnapshot.docs) {
//           final data = doc.data();
//           final amount = (data['amount'] as num).toDouble();

//           if (amount < 0) {
//             monthExpenses += amount.abs();
//           } else {
//             monthIncome += amount;
//           }
//         }

//         historicalExpenses[monthKey] = monthExpenses;
//         historicalIncome[monthKey] = monthIncome;
//       }

//       setState(() {
//         monthlyExpenses = historicalExpenses;
//         monthlyIncome = historicalIncome;
//       });
//     } catch (e) {
//       setState(() {
//       });
//     }
//   }

//   Widget _buildDateRangeSelector() {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: ListTile(
//         leading: const Icon(Icons.calendar_today),
//         title: Text(
//           '${DateFormat('MMM dd, yyyy').format(_dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange.end)}',
//           style: const TextStyle(fontSize: 16),
//         ),
//         trailing: const Icon(Icons.arrow_drop_down),
//         onTap: () => _showDatePicker(),
//       ),
//     );
//   }

//   Future<void> _showDatePicker() async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       initialDateRange: _dateRange,
//     );

//     if (picked != null) {
//       setState(() => _dateRange = picked);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Financial Reports"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadHistoricalData,
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildDateRangeSelector(),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('transactions')
//                   .where('date', isGreaterThanOrEqualTo: _dateRange.start)
//                   .where('date', isLessThanOrEqualTo: _dateRange.end)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('No transactions found'));
//                 }

//                 // Reset values
//                 expenseCategories.clear();
//                 incomeCategories.clear();
//                 totalExpenses = 0;
//                 totalIncome = 0;
//                 netBalance = 0;

//                 // Process transactions
//                 for (var doc in snapshot.data!.docs) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final amount = (data['amount'] as num?)?.toDouble() ?? 0;
//                   final category = data['category'] as String? ?? 'Uncategorized';
//                   final type = data['type'] as String? ?? 'expense';

//                   if (amount < 0 || type == 'expense') {
//                     final absAmount = amount.abs();
//                     totalExpenses += absAmount;
//                     expenseCategories[category] = (expenseCategories[category] ?? 0) + absAmount;
//                   } else {
//                     totalIncome += amount;
//                     incomeCategories[category] = (incomeCategories[category] ?? 0) + amount;
//                   }
//                 }

//                 netBalance = totalIncome - totalExpenses;

//                 return Column(
//                   children: [
//                     // Summary Cards
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
//                       child: Row(
//                         children: [
//                           // Income Card
//                           Expanded(
//                             child: _buildSummaryCard(
//                               title: 'Income',
//                               value: totalIncome,
//                               color: Colors.green,
//                               icon: Icons.arrow_upward,
//                             ),
//                           ),
//                           const SizedBox(width: 5),
//                           // Expense Card
//                           Expanded(
//                             child: _buildSummaryCard(
//                               title: 'Expenses',
//                               value: totalExpenses,
//                               color: Colors.red,
//                               icon: Icons.arrow_downward,
//                             ),
//                           ),
//                           const SizedBox(width: 5),
//                           // Net Balance Card
//                           Expanded(
//                             child: _buildSummaryCard(
//                               title: 'Balance',
//                               value: netBalance,
//                               color: netBalance >= 0 ? Colors.green : Colors.red,
//                               icon: netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // Tab Selector
//                     SizedBox(
//                       height: 50,
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: _ReportTab(
//                               label: 'Summary',
//                               icon: Icons.pie_chart,
//                               isActive: _activeTab == 0,
//                               onTap: () => setState(() => _activeTab = 0),
//                             ),
//                           ),
//                           Expanded(
//                             child: _ReportTab(
//                               label: 'Expenses',
//                               icon: Icons.money_off,
//                               isActive: _activeTab == 1,
//                               onTap: () => setState(() => _activeTab = 1),
//                             ),
//                           ),
//                           Expanded(
//                             child: _ReportTab(
//                               label: 'Income',
//                               icon: Icons.attach_money,
//                               isActive: _activeTab == 2,
//                               onTap: () => setState(() => _activeTab = 2),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Divider(height: 1),

//                     // Tab Content
//                     Expanded(
//                       child: _activeTab == 0
//                           ? _buildSummaryTab()
//                           : _activeTab == 1
//                               ? _buildExpensesTab()
//                               : _buildIncomeTab(),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Add this widget to your build method
// Widget _buildTaxInsights() {
//   if (_taxProfile == null) return const SizedBox();

//   return Card(
//     margin: const EdgeInsets.all(16),
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Tax Insights",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           _buildTaxRow('Estimated Annual Tax', _estimatedTax),
//           _buildTaxRow('Monthly Tax', _estimatedTax / 12),
//           const SizedBox(height: 10),
//           const Text(
//             "Tax Saving Opportunities",
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 5),
//           ...BangladeshTaxCalculator.getTaxSlabs().entries.map((entry) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 2),
//               child: Row(
//                 children: [
//                   Expanded(child: Text(entry.key)),
//                   Text(entry.value),
//                 ],
//               ),
//             );
//           }),
//           const SizedBox(height: 10),
//           ElevatedButton(
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const TaxProfileScreen(),
//               ),
//             ),
//             child: const Text("Update Tax Profile"),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// Widget _buildTaxRow(String label, double value) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 6),
//     child: Row(
//       children: [
//         Expanded(
//           child: Text(
//             label,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ),
//         Text(
//           '৳${value.toStringAsFixed(2)}',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: value > 0 ? Colors.red : Colors.green,
//           ),
//         ),
//       ],
//     ),
//   );
// }

//   Widget _buildSummaryCard({required String title, required double value, required Color color, required IconData icon}) {
//     return Card(
//       color: color.withOpacity(0.1),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color, size: 18),
//                 const SizedBox(width: 5),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: color,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '৳${value.toStringAsFixed(2)}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryTab() {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         // Expense Breakdown
//         _buildCategorySection(
//           title: 'Expense Breakdown',
//           categories: expenseCategories,
//           total: totalExpenses,
//           color: Colors.red,
//         ),

//         const SizedBox(height: 20),

//         // Income Breakdown
//         _buildCategorySection(
//           title: 'Income Sources',
//           categories: incomeCategories,
//           total: totalIncome,
//           color: Colors.green,
//         ),

//         const SizedBox(height: 20),

//         // Monthly Trends
//         _buildMonthlyTrends(),
//       ],
//     );
//   }

//  Widget _buildCategorySection({
//   required String title,
//   required Map<String, double> categories,
//   required double total,
//   required Color color,
// }) {
//   final sortedCategories = categories.entries.toList()
//     ..sort((a, b) => b.value.compareTo(a.value));

//   return Card(
//     elevation: 2,
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           ...sortedCategories.map((entry) {
//             final percentage = (entry.value / total) * 100;
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 6),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       entry.key,
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                   Text(
//                     '৳${entry.value.toStringAsFixed(2)}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(width: 10),
//                   SizedBox(
//                     width: 80,
//                     child: LinearProgressIndicator(
//                       value: entry.value / total,
//                       backgroundColor: color.withOpacity(0.2),
//                       color: color,
//                       minHeight: 8,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     '${percentage.toStringAsFixed(1)}%',
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     ),
//   );
// }

//   Widget _buildMonthlyTrends() {
//     final months = monthlyExpenses.keys.toList();

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Monthly Trends',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             SizedBox(
//               height: 200,
//               child: BarChart(
//                 BarChartData(
//                   barGroups: months.asMap().entries.map((entry) {
//                     final idx = entry.key;
//                     final month = entry.value;
//                     final expenses = monthlyExpenses[month] ?? 0;
//                     final income = monthlyIncome[month] ?? 0;

//                     return BarChartGroupData(
//                       x: idx,
//                       groupVertically: true,
//                       barRods: [
//                         BarChartRodData(
//                           toY: expenses,
//                           color: Colors.red,
//                           width: 12,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                         BarChartRodData(
//                           toY: income,
//                           color: Colors.green,
//                           width: 12,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ],
//                     );
//                   }).toList(),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           return Padding(
//                             padding: const EdgeInsets.only(top: 8),
//                             child: Text(
//                               months[value.toInt()],
//                               style: const TextStyle(fontSize: 10),
//                             ),
//                           );
//                         },
//                         reservedSize: 40,
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 40,
//                         getTitlesWidget: (value, meta) {
//                           return Text(
//                             '৳${value.toInt()}',
//                             style: const TextStyle(fontSize: 10),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                   gridData: const FlGridData(show: true),
//                   borderData: FlBorderData(show: false),
//                   barTouchData: BarTouchData(
//                     touchTooltipData: BarTouchTooltipData(
//                       tooltipBgColor: Colors.blueGrey,
//                       getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                         final isExpense = rodIndex == 0;
//                         final value = rod.toY;

//                         return BarTooltipItem(
//                           '${isExpense ? 'Expense' : 'Income'}: ৳${value.toStringAsFixed(2)}',
//                           const TextStyle(color: Colors.white),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildLegendItem('Expense', Colors.red),
//                 const SizedBox(width: 20),
//                 _buildLegendItem('Income', Colors.green),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLegendItem(String text, Color color) {
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           color: color,
//         ),
//         const SizedBox(width: 5),
//         Text(
//           text,
//           style: const TextStyle(fontSize: 12),
//         ),
//       ],
//     );
//   }

//   Widget _buildExpensesTab() {
//     final sortedCategories = expenseCategories.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         Text(
//           'Expense Analysis',
//           style: Theme.of(context).textTheme.titleLarge,
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 20),

//         // Expense Pie Chart
//         Card(
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 SizedBox(
//                   height: 200,
//                   child: PieChart(
//                     PieChartData(
//                       sections: _buildPieSections(expenseCategories, totalExpenses),
//                       sectionsSpace: 2,
//                       centerSpaceRadius: 50,
//                       startDegreeOffset: -90,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 _buildLegend(expenseCategories, totalExpenses),
//               ],
//             ),
//           ),
//         ),

//         const SizedBox(height: 20),

//         // Expense Details
//         ...sortedCategories.map((entry) {
//           final percentage = (entry.value / totalExpenses) * 100;
//           return Card(
//             margin: const EdgeInsets.only(bottom: 10),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.red.withOpacity(0.2),
//                 child: Text(
//                   entry.key[0],
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               title: Text(entry.key),
//               subtitle: LinearProgressIndicator(
//                 value: entry.value / totalExpenses,
//                 backgroundColor: Colors.red.withOpacity(0.1),
//                 color: Colors.red,
//               ),
//               trailing: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     '৳${entry.value.toStringAsFixed(2)}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   Text(
//                     '${percentage.toStringAsFixed(1)}%',
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildIncomeTab() {
//     final sortedCategories = incomeCategories.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         Text(
//           'Income Analysis',
//           style: Theme.of(context).textTheme.titleLarge,
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 20),

//         // Income Pie Chart
//         Card(
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 SizedBox(
//                   height: 200,
//                   child: PieChart(
//                     PieChartData(
//                       sections: _buildPieSections(incomeCategories, totalIncome),
//                       sectionsSpace: 2,
//                       centerSpaceRadius: 50,
//                       startDegreeOffset: -90,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 _buildLegend(incomeCategories, totalIncome),
//               ],
//             ),
//           ),
//         ),

//         const SizedBox(height: 20),

//         // Income Details
//         ...sortedCategories.map((entry) {
//           final percentage = (entry.value / totalIncome) * 100;
//           return Card(
//             margin: const EdgeInsets.only(bottom: 10),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.green.withOpacity(0.2),
//                 child: Text(
//                   entry.key[0],
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               title: Text(entry.key),
//               subtitle: LinearProgressIndicator(
//                 value: entry.value / totalIncome,
//                 backgroundColor: Colors.green.withOpacity(0.1),
//                 color: Colors.green,
//               ),
//               trailing: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     '৳${entry.value.toStringAsFixed(2)}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   Text(
//                     '${percentage.toStringAsFixed(1)}%',
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   List<PieChartSectionData> _buildPieSections(Map<String, double> categories, double total) {
//     if (categories.isEmpty) return [];

//     final colors = [
//       Colors.blue,
//       Colors.redAccent,
//       Colors.green,
//       Colors.orange,
//       Colors.purple,
//       Colors.cyan,
//       Colors.amber,
//       Colors.deepOrange,
//       Colors.lightGreen,
//       Colors.pink,
//     ];

//     int i = 0;
//     return categories.entries.map((entry) {
//       final percentage = (entry.value / total) * 100;
//       return PieChartSectionData(
//         color: colors[i++ % colors.length],
//         value: entry.value,
//         title: "${percentage.toStringAsFixed(1)}%",
//         radius: 20,
//         titleStyle: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           color: Colors.white
//         ),
//       );
//     }).toList();
//   }

//   Widget _buildLegend(Map<String, double> categories, double total) {
//     final sortedCategories = categories.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return Wrap(
//       spacing: 10,
//       runSpacing: 10,
//       children: sortedCategories.asMap().entries.map((entry) {
//         final idx = entry.key;
//         final category = entry.value;
//         final percentage = (category.value / total) * 100;

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.primaries[idx % Colors.primaries.length].withOpacity(0.1),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 10,
//                 height: 10,
//                 color: Colors.primaries[idx % Colors.primaries.length],
//               ),
//               const SizedBox(width: 5),
//               Text(
//                 category.key,
//                 style: const TextStyle(fontSize: 12),
//               ),
//               const SizedBox(width: 5),
//               Text(
//                 '(${percentage.toStringAsFixed(1)}%)',
//                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// class _ReportTab extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final bool isActive;
//   final VoidCallback onTap;

//   const _ReportTab({
//     required this.label,
//     required this.icon,
//     required this.isActive,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.blue : Colors.transparent,
//               width: 3,
//             ),
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: isActive ? Colors.blue : Colors.grey),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isActive ? Colors.blue : Colors.grey,
//                 fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




// import 'package:chatapp/tax_calculator.dart';
// import 'package:chatapp/tax_profile_model.dart';
// import 'package:chatapp/tax_profile_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';

// class ReportsScreen extends StatefulWidget {
//   const ReportsScreen({super.key});

//   @override
//   State<ReportsScreen> createState() => _ReportsScreenState();
// }

// class _ReportsScreenState extends State<ReportsScreen>
//     with TickerProviderStateMixin {
//   TabController? _tabController;
//   AnimationController? _animationController;
//   Animation<double>? _fadeAnimation;

//   Map<String, double> expenseCategories = {};
//   Map<String, double> incomeCategories = {};
//   Map<String, double> monthlyExpenses = {};
//   Map<String, double> monthlyIncome = {};
//   Map<String, double> dailySpending = {};

//   double totalExpenses = 0;
//   double totalIncome = 0;
//   double netBalance = 0;
//   double avgDailySpending = 0;
//   double projectedMonthlySpending = 0;

//   // Tax profile data
//   BangladeshTaxProfile? _taxProfile;
//   double _estimatedTax = 0;

//   // Get current user ID - same pattern as transactions screen
//   String? get userId => FirebaseAuth.instance.currentUser?.uid;

//   DateTimeRange _dateRange = DateTimeRange(
//     start: DateTime.now().subtract(const Duration(days: 30)),
//     end: DateTime.now(),
//   );

//   // Predefined date ranges
//   final List<DateRangeOption> _dateRangeOptions = [
//     DateRangeOption('Last 7 Days',
//         DateTime.now().subtract(const Duration(days: 7)), DateTime.now()),
//     DateRangeOption('Last 30 Days',
//         DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
//     DateRangeOption('Last 3 Months',
//         DateTime.now().subtract(const Duration(days: 90)), DateTime.now()),
//     DateRangeOption('Last 6 Months',
//         DateTime.now().subtract(const Duration(days: 180)), DateTime.now()),
//     DateRangeOption(
//         'This Year', DateTime(DateTime.now().year, 1, 1), DateTime.now()),
//   ];

//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
//     );

//     if (userId != null) {
//       _loadData();
//     }
//   }

//   @override
//   void dispose() {
//     _tabController?.dispose();
//     _animationController?.dispose();
//     super.dispose();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     await Future.wait([
//       _loadHistoricalData(),
//       _loadTaxProfile(),
//       _calculateDailySpending(),
//     ]);
//     setState(() => _isLoading = false);
//     _animationController?.forward();
//   }

//   Future<void> _loadTaxProfile() async {
//     if (userId == null) return;

//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('taxProfiles')
//           .doc(userId!)
//           .get();

//       if (doc.exists && doc.data() != null) {
//         setState(() {
//           _taxProfile = BangladeshTaxProfile.fromJson(doc.data()!);
//           _estimatedTax = BangladeshTaxCalculator.calculateTax(_taxProfile!);
//         });
//       }
//     } catch (e) {
//       print("Error loading tax profile: $e");
//     }
//   }

//   Future<void> _loadHistoricalData() async {
//     if (userId == null) return;

//     try {
//       final now = DateTime.now();
//       final historicalExpenses = <String, double>{};
//       final historicalIncome = <String, double>{};

//       for (int i = 11; i >= 0; i--) {
//         final month = now.month - i;
//         final year = now.year + (month <= 0 ? -1 : 0);
//         final adjustedMonth = month <= 0 ? month + 12 : month;

//         final monthStart = DateTime(year, adjustedMonth, 1);
//         final monthEnd = DateTime(year, adjustedMonth + 1, 1)
//             .subtract(const Duration(days: 1));

//         final monthKey = DateFormat('MMM').format(monthStart);

//         final monthSnapshot = await FirebaseFirestore.instance
//             .collection('transactions')
//             .where('userId', isEqualTo: userId!)
//             .where('date', isGreaterThanOrEqualTo: monthStart)
//             .where('date', isLessThanOrEqualTo: monthEnd)
//             .get();

//         double monthExpenses = 0;
//         double monthIncome = 0;

//         for (var doc in monthSnapshot.docs) {
//           final data = doc.data();
//           final amount = (data['amount'] as num).toDouble();

//           // Match transaction screen logic
//           if (amount < 0) {
//             monthExpenses += amount.abs();
//           } else {
//             monthIncome += amount;
//           }
//         }

//         historicalExpenses[monthKey] = monthExpenses;
//         historicalIncome[monthKey] = monthIncome;
//       }

//       setState(() {
//         monthlyExpenses = historicalExpenses;
//         monthlyIncome = historicalIncome;
//       });
//     } catch (e) {
//       print("Error loading historical data: $e");
//     }
//   }

//   Future<void> _calculateDailySpending() async {
//     if (userId == null) return;

//     try {
//       final last7Days = DateTime.now().subtract(const Duration(days: 7));
//       final snapshot = await FirebaseFirestore.instance
//           .collection('transactions')
//           .where('userId', isEqualTo: userId!)
//           .where('date', isGreaterThanOrEqualTo: last7Days)
//           .where('date', isLessThanOrEqualTo: DateTime.now())
//           .get();

//       double totalSpent = 0;
//       int days = 0;
//       final Map<String, double> dailyTotals = {};

//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         final amount = (data['amount'] as num).toDouble();
//         final date = (data['date'] as Timestamp).toDate();
//         final dayKey = DateFormat('yyyy-MM-dd').format(date);

//         // Match transaction screen logic for expenses
//         if (amount < 0) {
//           totalSpent += amount.abs();
//           dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + amount.abs();
//         }
//       }

//       days = dailyTotals.length;

//       setState(() {
//         dailySpending = dailyTotals;
//         avgDailySpending = days > 0 ? totalSpent / days : 0;
//         projectedMonthlySpending = avgDailySpending * 30;
//       });
//     } catch (e) {
//       print("Error calculating daily spending: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Check authentication - same pattern as transactions screen
//     if (userId == null) {
//       return const Scaffold(
//         body: Center(
//           child: Text('Please log in to view transactions'),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           "Financial Dashboard",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh_rounded),
//             onPressed: _loadData,
//           ),
//           PopupMenuButton<DateRangeOption>(
//             icon: const Icon(Icons.date_range_rounded),
//             onSelected: (option) {
//               setState(() {
//                 _dateRange =
//                     DateTimeRange(start: option.start, end: option.end);
//               });
//             },
//             itemBuilder: (context) => _dateRangeOptions.map((option) {
//               return PopupMenuItem(
//                 value: option,
//                 child: Text(option.label),
//               );
//             }).toList(),
//           ),
//         ],
//         bottom: _tabController == null
//             ? null
//             : TabBar(
//                 controller: _tabController,
//                 labelColor: Colors.blue[600],
//                 unselectedLabelColor: Colors.grey[600],
//                 indicatorColor: Colors.blue[600],
//                 indicatorWeight: 3,
//                 tabs: const [
//                   Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
//                   Tab(
//                       icon: Icon(Icons.trending_down_rounded),
//                       text: 'Expenses'),
//                   Tab(icon: Icon(Icons.trending_up_rounded), text: 'Income'),
//                   Tab(icon: Icon(Icons.analytics_rounded), text: 'Analytics'),
//                 ],
//               ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _tabController == null || _fadeAnimation == null
//               ? const Center(child: CircularProgressIndicator())
//               : FadeTransition(
//                   opacity: _fadeAnimation!,
//                   child: TabBarView(
//                     controller: _tabController,
//                     children: [
//                       _buildOverviewTab(),
//                       _buildExpensesTab(),
//                       _buildIncomeTab(),
//                       _buildAnalyticsTab(),
//                     ],
//                   ),
//                 ),
//     );
//   }

//   Widget _buildOverviewTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('transactions')
//           .where('userId', isEqualTo: userId!)
//           .where('date', isGreaterThanOrEqualTo: _dateRange.start)
//           .where('date', isLessThanOrEqualTo: _dateRange.end)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         _processTransactions(snapshot);

//         // Show empty state if no transactions
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.analytics_outlined,
//                   size: 64,
//                   color: Colors.grey[400],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No transactions found',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Add some transactions to see your reports',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[500],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildDateRangeCard(),
//               const SizedBox(height: 16),
//               _buildFinancialSummaryCards(),
//               const SizedBox(height: 20),
//               _buildQuickInsights(),
//               const SizedBox(height: 20),
//               _buildTaxInsightsCard(),
//               const SizedBox(height: 20),
//               _buildSpendingTrendsCard(),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDateRangeCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.blue[50],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(Icons.calendar_today_rounded, color: Colors.blue[600]),
//         ),
//         title: const Text(
//           'Report Period',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text(
//           '${DateFormat('MMM dd, yyyy').format(_dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange.end)}',
//         ),
//         trailing: const Icon(Icons.keyboard_arrow_down_rounded),
//         onTap: () => _showDatePicker(),
//       ),
//     );
//   }

//   Widget _buildFinancialSummaryCards() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildSummaryCard(
//             title: 'Total Income',
//             amount: totalIncome,
//             icon: Icons.trending_up_rounded,
//             color: Colors.green,
//             subtitle: 'This period',
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _buildSummaryCard(
//             title: 'Total Expenses',
//             amount: totalExpenses,
//             icon: Icons.trending_down_rounded,
//             color: Colors.red,
//             subtitle: 'This period',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSummaryCard({
//     required String title,
//     required double amount,
//     required IconData icon,
//     required Color color,
//     required String subtitle,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               color.withOpacity(0.1),
//               color.withOpacity(0.05),
//             ],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(icon, color: color, size: 20),
//                 ),
//                 const Spacer(),
//                 Icon(Icons.more_vert, color: Colors.grey[400], size: 16),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               '৳${amount.toStringAsFixed(2)}',
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickInsights() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.insights_rounded, color: Colors.purple[600]),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Quick Insights',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildInsightRow(
//               'Net Balance',
//               '৳${netBalance.toStringAsFixed(2)}',
//               netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
//               netBalance >= 0 ? Colors.green : Colors.red,
//             ),
//             const Divider(),
//             _buildInsightRow(
//               'Avg Daily Spending',
//               '৳${avgDailySpending.toStringAsFixed(2)}',
//               Icons.receipt_long_rounded,
//               Colors.orange,
//             ),
//             const Divider(),
//             _buildInsightRow(
//               'Projected Monthly',
//               '৳${projectedMonthlySpending.toStringAsFixed(2)}',
//               Icons.calendar_month_rounded,
//               Colors.blue,
//             ),
//             if (_estimatedTax > 0) ...[
//               const Divider(),
//               _buildInsightRow(
//                 'Est. Annual Tax',
//                 '৳${_estimatedTax.toStringAsFixed(2)}',
//                 Icons.account_balance_rounded,
//                 Colors.deepPurple,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInsightRow(
//       String label, String value, IconData icon, Color color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Icon(icon, size: 16, color: color),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTaxInsightsCard() {
//     if (_taxProfile == null || _estimatedTax == 0) return const SizedBox();

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.deepPurple.withOpacity(0.1),
//               Colors.deepPurple.withOpacity(0.05),
//             ],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(Icons.account_balance,
//                       color: Colors.deepPurple[600]),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Tax Information',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 TextButton(
//                   onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const TaxProfileScreen(),
//                     ),
//                   ),
//                   child: const Text('Update'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildTaxMetric(
//                     'Annual Tax',
//                     '৳${_estimatedTax.toStringAsFixed(2)}',
//                     Colors.deepPurple,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildTaxMetric(
//                     'Monthly Tax',
//                     '৳${(_estimatedTax / 12).toStringAsFixed(2)}',
//                     Colors.deepPurple,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTaxMetric(String label, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSpendingTrendsCard() {
//     if (monthlyExpenses.isEmpty && monthlyIncome.isEmpty)
//       return const SizedBox();

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.show_chart_rounded, color: Colors.blue[600]),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Monthly Trends',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               height: 200,
//               child: LineChart(
//                 LineChartData(
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: false,
//                     horizontalInterval: 10000,
//                     getDrawingHorizontalLine: (value) {
//                       return FlLine(
//                         color: Colors.grey[300]!,
//                         strokeWidth: 0.5,
//                       );
//                     },
//                   ),
//                   titlesData: FlTitlesData(
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 40,
//                         getTitlesWidget: (value, meta) {
//                           return Text(
//                             '${(value / 1000).toInt()}k',
//                             style: const TextStyle(fontSize: 10),
//                           );
//                         },
//                       ),
//                     ),
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           final months = monthlyExpenses.keys.toList();
//                           if (value.toInt() >= months.length)
//                             return const Text('');
//                           return Text(
//                             months[value.toInt()],
//                             style: const TextStyle(fontSize: 10),
//                           );
//                         },
//                       ),
//                     ),
//                     topTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false)),
//                     rightTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   borderData: FlBorderData(show: false),
//                   lineBarsData: [
//                     // Expenses line
//                     LineChartBarData(
//                       spots: monthlyExpenses.entries
//                           .toList()
//                           .asMap()
//                           .entries
//                           .map((entry) {
//                         return FlSpot(entry.key.toDouble(), entry.value.value);
//                       }).toList(),
//                       isCurved: true,
//                       color: Colors.red[400],
//                       barWidth: 3,
//                       belowBarData: BarAreaData(
//                         show: true,
//                         color: Colors.red.withOpacity(0.1),
//                       ),
//                       dotData: const FlDotData(show: false),
//                     ),
//                     // Income line
//                     LineChartBarData(
//                       spots: monthlyIncome.entries
//                           .toList()
//                           .asMap()
//                           .entries
//                           .map((entry) {
//                         return FlSpot(entry.key.toDouble(), entry.value.value);
//                       }).toList(),
//                       isCurved: true,
//                       color: Colors.green[400],
//                       barWidth: 3,
//                       belowBarData: BarAreaData(
//                         show: true,
//                         color: Colors.green.withOpacity(0.1),
//                       ),
//                       dotData: const FlDotData(show: false),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildLegendItem('Income', Colors.green[400]!),
//                 const SizedBox(width: 20),
//                 _buildLegendItem('Expenses', Colors.red[400]!),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExpensesTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('transactions')
//           .where('userId', isEqualTo: userId!)
//           .where('date', isGreaterThanOrEqualTo: _dateRange.start)
//           .where('date', isLessThanOrEqualTo: _dateRange.end)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         // Process transactions for expenses
//         _processTransactions(snapshot);

//         return _buildCategoryAnalysisTab(
//           categories: expenseCategories,
//           total: totalExpenses,
//           color: Colors.red,
//           title: 'Expense Analysis',
//           emptyIcon: Icons.money_off_rounded,
//           emptyText: 'No expenses found',
//           emptySubtext: 'Add some expense transactions to see analysis',
//         );
//       },
//     );
//   }

//   Widget _buildIncomeTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('transactions')
//           .where('userId', isEqualTo: userId!)
//           .where('date', isGreaterThanOrEqualTo: _dateRange.start)
//           .where('date', isLessThanOrEqualTo: _dateRange.end)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         // Process transactions for income
//         _processTransactions(snapshot);

//         return _buildCategoryAnalysisTab(
//           categories: incomeCategories,
//           total: totalIncome,
//           color: Colors.green,
//           title: 'Income Analysis',
//           emptyIcon: Icons.attach_money_rounded,
//           emptyText: 'No income found',
//           emptySubtext: 'Add some income transactions to see analysis',
//         );
//       },
//     );
//   }

//   Widget _buildCategoryAnalysisTab({
//     required Map<String, double> categories,
//     required double total,
//     required Color color,
//     required String title,
//     required IconData emptyIcon,
//     required String emptyText,
//     required String emptySubtext,
//   }) {
//     if (categories.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(emptyIcon, size: 64, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               emptyText,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               emptySubtext,
//               style: TextStyle(color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     final sortedCategories = categories.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // Header
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Pie Chart
//           Card(
//             elevation: 3,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   SizedBox(
//                     height: 250,
//                     child: PieChart(
//                       PieChartData(
//                         sections:
//                             _buildEnhancedPieSections(categories, total, color),
//                         sectionsSpace: 3,
//                         centerSpaceRadius: 60,
//                         startDegreeOffset: -90,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   _buildEnhancedLegend(categories, total),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Category Breakdown
//           ...sortedCategories.map((entry) {
//             final percentage = total > 0 ? (entry.value / total) * 100 : 0;
//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.all(16),
//                 leading: Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     _getCategoryIcon(entry.key),
//                     color: color,
//                   ),
//                 ),
//                 title: Text(
//                   entry.key,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 8),
//                     LinearProgressIndicator(
//                       value: total > 0 ? entry.value / total : 0,
//                       backgroundColor: color.withOpacity(0.1),
//                       color: color,
//                       minHeight: 6,
//                     ),
//                     const SizedBox(height: 4),
//                     Text('${percentage.toStringAsFixed(1)}% of total'),
//                   ],
//                 ),
//                 trailing: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '৳${entry.value.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnalyticsTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('transactions')
//           .where('userId', isEqualTo: userId!)
//           .where('date', isGreaterThanOrEqualTo: _dateRange.start)
//           .where('date', isLessThanOrEqualTo: _dateRange.end)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         // Process transactions for analytics
//         _processTransactions(snapshot);

//         // Show empty state if no transactions
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.analytics_outlined,
//                   size: 64,
//                   color: Colors.grey[400],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No analytics available',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Add transactions to see detailed analytics',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[500],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               // Spending Patterns
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.pattern_rounded,
//                               color: Colors.orange[600]),
//                           const SizedBox(width: 8),
//                           const Text(
//                             'Spending Patterns',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       _buildAnalyticsMetric(
//                         'Savings Rate',
//                         totalIncome > 0
//                             ? '${((totalIncome - totalExpenses) / totalIncome * 100).toStringAsFixed(1)}%'
//                             : '0%',
//                         totalIncome > totalExpenses ? Colors.green : Colors.red,
//                         Icons.savings_rounded,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildAnalyticsMetric(
//                         'Expense Ratio',
//                         totalIncome > 0
//                             ? '${(totalExpenses / totalIncome * 100).toStringAsFixed(1)}%'
//                             : '0%',
//                         Colors.orange,
//                         Icons.pie_chart_rounded,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildAnalyticsMetric(
//                         'Top Expense Category',
//                         expenseCategories.isNotEmpty
//                             ? expenseCategories.entries
//                                 .reduce((a, b) => a.value > b.value ? a : b)
//                                 .key
//                             : 'None',
//                         Colors.red,
//                         Icons.category_rounded,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildAnalyticsMetric(
//                         'Daily Average Spend',
//                         '৳${avgDailySpending.toStringAsFixed(2)}',
//                         Colors.blue,
//                         Icons.today_rounded,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Financial Health Score
//               _buildFinancialHealthCard(),

//               const SizedBox(height: 20),

//               // Budget Recommendations
//               _buildBudgetRecommendationsCard(),

//               const SizedBox(height: 20),

//               // Weekly Spending Chart
//               if (dailySpending.isNotEmpty) _buildWeeklySpendingChart(),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAnalyticsMetric(
//       String label, String value, Color color, IconData icon) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Text(
//             label,
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: color,
//             fontSize: 16,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFinancialHealthCard() {
//     double healthScore = _calculateFinancialHealthScore();
//     Color scoreColor = _getHealthScoreColor(healthScore);

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               scoreColor.withOpacity(0.1),
//               scoreColor.withOpacity(0.05),
//             ],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: scoreColor.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child:
//                       Icon(Icons.health_and_safety_rounded, color: scoreColor),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Financial Health Score',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: Column(
//                 children: [
//                   SizedBox(
//                     width: 120,
//                     height: 120,
//                     child: CircularProgressIndicator(
//                       value: healthScore / 100,
//                       backgroundColor: scoreColor.withOpacity(0.2),
//                       color: scoreColor,
//                       strokeWidth: 8,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     '${healthScore.toInt()}/100',
//                     style: TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                       color: scoreColor,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     _getHealthScoreLabel(healthScore),
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: scoreColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _getHealthScoreDescription(healthScore),
//               style: const TextStyle(fontSize: 14, height: 1.5),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBudgetRecommendationsCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.lightbulb_rounded, color: Colors.amber[600]),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Smart Recommendations',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             ..._generateRecommendations().map((recommendation) {
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: recommendation.color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border:
//                       Border.all(color: recommendation.color.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(recommendation.icon,
//                         color: recommendation.color, size: 20),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         recommendation.message,
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget _buildWeeklySpendingChart() {
//   //   return Card(
//   //     elevation: 2,
//   //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//   //     child: Padding(
//   //       padding: const EdgeInsets.all(16),
//   //       child: Column(
//   //         crossAxisAlignment: CrossAxisAlignment.start,
//   //         children: [
//   //           Row(
//   //             children: [
//   //               Icon(Icons.calendar_view_week_rounded,
//   //                   color: Colors.indigo[600]),
//   //               const SizedBox(width: 8),
//   //               const Text(
//   //                 'Last 7 Days Spending',
//   //                 style: TextStyle(
//   //                   fontSize: 18,
//   //                   fontWeight: FontWeight.bold,
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //           const SizedBox(height: 20),
//   //           SizedBox(
//   //             height: 200,
//   //             child: BarChart(
//   //               BarChartData(
//   //                 barGroups: dailySpending.entries
//   //                     .toList()
//   //                     .asMap()
//   //                     .entries
//   //                     .map((entry) {
//   //                   final idx = entry.key;
//   //                   final amount = entry.value.value;

//   //                   return BarChartGroupData(
//   //                     x: idx,
//   //                     barRods: [
//   //                       BarChartRodData(
//   //                         toY: amount,
//   //                         color: Colors.indigo[400],
//   //                         width: 20,
//   //                         borderRadius: const BorderRadius.only(
//   //                           topLeft: Radius.circular(6),
//   //                           topRight: Radius.circular(6),
//   //                         ),
//   //                       ),
//   //                     ],
//   //                   );
//   //                 }).toList(),
//   //                 titlesData: FlTitlesData(
//   //                   bottomTitles: AxisTitles(
//   //                     sideTitles: SideTitles(
//   //                       showTitles: true,
//   //                       getTitlesWidget: (value, meta) {
//   //                         final dates = dailySpending.keys.toList();
//   //                         if (value.toInt() >= dates.length)
//   //                           return const Text('');
//   //                         final date = DateTime.parse(dates[value.toInt()]);
//   //                         return Text(
//   //                           DateFormat('E').format(date),
//   //                           style: const TextStyle(fontSize: 10),
//   //                         );
//   //                       },
//   //                     ),
//   //                   ),
//   //                   leftTitles: AxisTitles(
//   //                     sideTitles: SideTitles(
//   //                       showTitles: true,
//   //                       reservedSize: 40,
//   //                       getTitlesWidget: (value, meta) {
//   //                         return Text(
//   //                           '৳${value.toInt()}',
//   //                           style: const TextStyle(fontSize: 10),
//   //                         );
//   //                       },
//   //                     ),
//   //                   ),
//   //                   topTitles: const AxisTitles(
//   //                       sideTitles: SideTitles(showTitles: false)),
//   //                   rightTitles: const AxisTitles(
//   //                       sideTitles: SideTitles(showTitles: false)),
//   //                 ),
//   //                 gridData: const FlGridData(show: true),
//   //                 borderData: FlBorderData(show: false),
//   //               ),
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }


//     Widget _buildWeeklySpendingChart() {
//     if (dailySpending.isEmpty) return const SizedBox();

//     final sortedDays = dailySpending.entries.toList()
//       ..sort((a, b) => a.key.compareTo(b.key));

//     double maxSpending = dailySpending.values.isNotEmpty 
//       ? dailySpending.values.reduce((a, b) => a > b ? a : b) 
//       : 0;

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.calendar_view_week_rounded, color: Colors.indigo[600]),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Last 7 Days Spending',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               height: 200,
//               child: BarChart(
//                 BarChartData(
//                   barGroups: sortedDays.asMap().entries.map((entry) {
//                     final idx = entry.key;
//                     final amount = entry.value.value;
                    
//                     return BarChartGroupData(
//                       x: idx,
//                       barRods: [
//                         BarChartRodData(
//                           toY: amount,
//                           color: Colors.indigo[400],
//                           width: 20,
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(6),
//                             topRight: Radius.circular(6),
//                           ),
//                         ),
//                       ],
//                     );
//                   }).toList(),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           if (value.toInt() >= sortedDays.length) return const Text('');
//                           final date = DateTime.parse(sortedDays[value.toInt()].key);
//                           return Text(
//                             DateFormat('E').format(date),
//                             style: const TextStyle(fontSize: 10),
//                           );
//                         },
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 50,
//                         getTitlesWidget: (value, meta) {
//                           if (value >= 1000) {
//                             return Text(
//                               '৳${(value / 1000).toStringAsFixed(0)}k',
//                               style: const TextStyle(fontSize: 10),
//                             );
//                           } else {
//                             return Text(
//                               '৳${value.toInt()}',
//                               style: const TextStyle(fontSize: 10),
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                     topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: false,
//                     horizontalInterval: maxSpending > 0 ? maxSpending / 4 : 1000,
//                   ),
//                   borderData: FlBorderData(show: false),
//                   barTouchData: BarTouchData(
//                     touchTooltipData: BarTouchTooltipData(
//                       tooltipBgColor: Colors.blueGrey,
//                       getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                         final date = DateTime.parse(sortedDays[group.x.toInt()].key);
//                         return BarTooltipItem(
//                           '${DateFormat('MMM dd').format(date)}\n৳${rod.toY.toStringAsFixed(2)}',
//                           const TextStyle(color: Colors.white),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Helper methods
//   void _processTransactions(AsyncSnapshot<QuerySnapshot> snapshot) {
//     expenseCategories.clear();
//     incomeCategories.clear();
//     totalExpenses = 0;
//     totalIncome = 0;
//     netBalance = 0;

//     if (!snapshot.hasData) return;

//     for (var doc in snapshot.data!.docs) {
//       final data = doc.data() as Map<String, dynamic>;
//       final amount = (data['amount'] as num?)?.toDouble() ?? 0;
//       final category = data['category'] as String? ?? 'Uncategorized';
//       final type = data['type'] as String? ?? 'expense';

//       // Match transaction screen logic: negative amounts or type == 'expense'
//       if (amount < 0 || type == 'expense') {
//         final absAmount = amount.abs();
//         totalExpenses += absAmount;
//         expenseCategories[category] =
//             (expenseCategories[category] ?? 0) + absAmount;
//       } else {
//         totalIncome += amount;
//         incomeCategories[category] = (incomeCategories[category] ?? 0) + amount;
//       }
//     }

//     netBalance = totalIncome - totalExpenses;
//   }

//   List<PieChartSectionData> _buildEnhancedPieSections(
//       Map<String, double> categories, double total, Color baseColor) {
//     if (categories.isEmpty || total == 0) return [];

//     final sortedCategories = categories.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     final colors = [
//       baseColor,
//       baseColor.withOpacity(0.8),
//       baseColor.withOpacity(0.6),
//       baseColor.withOpacity(0.4),
//       baseColor.withOpacity(0.3),
//       Colors.blue.withOpacity(0.7),
//       Colors.purple.withOpacity(0.7),
//       Colors.orange.withOpacity(0.7),
//       Colors.teal.withOpacity(0.7),
//       Colors.pink.withOpacity(0.7),
//     ];

//     return sortedCategories.asMap().entries.map((entry) {
//       final idx = entry.key;
//       final category = entry.value;
//       final percentage = (category.value / total) * 100;

//       return PieChartSectionData(
//         color: colors[idx % colors.length],
//         value: category.value,
//         title: percentage > 5 ? "${percentage.toStringAsFixed(1)}%" : "",
//         radius: 30,
//         titleStyle: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//       );
//     }).toList();
//   }

//   Widget _buildEnhancedLegend(Map<String, double> categories, double total) {
//     if (categories.isEmpty || total == 0) return const SizedBox();

//     final sortedCategories = categories.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     final colors = [
//       Colors.red,
//       Colors.red.withOpacity(0.8),
//       Colors.red.withOpacity(0.6),
//       Colors.red.withOpacity(0.4),
//       Colors.red.withOpacity(0.3),
//       Colors.blue.withOpacity(0.7),
//       Colors.purple.withOpacity(0.7),
//       Colors.orange.withOpacity(0.7),
//       Colors.teal.withOpacity(0.7),
//       Colors.pink.withOpacity(0.7),
//     ];

//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: sortedCategories.take(10).toList().asMap().entries.map((entry) {
//         final idx = entry.key;
//         final category = entry.value;
//         final percentage = (category.value / total) * 100;

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   color: colors[idx % colors.length],
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 '${category.key} (${percentage.toStringAsFixed(1)}%)',
//                 style: const TextStyle(fontSize: 11),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildLegendItem(String text, Color color) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           text,
//           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   IconData _getCategoryIcon(String category) {
//     switch (category.toLowerCase()) {
//       case 'food':
//       case 'food & daily':
//       case 'groceries':
//         return Icons.restaurant_rounded;
//       case 'transport':
//       case 'transportation':
//         return Icons.directions_car_rounded;
//       case 'housing':
//       case 'rent':
//         return Icons.home_rounded;
//       case 'entertainment':
//         return Icons.movie_rounded;
//       case 'healthcare':
//       case 'medical':
//       case 'health':
//         return Icons.medical_services_rounded;
//       case 'education':
//         return Icons.school_rounded;
//       case 'shopping':
//         return Icons.shopping_bag_rounded;
//       case 'bills':
//         return Icons.receipt_rounded;
//       case 'salary':
//       case 'income':
//         return Icons.work_rounded;
//       case 'business':
//         return Icons.business_rounded;
//       case 'investment':
//         return Icons.trending_up_rounded;
//       case 'others':
//         return Icons.more_horiz_rounded;
//       default:
//         return Icons.category_rounded;
//     }
//   }

//   double _calculateFinancialHealthScore() {
//     double score = 0;

//     // Savings rate (40 points max)
//     if (totalIncome > 0) {
//       double savingsRate = (totalIncome - totalExpenses) / totalIncome;
//       if (savingsRate >= 0.2)
//         score += 40;
//       else if (savingsRate >= 0.1)
//         score += 30;
//       else if (savingsRate >= 0.05)
//         score += 20;
//       else if (savingsRate >= 0) score += 10;
//     }

//     // Expense diversification (20 points max)
//     if (expenseCategories.length >= 5)
//       score += 20;
//     else if (expenseCategories.length >= 3)
//       score += 15;
//     else if (expenseCategories.length >= 2) score += 10;

//     // Income stability (20 points max)
//     if (incomeCategories.isNotEmpty) {
//       if (incomeCategories.length == 1)
//         score += 10; // Single income source
//       else if (incomeCategories.length >= 2)
//         score += 20; // Multiple income sources
//     }

//     // Tax planning (20 points max)
//     if (_taxProfile != null) {
//       score += 10;
//       if (_estimatedTax > 0) score += 10;
//     }

//     return score.clamp(0, 100);
//   }

//   Color _getHealthScoreColor(double score) {
//     if (score >= 80) return Colors.green;
//     if (score >= 60) return Colors.orange;
//     if (score >= 40) return Colors.amber;
//     return Colors.red;
//   }

//   String _getHealthScoreLabel(double score) {
//     if (score >= 80) return 'Excellent';
//     if (score >= 60) return 'Good';
//     if (score >= 40) return 'Fair';
//     return 'Needs Improvement';
//   }

//   String _getHealthScoreDescription(double score) {
//     if (score >= 80) {
//       return 'Your financial health is excellent! You\'re saving well and managing expenses effectively.';
//     } else if (score >= 60) {
//       return 'Good financial health! Consider increasing savings and diversifying income sources.';
//     } else if (score >= 40) {
//       return 'Fair financial health. Focus on reducing expenses and increasing savings rate.';
//     } else {
//       return 'Your financial health needs attention. Consider budgeting and expense tracking.';
//     }
//   }

//   List<Recommendation> _generateRecommendations() {
//     List<Recommendation> recommendations = [];

//     // Savings rate recommendation
//     if (totalIncome > 0) {
//       double savingsRate = (totalIncome - totalExpenses) / totalIncome;
//       if (savingsRate < 0.1) {
//         recommendations.add(Recommendation(
//           'Try to save at least 10% of your income. Consider reducing non-essential expenses.',
//           Icons.savings_rounded,
//           Colors.orange,
//         ));
//       }
//     }

//     // Top expense category recommendation
//     if (expenseCategories.isNotEmpty) {
//       final topExpense =
//           expenseCategories.entries.reduce((a, b) => a.value > b.value ? a : b);
//       if (topExpense.value / totalExpenses > 0.5) {
//         recommendations.add(Recommendation(
//           '${topExpense.key} takes up ${((topExpense.value / totalExpenses) * 100).toStringAsFixed(1)}% of your expenses. Consider ways to reduce this.',
//           Icons.trending_down_rounded,
//           Colors.red,
//         ));
//       }
//     }

//     // Tax optimization recommendation
//     if (_taxProfile == null) {
//       recommendations.add(Recommendation(
//         'Set up your tax profile to get personalized tax optimization advice.',
//         Icons.account_balance_rounded,
//         Colors.blue,
//       ));
//     }

//     // Emergency fund recommendation
//     if (netBalance < totalExpenses) {
//       recommendations.add(Recommendation(
//         'Build an emergency fund covering 3-6 months of expenses for financial security.',
//         Icons.security_rounded,
//         Colors.purple,
//       ));
//     }

//     return recommendations;
//   }

//   Future<void> _showDatePicker() async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       initialDateRange: _dateRange,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() => _dateRange = picked);
//     }
//   }
// }

// class DateRangeOption {
//   final String label;
//   final DateTime start;
//   final DateTime end;

//   DateRangeOption(this.label, this.start, this.end);
// }

// class Recommendation {
//   final String message;
//   final IconData icon;
//   final Color color;

//   Recommendation(this.message, this.icon, this.color);
// }






