import 'dart:typed_data';
import 'dart:async';
import 'package:chatapp/firebase_service.dart';
import 'package:chatapp/gemini_service.dart';
import 'package:chatapp/transaction_model.dart';
import 'package:flutter/material.dart';


class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  StreamSubscription<List<TransactionModel>>? _transactionsSubscription;
  bool _isLoading = false;
  String _error = '';
  
  // Financial summary
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _netBalance = 0;
  double _loanBalance = 0;
  final Map<String, double> _categoryExpenses = {};
  
  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get filteredTransactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  String get error => _error;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  double get netBalance => _netBalance;
  double get loanBalance => _loanBalance;
  Map<String, double> get categoryExpenses => _categoryExpenses;
  double get savingsRate => totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome * 100) : 0;
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void setError(String message) {
    _error = message;
    notifyListeners();
  }
  
  Future<void> loadTransactions(String userId) async {
    if (userId.isEmpty) {
      setError('Missing user id for loading transactions.');
      return;
    }

    await _transactionsSubscription?.cancel();
    setLoading(true);
    setError('');
    
    try {
      _transactionsSubscription = FirebaseService.getTransactions(userId).listen(
        (transactions) {
          _transactions = transactions;
          _filteredTransactions = transactions;
          _calculateSummary();
          setLoading(false);
        },
        onError: (error) {
          setError('Failed to load transactions: $error');
          setLoading(false);
        },
      );
    } catch (e) {
      setError('Failed to load transactions: $e');
      setLoading(false);
    }
  }
  
  Future<void> loadTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    setLoading(true);
    setError('');
    
    try {
      final transactions = await FirebaseService.getTransactionsByDateRange(
        userId,
        startDate,
        endDate,
      );
      _filteredTransactions = transactions;
      _calculateSummary();
      setLoading(false);
    } catch (e) {
      setError('Failed to load transactions: $e');
      setLoading(false);
    }
  }
  
  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final id = await FirebaseService.addTransaction(transaction);
      if (id != null) {
        return true;
      }
      setError('Failed to add transaction. Check Firebase rules/connection and ensure the user profile exists.');
      return false;
    } catch (e) {
      setError('Error adding transaction: $e');
      return false;
    }
  }
  
  Future<bool> updateTransaction(String transactionId, Map<String, dynamic> updates) async {
    try {
      final success = await FirebaseService.updateTransaction(transactionId, updates);
      if (success) {
        return true;
      }
      setError('Failed to update transaction');
      return false;
    } catch (e) {
      setError('Error updating transaction: $e');
      return false;
    }
  }
  
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final success = await FirebaseService.deleteTransaction(transactionId);
      if (success) {
        // Remove from local list immediately for better UX
        _transactions.removeWhere((t) => t.id == transactionId);
        _filteredTransactions.removeWhere((t) => t.id == transactionId);
        _calculateSummary();
        return true;
      }
      setError('Failed to delete transaction');
      return false;
    } catch (e) {
      setError('Error deleting transaction: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> processVoiceCommand(String transcription) async {
    try {
      final result = await GeminiService.processVoiceCommand(transcription);
      
      // The GeminiService now returns the processed data directly
      if (result != null) {
        print('Voice Command Result: $result'); // Debug log
        return result;
      }
      
      return null;
    } catch (e) {
      setError('Error processing voice command: $e');
      print('Voice Command Error: $e'); // Debug log
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> analyzeReceipt(Uint8List imageBytes) async {
    try {
      return await GeminiService.analyzeReceipt(imageBytes);
    } catch (e) {
      setError('Error analyzing receipt: $e');
      return null;
    }
  }
  
  void filterTransactionsByType(TransactionType? type) {
    if (type == null) {
      _filteredTransactions = _transactions;
    } else {
      _filteredTransactions = _transactions.where((t) => t.type == type).toList();
    }
    _calculateSummary();
  }
  
  void filterTransactionsByCategory(String? category) {
    if (category == null || category.isEmpty) {
      _filteredTransactions = _transactions;
    } else {
      _filteredTransactions = _transactions.where((t) => t.category == category).toList();
    }
    _calculateSummary();
  }
  
  void _calculateSummary() {
    _totalIncome = 0;
    _totalExpenses = 0;
    _loanBalance = 0;
    _categoryExpenses.clear();
    
    for (final transaction in _filteredTransactions) {
      switch (transaction.type) {
        case TransactionType.income:
          _totalIncome += transaction.amount;
          break;
        case TransactionType.expense:
          _totalExpenses += transaction.amount;
          _categoryExpenses[transaction.category] = 
              (_categoryExpenses[transaction.category] ?? 0) + transaction.amount;
          break;
        case TransactionType.loanGiven:
          _loanBalance -= transaction.amount;
          break;
        case TransactionType.loanReceived:
          _loanBalance += transaction.amount;
          break;
      }
    }
    
    _netBalance = _totalIncome - _totalExpenses;
    notifyListeners();
  }
  
  List<Map<String, dynamic>> getMonthlyTrends() {
    final Map<String, Map<String, double>> monthlyData = {};
    
    for (final transaction in _transactions) {
      final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'income': 0, 'expenses': 0};
      }
      
      if (transaction.type == TransactionType.income) {
        monthlyData[monthKey]!['income'] = 
            (monthlyData[monthKey]!['income'] ?? 0) + transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        monthlyData[monthKey]!['expenses'] = 
            (monthlyData[monthKey]!['expenses'] ?? 0) + transaction.amount;
      }
    }
    
    final sortedMonths = monthlyData.keys.toList()..sort();
    
    return sortedMonths.map((month) => {
      'month': month,
      'income': monthlyData[month]!['income'] ?? 0,
      'expenses': monthlyData[month]!['expenses'] ?? 0,
    }).toList();
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
