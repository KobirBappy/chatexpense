import 'package:chatapp/firebase_service.dart';
import 'package:chatapp/image_processing_service.dart';
import 'package:chatapp/notification_service.dart';
import 'package:chatapp/subscription_provider.dart';
import 'package:chatapp/theme_config.dart';
import 'package:chatapp/transaction_model.dart';
import 'package:chatapp/transaction_provider.dart';
import 'package:chatapp/user_provider.dart';
import 'package:chatapp/voice_service.dart';
import 'package:chatapp/voiceprocessingdialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';


class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isProcessing = false;
  bool _showManualEntry = true;
  String? _voiceTranscription;
  File? _selectedImage;
  EntryMethod? _currentEntryMethod = EntryMethod.manual;
  
  final List<String> _defaultCategories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 
    'Salary', 'Healthcare', 'Education', 'Other'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<TransactionProvider>().netBalance;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),
            
            // Manual Entry Section
            _buildManualEntrySection(),
            const SizedBox(height: 24),
            
            // Recent Transactions
            _buildRecentTransactions(balance),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.mic,
              label: 'Voice',
              color: Colors.blue,
              onPressed: _handleVoiceInput,
            ),
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: Colors.purple,
              onPressed: _handleGalleryInput,
            ),
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: Colors.green,
              onPressed: _handleCameraInput,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildManualEntrySection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showManualEntry = !_showManualEntry;
                _currentEntryMethod = EntryMethod.manual;
              });
            },
            child: Row(
              children: [
                const Icon(Icons.edit, color: AppTheme.secondaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Manual Entry',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Icon(
                  _showManualEntry ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          if (_showManualEntry) ...[
            const SizedBox(height: 16),
            
            // Transaction Type Dropdown
            DropdownButtonFormField<TransactionType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
              ),
              items: const [
                DropdownMenuItem(
                  value: TransactionType.expense,
                  child: Text('Expense'),
                ),
                DropdownMenuItem(
                  value: TransactionType.income,
                  child: Text('Income'),
                ),
                DropdownMenuItem(
                  value: TransactionType.loanGiven,
                  child: Text('Loan Given'),
                ),
                DropdownMenuItem(
                  value: TransactionType.loanReceived,
                  child: Text('Loan Received'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  // Auto-select category based on type
                  if (value == TransactionType.income) {
                    _selectedCategory = 'Salary';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Amount and Category Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    validator: (value) {
                      // Skip validation for voice/image entries
                      if (_currentEntryMethod != EntryMethod.manual) {
                        return null;
                      }
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value.replaceAll(',', '').trim()) == null) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: _defaultCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What was this for?',
              ),
              validator: (value) {
                // Skip validation for voice/image entries
                if (_currentEntryMethod != EntryMethod.manual) {
                  return null;
                }
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Date Selection
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Add Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleSubmit,
                icon: _isProcessing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isProcessing ? 'Processing...' : 'Add Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildRecentTransactions(double balance) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final recentTransactions = transactions.take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Balance: ৳${balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: balance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (recentTransactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else
          ...recentTransactions.map((transaction) => _buildTransactionItem(transaction)),
      ],
    );
  }
  
  Widget _buildTransactionItem(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income || 
                     transaction.type == TransactionType.loanReceived;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmationDialog(transaction);
        },
        onDismissed: (direction) {
          _deleteTransaction(transaction);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          title: Text(transaction.description),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transaction.category} • ${_formatDate(transaction.date)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (transaction.entryMethod != EntryMethod.manual)
                Row(
                  children: [
                    Icon(
                      _getMethodIcon(transaction.entryMethod),
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getMethodLabel(transaction.entryMethod),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}৳${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _editTransaction(transaction),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _confirmAndDeleteTransaction(transaction),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _showTransactionDetails(transaction),
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Transaction Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Type', _getTransactionTypeLabel(transaction.type)),
            _buildDetailRow('Amount', '৳${transaction.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Category', transaction.category),
            _buildDetailRow('Description', transaction.description),
            _buildDetailRow('Date', _formatDate(transaction.date)),
            _buildDetailRow('Entry Method', _getMethodLabel(transaction.entryMethod)),
            if (transaction.metadata != null && transaction.metadata!.isNotEmpty)
              _buildDetailRow('Additional Info', transaction.metadata.toString()),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editTransaction(transaction);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmAndDeleteTransaction(transaction);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editTransaction(TransactionModel transaction) {
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description;
    setState(() {
      _selectedType = transaction.type;
      _selectedCategory = transaction.category;
      _selectedDate = transaction.date;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Edit Transaction',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: GlobalKey<FormState>(),
                  child: Column(
                    children: [
                      DropdownButtonFormField<TransactionType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TransactionType.expense,
                            child: Text('Expense'),
                          ),
                          DropdownMenuItem(
                            value: TransactionType.income,
                            child: Text('Income'),
                          ),
                          DropdownMenuItem(
                            value: TransactionType.loanGiven,
                            child: Text('Loan Given'),
                          ),
                          DropdownMenuItem(
                            value: TransactionType.loanReceived,
                            child: Text('Loan Received'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.currency_exchange),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter amount';
                                }
                                if (double.tryParse(value.replaceAll(',', '').trim()) == null) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              items: _defaultCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'What was this for?',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _formatDate(_selectedDate),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _resetForm();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateTransaction(transaction.id),
                              child: const Text('Update'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTransaction(String transactionId) async {
    final updates = {
      'type': _selectedType.index,
      'amount': double.parse(_amountController.text.replaceAll(',', '').trim()),
      'category': _selectedCategory,
      'description': _descriptionController.text,
      'date': _selectedDate.toIso8601String(),
    };

    final success = await context.read<TransactionProvider>().updateTransaction(
      transactionId,
      updates,
    );

    if (success) {
      Navigator.pop(context);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update transaction'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmAndDeleteTransaction(TransactionModel transaction) async {
    final shouldDelete = await _showDeleteConfirmationDialog(transaction);
    if (shouldDelete == true) {
      _deleteTransaction(transaction);
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(TransactionModel transaction) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this transaction?\n\n'
          '${transaction.description}\n'
          '৳${transaction.amount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final success = await context.read<TransactionProvider>().deleteTransaction(transaction.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              // Re-add the transaction
              context.read<TransactionProvider>().addTransaction(transaction);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete transaction'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Transactions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Transactions'),
              onTap: () {
                context.read<TransactionProvider>().filterTransactionsByType(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.red),
              title: const Text('Expenses Only'),
              onTap: () {
                context.read<TransactionProvider>().filterTransactionsByType(TransactionType.expense);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.green),
              title: const Text('Income Only'),
              onTap: () {
                context.read<TransactionProvider>().filterTransactionsByType(TransactionType.income);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = TransactionType.expense;
      _selectedCategory = 'Food';
      _selectedDate = DateTime.now();
      _voiceTranscription = null;
      _selectedImage = null;
      _currentEntryMethod = EntryMethod.manual;
    });
  }

  String _getTransactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.loanGiven:
        return 'Loan Given';
      case TransactionType.loanReceived:
        return 'Loan Received';
    }
  }

  IconData _getMethodIcon(EntryMethod method) {
    switch (method) {
      case EntryMethod.voice:
        return Icons.mic;
      case EntryMethod.image:
        return Icons.camera_alt;
      case EntryMethod.ai:
        return Icons.auto_awesome;
      default:
        return Icons.edit;
    }
  }

  String _getMethodLabel(EntryMethod method) {
    switch (method) {
      case EntryMethod.voice:
        return 'Voice Entry';
      case EntryMethod.image:
        return 'Camera Entry';
      case EntryMethod.ai:
        return 'AI Entry';
      default:
        return 'Manual Entry';
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _handleVoiceInput() async {
    final subscription = context.read<SubscriptionProvider>().subscription;
    if (subscription != null && !subscription.canUseFeature('voiceEntries')) {
      _showFeatureLimitDialog('voice entries');
      return;
    }

    // Initialize voice service
    final voiceInitialized = await VoiceService.initialize();
    if (!voiceInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission denied'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String transcriptionText = '';
    bool isListeningState = false;
    bool isProcessingState = false;
    bool shouldAutoAdd = false;
    Map<String, dynamic>? processedResult;

    // Show voice processing dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            // Start listening after dialog is shown
            if (!isListeningState && !isProcessingState) {
              Future.delayed(const Duration(milliseconds: 300), () async {
                setDialogState(() {
                  isListeningState = true;
                });
                
                try {
                  await VoiceService.startListening(
                    onResult: (text) {
                      setDialogState(() {
                        transcriptionText = text;
                      });
                    },
                    onListening: () {
                      // Already set to listening
                    },
                    onComplete: () async {
                      if (transcriptionText.isNotEmpty) {
                        setDialogState(() {
                          isListeningState = false;
                          isProcessingState = true;
                        });
                        
                        // Process with AI
                        await Future.delayed(const Duration(milliseconds: 500));
                        
                        try {
                          final transactionProvider = context.read<TransactionProvider>();
                          processedResult = await transactionProvider.processVoiceCommand(transcriptionText);
                          
                          if (processedResult != null && 
                              processedResult!['amount'] != null && 
                              processedResult!['amount'] > 0) {
                            shouldAutoAdd = true;
                          }
                          
                          // Close dialog
                          if (mounted) Navigator.pop(dialogContext);
                          
                        } catch (e) {
                          if (mounted) Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        // No transcription
                        if (mounted) Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No voice detected. Please speak clearly.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  );
                } catch (e) {
                  if (mounted) Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Voice error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            }
            
            return VoiceProcessingDialog(
              transcription: transcriptionText,
              isListening: isListeningState,
              isProcessing: isProcessingState,
              onCancel: () {
                VoiceService.stopListening();
                Navigator.pop(dialogContext);
              },
            );
          },
        );
      },
    );

    // Auto-add transaction if voice command was successfully processed
    if (shouldAutoAdd && processedResult != null) {
      await _autoAddTransaction(
        amount: processedResult!['amount'].toDouble(),
        description: processedResult!['description'] ?? transcriptionText,
        category: processedResult!['category'] ?? 'Other',
        type: _getTransactionType(processedResult!['type']),
        entryMethod: EntryMethod.voice,
        transcription: transcriptionText,
      );
    }
  }
  
  Future<void> _handleGalleryInput() async {
    final subscription = context.read<SubscriptionProvider>().subscription;
    if (subscription != null && !subscription.canUseFeature('imageEntries')) {
      _showFeatureLimitDialog('image entries');
      return;
    }
    
    final image = await ImageProcessingService.pickImageFromGallery();
    if (image != null) {
      await _processImage(image);
    }
  }
  
  Future<void> _handleCameraInput() async {
    final subscription = context.read<SubscriptionProvider>().subscription;
    if (subscription != null && !subscription.canUseFeature('imageEntries')) {
      _showFeatureLimitDialog('image entries');
      return;
    }
    
    final image = await ImageProcessingService.captureImageFromCamera();
    if (image != null) {
      await _processImage(image);
    }
  }
  
  Future<void> _processImage(File image) async {
    setState(() {
      _selectedImage = image;
      _isProcessing = true;
    });
    
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Analyzing receipt...'),
                const SizedBox(height: 8),
                Text(
                  'This may take a moment',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      final processedBytes = await ImageProcessingService.processImage(image);
      final imageBytes = processedBytes ?? await image.readAsBytes();
      final transactionProvider = context.read<TransactionProvider>();
      final result = await transactionProvider.analyzeReceipt(imageBytes);

      if (!mounted) return;
      Navigator.pop(context);

      if (result != null && result['total_amount'] != null) {
        final parsedDate = result['date'] != null
            ? DateTime.tryParse(result['date'].toString())
            : null;

        await _autoAddTransaction(
          amount: (result['total_amount'] as num).toDouble(),
          description: result['description']?.toString() ?? 'Receipt',
          category: result['category']?.toString() ?? 'Other',
          type: TransactionType.expense,
          entryMethod: EntryMethod.image,
          image: image,
          date: parsedDate ?? DateTime.now(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not analyze receipt. Please try another image.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<void> _autoAddTransaction({
    required double amount,
    required String description,
    required String category,
    required TransactionType type,
    required EntryMethod entryMethod,
    String? transcription,
    File? image,
    DateTime? date,
  }) async {
    final userId = context.read<UserProvider>().user?.id ?? FirebaseService.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again to save transactions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Upload image if provided
    String? imagePath;
    if (image != null) {
      imagePath = await FirebaseService.uploadImage(userId, image.path);
    }
    
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      amount: amount,
      category: category,
      description: description,
      date: date ?? DateTime.now(),
      entryMethod: entryMethod,
      imagePath: imagePath,
      metadata: transcription != null ? {'transcription': transcription} : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final success = await context.read<TransactionProvider>().addTransaction(transaction);
    
    if (success) {
      // Show notification
      await NotificationService.showTransactionConfirmation(
        type: type.name,
        amount: transaction.amount,
        category: transaction.category,
      );
      
      // Show success message with undo option
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added: ${type == TransactionType.income ? '+' : '-'}৳${amount.toStringAsFixed(2)} for $description',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                final deleted = await context.read<TransactionProvider>().deleteTransaction(transaction.id);
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction removed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } else {
      final providerError = context.read<TransactionProvider>().error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              providerError.isNotEmpty ? providerError : 'Failed to add transaction',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  TransactionType _getTransactionType(String? type) {
    switch (type) {
      case 'income':
        return TransactionType.income;
      case 'loan_given':
        return TransactionType.loanGiven;
      case 'loan_received':
        return TransactionType.loanReceived;
      default:
        return TransactionType.expense;
    }
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = context.read<UserProvider>().user?.id ?? FirebaseService.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to add transactions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    // Upload image if selected
    String? imagePath;
    if (_selectedImage != null) {
      imagePath = await FirebaseService.uploadImage(userId, _selectedImage!.path);
    }
    
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: userId,
      type: _selectedType,
      amount: double.parse(_amountController.text.replaceAll(',', '').trim()),
      category: _selectedCategory,
      description: _descriptionController.text,
      date: _selectedDate,
      entryMethod: _currentEntryMethod ?? EntryMethod.manual,
      imagePath: imagePath,
      metadata: _voiceTranscription != null ? {'transcription': _voiceTranscription} : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final success = await context.read<TransactionProvider>().addTransaction(transaction);
    
    if (success) {
      // Show notification
      await NotificationService.showTransactionConfirmation(
        type: _selectedType.name,
        amount: transaction.amount,
        category: transaction.category,
      );
      
      // Clear form
      _resetForm();
      setState(() {
        _isProcessing = false;
        _showManualEntry = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _isProcessing = false;
      });
      
      final providerError = context.read<TransactionProvider>().error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              providerError.isNotEmpty ? providerError : 'Failed to add transaction',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showFeatureLimitDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Limit Reached'),
        content: Text('You have reached your monthly limit for $feature. Upgrade your plan to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

