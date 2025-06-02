import 'package:chatapp/reports_expenses_tab_fixed.dart';
import 'package:chatapp/reports_income_tab_fixed.dart';
import 'package:chatapp/reports_overview_tab_fixed.dart';
import 'package:chatapp/tax_calculator.dart';
import 'package:chatapp/tax_profile_model.dart';
import 'package:chatapp/tax_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Import the separated files
import 'reports_analytics_tab.dart';
import 'reports_widgets.dart';

// Add the missing DateRangeOption class
class DateRangeOption {
  final String label;
  final DateTime start;
  final DateTime end;

  DateRangeOption(this.label, this.start, this.end);
}

// FIXED: Add safe type conversion function
double _safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  if (value is num) return value.toDouble();
  return 0.0;
}

// FIXED: Updated ReportsDataService class with proper type handling
class ReportsDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> loadAllData(String userId) async {
    try {
      final results = await Future.wait([
        _loadHistoricalData(userId),
        _loadTaxProfile(userId),
        _calculateDailySpending(userId),
      ]);

      return {
        'monthlyExpenses': results[0]['monthlyExpenses'] ?? {},
        'monthlyIncome': results[0]['monthlyIncome'] ?? {},
        'taxProfile': results[1]['taxProfile'],
        'estimatedTax': results[1]['estimatedTax'] ?? 0.0,
        'dailySpending': results[2]['dailySpending'] ?? {},
        'avgDailySpending': results[2]['avgDailySpending'] ?? 0.0,
        'projectedMonthlySpending': results[2]['projectedMonthlySpending'] ?? 0.0,
      };
    } catch (e) {
      print("Error in loadAllData: $e");
      return {
        'monthlyExpenses': <String, double>{},
        'monthlyIncome': <String, double>{},
        'taxProfile': null,
        'estimatedTax': 0.0,
        'dailySpending': <String, double>{},
        'avgDailySpending': 0.0,
        'projectedMonthlySpending': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _loadTaxProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('taxProfiles')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final taxProfile = BangladeshTaxProfile.fromJson(doc.data()!);
        final estimatedTax = BangladeshTaxCalculator.calculateTax(taxProfile);
        
        return {
          'taxProfile': taxProfile,
          'estimatedTax': estimatedTax,
        };
      }
    } catch (e) {
      print("Error loading tax profile: $e");
    }
    
    return {
      'taxProfile': null,
      'estimatedTax': 0.0,
    };
  }

  Future<Map<String, dynamic>> _loadHistoricalData(String userId) async {
    try {
      final now = DateTime.now();
      final historicalExpenses = <String, double>{};
      final historicalIncome = <String, double>{};

      for (int i = 11; i >= 0; i--) {
        final month = now.month - i;
        final year = now.year + (month <= 0 ? -1 : 0);
        final adjustedMonth = month <= 0 ? month + 12 : month;

        final monthStart = DateTime(year, adjustedMonth, 1);
        final monthEnd = DateTime(year, adjustedMonth + 1, 1)
            .subtract(const Duration(days: 1));

        final monthKey = DateFormat('MMM').format(monthStart);

        // FIXED: Added proper error handling for Firestore query
        try {
          final monthSnapshot = await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
              .get();

          double monthExpenses = 0;
          double monthIncome = 0;

          for (var doc in monthSnapshot.docs) {
            try {
              final data = doc.data();
              if (data == null) continue;
              
              // FIXED: Use safe conversion instead of direct casting
              final amount = _safeToDouble(data['amount']);
              final type = data['type'] as String? ?? 'expense';

              // Match your transaction screen logic
              if (amount < 0 || type == 'expense') {
                monthExpenses += amount.abs();
              } else if (amount > 0 || type == 'earning') {
                monthIncome += amount;
              }
            } catch (e) {
              print("Error processing document ${doc.id}: $e");
              continue; // Skip this document and continue with others
            }
          }

          historicalExpenses[monthKey] = monthExpenses;
          historicalIncome[monthKey] = monthIncome;
        } catch (e) {
          print("Error loading data for month $monthKey: $e");
          historicalExpenses[monthKey] = 0.0;
          historicalIncome[monthKey] = 0.0;
        }
      }

      return {
        'monthlyExpenses': historicalExpenses,
        'monthlyIncome': historicalIncome,
      };
    } catch (e) {
      print("Error loading historical data: $e");
      return {
        'monthlyExpenses': <String, double>{},
        'monthlyIncome': <String, double>{},
      };
    }
  }

  Future<Map<String, dynamic>> _calculateDailySpending(String userId) async {
    try {
      final last7Days = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(last7Days))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .get();

      double totalSpent = 0;
      final Map<String, double> dailyTotals = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data == null) continue;
          
          // FIXED: Use safe conversion
          final amount = _safeToDouble(data['amount']);
          final type = data['type'] as String? ?? 'expense';
          final date = (data['date'] as Timestamp?)?.toDate();
          
          if (date == null) continue;
          
          final dayKey = DateFormat('yyyy-MM-dd').format(date);

          // Match transaction screen logic for expenses only
          if (amount < 0 || type == 'expense') {
            final absAmount = amount.abs();
            totalSpent += absAmount;
            dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + absAmount;
          }
        } catch (e) {
          print("Error processing daily spending document ${doc.id}: $e");
          continue;
        }
      }

      final days = dailyTotals.length;
      final avgDailySpending = days > 0 ? totalSpent / days : 0.0;
      final projectedMonthlySpending = avgDailySpending * 30;

      return {
        'dailySpending': dailyTotals,
        'avgDailySpending': avgDailySpending,
        'projectedMonthlySpending': projectedMonthlySpending,
      };
    } catch (e) {
      print("Error calculating daily spending: $e");
      return {
        'dailySpending': <String, double>{},
        'avgDailySpending': 0.0,
        'projectedMonthlySpending': 0.0,
      };
    }
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // Current transaction data - will be updated by StreamBuilder
  Map<String, double> _currentExpenseCategories = {};
  Map<String, double> _currentIncomeCategories = {};
  double _currentTotalExpenses = 0;
  double _currentTotalIncome = 0;
  double _currentNetBalance = 0;

  // Historical data
  Map<String, double> monthlyExpenses = {};
  Map<String, double> monthlyIncome = {};
  Map<String, double> dailySpending = {};
  double avgDailySpending = 0;
  double projectedMonthlySpending = 0;

  // Tax profile data
  BangladeshTaxProfile? _taxProfile;
  double _estimatedTax = 0;

  // Get current user ID
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Predefined date ranges
  final List<DateRangeOption> _dateRangeOptions = [
    DateRangeOption('Last 7 Days',
        DateTime.now().subtract(const Duration(days: 7)), DateTime.now()),
    DateRangeOption('Last 30 Days',
        DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
    DateRangeOption('Last 3 Months',
        DateTime.now().subtract(const Duration(days: 90)), DateTime.now()),
    DateRangeOption('Last 6 Months',
        DateTime.now().subtract(const Duration(days: 180)), DateTime.now()),
    DateRangeOption(
        'This Year', DateTime(DateTime.now().year, 1, 1), DateTime.now()),
  ];

  bool _isLoading = false;
  late ReportsDataService _dataService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _dataService = ReportsDataService();
    
    if (userId != null) {
      _loadHistoricalData();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadHistoricalData() async {
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final results = await _dataService.loadAllData(userId!);
      
      if (mounted) {
        setState(() {
          monthlyExpenses = Map<String, double>.from(results['monthlyExpenses'] ?? {});
          monthlyIncome = Map<String, double>.from(results['monthlyIncome'] ?? {});
          dailySpending = Map<String, double>.from(results['dailySpending'] ?? {});
          avgDailySpending = _safeToDouble(results['avgDailySpending']);
          projectedMonthlySpending = _safeToDouble(results['projectedMonthlySpending']);
          _taxProfile = results['taxProfile'];
          _estimatedTax = _safeToDouble(results['estimatedTax']);
          _isLoading = false;
        });
        
        _animationController?.forward();
      }
    } catch (e) {
      print("Error in _loadHistoricalData: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load historical data');
      }
    }
  }

  void _processTransactions(AsyncSnapshot<QuerySnapshot> snapshot) {
    try {
      _currentExpenseCategories.clear();
      _currentIncomeCategories.clear();
      _currentTotalExpenses = 0;
      _currentTotalIncome = 0;
      _currentNetBalance = 0;

      if (!snapshot.hasData || snapshot.data == null) return;

      for (var doc in snapshot.data!.docs) {
        try {
          final data = doc.data();
          if (data == null) continue;
          
          final dataMap = data as Map<String, dynamic>;
          
          // FIXED: Use safe conversion
          final amount = _safeToDouble(dataMap['amount']);
          final category = dataMap['category'] as String? ?? 'Uncategorized';
          final type = dataMap['type'] as String? ?? 'expense';

          // Match your transaction screen logic exactly
          if (amount < 0 || type == 'expense') {
            final absAmount = amount.abs();
            _currentTotalExpenses += absAmount;
            _currentExpenseCategories[category] =
                (_currentExpenseCategories[category] ?? 0) + absAmount;
          } else if (amount > 0 || type == 'earning') {
            _currentTotalIncome += amount;
            _currentIncomeCategories[category] = 
                (_currentIncomeCategories[category] ?? 0) + amount;
          }
        } catch (e) {
          print("Error processing transaction document ${doc.id}: $e");
          continue;
        }
      }

      _currentNetBalance = _currentTotalIncome - _currentTotalExpenses;
    } catch (e) {
      print("Error in _processTransactions: $e");
    }
  }

  Future<void> _showDatePicker() async {
    try {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _dateRange,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() => _dateRange = picked);
      }
    } catch (e) {
      print("Error showing date picker: $e");
      _showErrorSnackBar('Failed to open date picker');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please log in to view reports',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Financial Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistoricalData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<DateRangeOption>(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Select Date Range',
            onSelected: (option) {
              if (mounted) {
                setState(() {
                  _dateRange = DateTimeRange(start: option.start, end: option.end);
                });
              }
            },
            itemBuilder: (context) => _dateRangeOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Text(option.label),
              );
            }).toList(),
          ),
        ],
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: Colors.blue[600],
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.blue[600],
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
                  Tab(icon: Icon(Icons.trending_down_rounded), text: 'Expenses'),
                  Tab(icon: Icon(Icons.trending_up_rounded), text: 'Income'),
                  Tab(icon: Icon(Icons.analytics_rounded), text: 'Analytics'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading financial data...'),
                ],
              ),
            )
          : _tabController == null || _fadeAnimation == null
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _fadeAnimation!,
                  child: StreamBuilder<QuerySnapshot>(
                    // Main StreamBuilder that drives all tabs
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('userId', isEqualTo: userId!)
                        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
                        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Handle connection state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading transactions...'),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadHistoricalData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      // Process transactions for current date range
                      _processTransactions(snapshot);
                      
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          ReportsOverviewTab(
                            userId: userId!,
                            dateRange: _dateRange,
                            onShowDatePicker: _showDatePicker,
                            monthlyExpenses: monthlyExpenses,
                            monthlyIncome: monthlyIncome,
                            dailySpending: dailySpending,
                            avgDailySpending: avgDailySpending,
                            projectedMonthlySpending: projectedMonthlySpending,
                            taxProfile: _taxProfile,
                            estimatedTax: _estimatedTax,
                            totalExpenses: _currentTotalExpenses,
                            totalIncome: _currentTotalIncome,
                            netBalance: _currentNetBalance,
                            expenseCategories: _currentExpenseCategories,
                            incomeCategories: _currentIncomeCategories,
                            snapshot: snapshot,
                          ),
                          ReportsExpensesTab(
                            userId: userId!,
                            dateRange: _dateRange,
                            expenseCategories: _currentExpenseCategories,
                            totalExpenses: _currentTotalExpenses,
                            snapshot: snapshot,
                          ),
                          ReportsIncomeTab(
                            userId: userId!,
                            dateRange: _dateRange,
                            incomeCategories: _currentIncomeCategories,
                            totalIncome: _currentTotalIncome,
                            snapshot: snapshot,
                          ),
                          ReportsAnalyticsTab(
                            userId: userId!,
                            dateRange: _dateRange,
                            expenseCategories: _currentExpenseCategories,
                            incomeCategories: _currentIncomeCategories,
                            dailySpending: dailySpending,
                            totalExpenses: _currentTotalExpenses,
                            totalIncome: _currentTotalIncome,
                            avgDailySpending: avgDailySpending,
                            taxProfile: _taxProfile,
                            estimatedTax: _estimatedTax,
                            snapshot: snapshot,
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}