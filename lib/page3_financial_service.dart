import 'package:chatapp/page1_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;


class FinancialDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for financial data
  FinancialData? _cachedFinancialData;
  DateTime? _lastDataUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  Future<FinancialData> getUserFinancialData(String userId, {bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && 
        _cachedFinancialData != null && 
        _lastDataUpdate != null &&
        DateTime.now().difference(_lastDataUpdate!) < _cacheValidDuration) {
      return _cachedFinancialData!;
    }

    try {
      final now = DateTime.now();
      final last12Months = now.subtract(const Duration(days: 365));
      final last30Days = now.subtract(const Duration(days: 30));

      // Get transactions for analysis
      final allTransactionsQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: last12Months)
          .orderBy('date', descending: true)
          .get();

      final recentTransactionsQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: last30Days)
          .orderBy('date', descending: true)
          .get();

      // Process the data
      final processedData = _processTransactionData(
        allTransactionsQuery.docs, 
        recentTransactionsQuery.docs
      );

      _cachedFinancialData = processedData;
      _lastDataUpdate = DateTime.now();

      return processedData;
    } catch (e) {
      print("Error getting user financial data: $e");
      return _getEmptyFinancialData();
    }
  }

  FinancialData _processTransactionData(
    List<QueryDocumentSnapshot> allTransactions,
    List<QueryDocumentSnapshot> recentTransactions,
  ) {
  // Initialize variables with proper types
  double totalIncome = 0;
  double totalExpenses = 0;
  double recentIncome = 0;
  double recentExpenses = 0;
  
  // Fix: Initialize with proper Map<String, double> types
  Map<String, double> expenseByCategory = <String, double>{};
  Map<String, double> incomeByCategory = <String, double>{};
  Map<String, double> monthlyExpenses = <String, double>{};
  Map<String, double> monthlyIncome = <String, double>{};
  Map<String, int> transactionFrequency = <String, int>{};

  // Process all transactions (last 12 months)
  for (var doc in allTransactions) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // Fix: Better null safety and type checking
      final amountRaw = data['amount'];
      if (amountRaw == null) continue;
      
      final amount = (amountRaw is num) ? amountRaw.toDouble() : 0.0;
      if (amount == 0) continue; // Skip zero amounts
      
      final category = (data['category'] as String?) ?? 'Uncategorized';
      final type = (data['type'] as String?) ?? '';
      
      // Fix: Better date handling with null safety
      final dateField = data['date'];
      DateTime date;
      if (dateField is Timestamp) {
        date = dateField.toDate();
      } else if (dateField is DateTime) {
        date = dateField;
      } else {
        date = DateTime.now(); // Fallback to current date
      }
      
      final monthKey = DateFormat('yyyy-MM').format(date);

      // Fix: More robust expense/income determination
      bool isExpense;
      if (type.toLowerCase() == 'expense') {
        isExpense = true;
      } else if (type.toLowerCase() == 'earning' || type.toLowerCase() == 'income') {
        isExpense = false;
      } else {
        // Fallback to amount sign
        isExpense = amount < 0;
      }
      
      if (isExpense) {
        final absAmount = amount.abs();
        totalExpenses += absAmount;
        
        // Fix: Ensure we're adding to the correct map type
        expenseByCategory[category] = (expenseByCategory[category] ?? 0.0) + absAmount;
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0.0) + absAmount;
      } else {
        final positiveAmount = amount.abs(); // Ensure positive for income
        totalIncome += positiveAmount;
        
        incomeByCategory[category] = (incomeByCategory[category] ?? 0.0) + positiveAmount;
        monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0.0) + positiveAmount;
      }

      transactionFrequency[category] = (transactionFrequency[category] ?? 0) + 1;
      
    } catch (e) {
      print("Error processing transaction ${doc.id}: $e");
      continue; // Skip problematic transactions
    }
  }

  // Process recent transactions (last 30 days) with same safety measures
  for (var doc in recentTransactions) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      final amountRaw = data['amount'];
      if (amountRaw == null) continue;
      
      final amount = (amountRaw is num) ? amountRaw.toDouble() : 0.0;
      if (amount == 0) continue;
      
      final type = (data['type'] as String?) ?? '';

      bool isExpense;
      if (type.toLowerCase() == 'expense') {
        isExpense = true;
      } else if (type.toLowerCase() == 'earning' || type.toLowerCase() == 'income') {
        isExpense = false;
      } else {
        isExpense = amount < 0;
      }
      
      if (isExpense) {
        recentExpenses += amount.abs();
      } else {
        recentIncome += amount.abs();
      }
      
    } catch (e) {
      print("Error processing recent transaction ${doc.id}: $e");
      continue;
    }
  }

  // Fix: Calculate derived metrics with null safety and division by zero checks
  final netSavings = totalIncome - totalExpenses;
  final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0.0;
  
  final avgMonthlyExpenses = monthlyExpenses.values.isNotEmpty 
      ? monthlyExpenses.values.reduce((a, b) => a + b) / monthlyExpenses.length 
      : 0.0;
  
  final avgMonthlyIncome = monthlyIncome.values.isNotEmpty 
      ? monthlyIncome.values.reduce((a, b) => a + b) / monthlyIncome.length 
      : 0.0;

  // Fix: Find top expense category and concentration with safety checks
  String topExpenseCategory = 'None';
  double expenseConcentration = 0.0;
  
  if (expenseByCategory.isNotEmpty && totalExpenses > 0) {
    try {
      final topExpenseEntry = expenseByCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      topExpenseCategory = topExpenseEntry.key;
      expenseConcentration = (topExpenseEntry.value / totalExpenses) * 100;
    } catch (e) {
      print("Error calculating top expense category: $e");
      // Keep default values
    }
  }

  // Fix: Ensure all values are finite and not NaN
  return FinancialData(
    totalIncome: _sanitizeDouble(totalIncome),
    totalExpenses: _sanitizeDouble(totalExpenses),
    netSavings: _sanitizeDouble(netSavings),
    savingsRate: _sanitizeDouble(savingsRate),
    avgMonthlyIncome: _sanitizeDouble(avgMonthlyIncome),
    avgMonthlyExpenses: _sanitizeDouble(avgMonthlyExpenses),
    expenseByCategory: _sanitizeMap(expenseByCategory),
    incomeByCategory: _sanitizeMap(incomeByCategory),
    monthlyExpenses: _sanitizeMap(monthlyExpenses),
    monthlyIncome: _sanitizeMap(monthlyIncome),
    transactionCount: math.max(0, allTransactions.length), // Ensure non-negative
    topExpenseCategory: topExpenseCategory,
    expenseConcentration: _sanitizeDouble(expenseConcentration),
    incomeSourceCount: math.max(0, incomeByCategory.length),
    expenseCategoryCount: math.max(0, expenseByCategory.length),
  );
}

// Helper method to sanitize double values
double _sanitizeDouble(double value) {
  if (value.isNaN || value.isInfinite) {
    return 0.0;
  }
  return value;
}

// Helper method to sanitize map values
Map<String, double> _sanitizeMap(Map<String, double> map) {
  final sanitized = <String, double>{};
  for (final entry in map.entries) {
    if (!entry.value.isNaN && !entry.value.isInfinite && entry.value >= 0) {
      sanitized[entry.key] = entry.value;
    }
  }
  return sanitized;
}


  FinancialData _getEmptyFinancialData() {
    return FinancialData(
      totalIncome: 0,
      totalExpenses: 0,
      netSavings: 0,
      savingsRate: 0,
      avgMonthlyIncome: 0,
      avgMonthlyExpenses: 0,
      expenseByCategory: {},
      incomeByCategory: {},
      monthlyExpenses: {},
      monthlyIncome: {},
      transactionCount: 0,
      topExpenseCategory: 'None',
      expenseConcentration: 0,
      incomeSourceCount: 0,
      expenseCategoryCount: 0,
    );
  }

  Future<Map<String, dynamic>?> getUserTaxProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('taxProfiles')
          .doc(userId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error getting tax profile: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getFinancialSummary(String userId) async {
    try {
      final financialData = await getUserFinancialData(userId);
      final taxProfile = await getUserTaxProfile(userId);

      return {
        'financialData': financialData,
        'taxProfile': taxProfile,
        'summary': financialData.summaryText,
        'expenseBreakdown': financialData.expenseBreakdownText,
        'incomeBreakdown': financialData.incomeBreakdownText,
        'monthlyTrends': financialData.monthlyTrendsText,
        'behaviorPatterns': _generateBehaviorPatterns(financialData),
        'riskAssessment': _assessFinancialRisks(financialData),
        'recommendations': _generateBasicRecommendations(financialData),
      };
    } catch (e) {
      print("Error getting financial summary: $e");
      return {
        'financialData': _getEmptyFinancialData(),
        'taxProfile': null,
        'summary': 'No financial data available',
        'expenseBreakdown': 'No expense data',
        'incomeBreakdown': 'No income data',
        'monthlyTrends': 'No trend data',
        'behaviorPatterns': 'No behavioral data available',
        'riskAssessment': 'No risk data available',
        'recommendations': <String>[],
      };
    }
  }

  String _generateBehaviorPatterns(FinancialData data) {
    final patterns = <String>[];

    // Spending concentration
    if (data.expenseConcentration > 50) {
      patterns.add('High spending concentration in ${data.topExpenseCategory} (${data.expenseConcentration.toStringAsFixed(1)}%)');
    }

    // Transaction frequency
    final avgTransactionsPerMonth = data.transactionCount / 12;
    if (avgTransactionsPerMonth > 100) {
      patterns.add('High transaction frequency (${avgTransactionsPerMonth.toStringAsFixed(1)} per month)');
    } else if (avgTransactionsPerMonth < 20) {
      patterns.add('Low transaction frequency (${avgTransactionsPerMonth.toStringAsFixed(1)} per month)');
    }

    // Income diversification
    if (data.incomeSourceCount == 1) {
      patterns.add('Single income source dependency');
    } else if (data.incomeSourceCount >= 3) {
      patterns.add('Well-diversified income sources (${data.incomeSourceCount} sources)');
    }

    // Expense diversification
    if (data.expenseCategoryCount < 5) {
      patterns.add('Limited expense categories (${data.expenseCategoryCount})');
    } else if (data.expenseCategoryCount > 10) {
      patterns.add('Highly diversified spending across ${data.expenseCategoryCount} categories');
    }

    // Savings behavior
    if (data.savingsRate > 20) {
      patterns.add('Excellent savings habit (${data.savingsRate.toStringAsFixed(1)}% savings rate)');
    } else if (data.savingsRate < 5) {
      patterns.add('Low savings rate (${data.savingsRate.toStringAsFixed(1)}%)');
    }

    return patterns.isEmpty ? 'No significant patterns identified' : patterns.join('\n');
  }

  Map<String, dynamic> _assessFinancialRisks(FinancialData data) {
    final risks = <String>[];
    final warnings = <String>[];
    final positives = <String>[];

    // Income risks
    if (data.incomeSourceCount == 1) {
      risks.add('Income dependency risk - single source of income');
    }

    // Expense concentration risks
    if (data.expenseConcentration > 60) {
      risks.add('High expense concentration in ${data.topExpenseCategory}');
    }

    // Savings risks
    if (data.savingsRate < 0) {
      risks.add('Negative savings rate - spending exceeds income');
    } else if (data.savingsRate < 10) {
      warnings.add('Low savings rate below recommended 10%');
    }

    // Emergency fund assessment
    final emergencyFundMonths = data.avgMonthlyExpenses > 0 
        ? data.netSavings / data.avgMonthlyExpenses 
        : 0;
    
    if (emergencyFundMonths < 3) {
      risks.add('Insufficient emergency fund (${emergencyFundMonths.toStringAsFixed(1)} months coverage)');
    } else if (emergencyFundMonths >= 6) {
      positives.add('Good emergency fund coverage (${emergencyFundMonths.toStringAsFixed(1)} months)');
    }

    // Cash flow risks
    if (data.avgMonthlyExpenses > data.avgMonthlyIncome) {
      risks.add('Monthly expenses exceed monthly income on average');
    }

    // Positive indicators
    if (data.savingsRate > 15) {
      positives.add('Strong savings rate of ${data.savingsRate.toStringAsFixed(1)}%');
    }

    if (data.incomeSourceCount > 2) {
      positives.add('Good income diversification with ${data.incomeSourceCount} sources');
    }

    return {
      'risks': risks,
      'warnings': warnings,
      'positives': positives,
      'riskScore': _calculateRiskScore(data),
      'emergencyFundMonths': emergencyFundMonths,
    };
  }

  double _calculateRiskScore(FinancialData data) {
    double score = 100; // Start with perfect score

    // Deduct for risks
    if (data.incomeSourceCount == 1) score -= 20;
    if (data.expenseConcentration > 50) score -= 15;
    if (data.savingsRate < 0) score -= 30;
    else if (data.savingsRate < 10) score -= 15;
    
    final emergencyFundMonths = data.avgMonthlyExpenses > 0 
        ? data.netSavings / data.avgMonthlyExpenses 
        : 0;
    
    if (emergencyFundMonths < 1) score -= 25;
    else if (emergencyFundMonths < 3) score -= 15;

    if (data.avgMonthlyExpenses > data.avgMonthlyIncome) score -= 20;

    return score.clamp(0, 100);
  }

  List<String> _generateBasicRecommendations(FinancialData data) {
    final recommendations = <String>[];

    // Savings recommendations
    if (data.savingsRate < 10) {
      recommendations.add('Aim to save at least 10% of your income (currently ${data.savingsRate.toStringAsFixed(1)}%)');
    }

    // Emergency fund
    final emergencyFundMonths = data.avgMonthlyExpenses > 0 
        ? data.netSavings / data.avgMonthlyExpenses 
        : 0;
    
    if (emergencyFundMonths < 6) {
      final targetAmount = data.avgMonthlyExpenses * 6;
      recommendations.add('Build an emergency fund of ৳${targetAmount.toStringAsFixed(2)} (6 months of expenses)');
    }

    // Expense optimization
    if (data.expenseConcentration > 40) {
      final potentialSaving = data.expenseByCategory[data.topExpenseCategory]! * 0.1;
      recommendations.add('Consider reducing ${data.topExpenseCategory} expenses by 10% to save ৳${potentialSaving.toStringAsFixed(2)} monthly');
    }

    // Income diversification
    if (data.incomeSourceCount == 1) {
      recommendations.add('Consider developing additional income sources to reduce financial risk');
    }

    // Investment opportunities
    if (data.savingsRate > 15) {
      final investmentAmount = data.netSavings * 0.3;
      recommendations.add('Consider investing ৳${investmentAmount.toStringAsFixed(2)} in tax-saving instruments for better returns');
    }

    return recommendations;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrends(String userId, {int months = 12}) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months, 1);

      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .orderBy('date')
          .get();

      final monthlyData = <String, Map<String, dynamic>>{};

      for (var doc in transactions.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = data['type'] as String? ?? '';
        final date = (data['date'] as Timestamp).toDate();
        final monthKey = DateFormat('yyyy-MM').format(date);

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'month': monthKey,
            'income': 0.0,
            'expenses': 0.0,
            'transactions': 0,
            'categories': <String>{},
          };
        }

        final isExpense = amount < 0 || type == 'expense';
        
        if (isExpense) {
          monthlyData[monthKey]!['expenses'] += amount.abs();
        } else {
          monthlyData[monthKey]!['income'] += amount;
        }

        monthlyData[monthKey]!['transactions']++;
        monthlyData[monthKey]!['categories'].add(data['category'] ?? 'Uncategorized');
      }

      // Convert to list and add calculated fields
      final result = monthlyData.values.map((data) {
        final income = data['income'] as double;
        final expenses = data['expenses'] as double;
        final categories = data['categories'] as Set<String>;
        
        return {
          ...data,
          'netSavings': income - expenses,
          'savingsRate': income > 0 ? ((income - expenses) / income) * 100 : 0,
          'categoryCount': categories.length,
          'categories': categories.toList(),
        };
      }).toList();

      // Sort by month
      result.sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));

      return result;
    } catch (e) {
      print("Error getting monthly trends: $e");
      return [];
    }
  }

  Future<Map<String, double>> getCategorySpending(String userId, {int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .get();

      final categorySpending = <String, double>{};

      for (var doc in transactions.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = data['type'] as String? ?? '';
        final category = data['category'] as String? ?? 'Uncategorized';

        final isExpense = amount < 0 || type == 'expense';
        
        if (isExpense) {
          categorySpending[category] = (categorySpending[category] ?? 0) + amount.abs();
        }
      }

      return categorySpending;
    } catch (e) {
      print("Error getting category spending: $e");
      return {};
    }
  }

  // Clear cache when user data might have changed
  void clearCache() {
    _cachedFinancialData = null;
    _lastDataUpdate = null;
  }

  // Force refresh of financial data
  Future<FinancialData> refreshFinancialData(String userId) async {
    return getUserFinancialData(userId, forceRefresh: true);
  }
}