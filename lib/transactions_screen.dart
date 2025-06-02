import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Get current user ID
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Others'
  ];

  // Add transaction with validation and user ID
  void _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add transactions'))
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final amount = double.parse(_amountController.text);
      
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid, // Add user ID
        'amount': amount,
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'date': _selectedDate,
        'type': amount > 0 ? 'earning' : 'expense',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reset form
      _amountController.clear();
      _descController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete transaction with confirmation
  void _deleteTransaction(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('transactions').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted'))
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.toString()}'))
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Date picker with initial selection
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Format currency display
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 2,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view transactions'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
      body: Column(
        children: [
          // Add Transaction Form
          // Card(
          //   margin: const EdgeInsets.all(10),
          //   elevation: 3,
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Form(
          //       key: _formKey,
          //       child: Column(
          //         children: [
          //           TextFormField(
          //             controller: _amountController,
          //             keyboardType: const TextInputType.numberWithOptions(decimal: true),
          //             decoration: const InputDecoration(
          //               labelText: 'Amount (+ for income, - for expense)',
          //               prefixIcon: Icon(Icons.attach_money),
          //             ),
          //             validator: (value) {
          //               if (value == null || value.isEmpty) return 'Enter amount';
          //               final amount = double.tryParse(value);
          //               if (amount == null) return 'Invalid number';
          //               return null;
          //             },
          //           ),
          //           const SizedBox(height: 16),
          //           TextFormField(
          //             controller: _descController,
          //             decoration: const InputDecoration(
          //               labelText: 'Description',
          //               prefixIcon: Icon(Icons.description),
          //             ),
          //             validator: (value) {
          //               if (value == null || value.isEmpty) return 'Enter description';
          //               if (value.length < 3) return 'Too short';
          //               return null;
          //             },
          //           ),
          //           const SizedBox(height: 16),
          //           Row(
          //             children: [
          //               Expanded(
          //                 child: DropdownButtonFormField<String>(
          //                   value: _selectedCategory,
          //                   items: _categories.map((cat) {
          //                     return DropdownMenuItem(
          //                       value: cat,
          //                       child: Text(cat),
          //                     );
          //                   }).toList(),
          //                   onChanged: (val) => setState(() => _selectedCategory = val!),
          //                   decoration: const InputDecoration(
          //                     labelText: 'Category',
          //                     border: OutlineInputBorder(),
          //                   ),
          //                 ),
          //               ),
          //               const SizedBox(width: 16),
          //               Expanded(
          //                 child: TextButton.icon(
          //                   style: TextButton.styleFrom(
          //                     padding: const EdgeInsets.symmetric(vertical: 16),
          //                     backgroundColor: Colors.grey[200],
          //                   ),
          //                   onPressed: _pickDate,
          //                   icon: const Icon(Icons.calendar_today),
          //                   label: Text(
          //                     DateFormat.yMd().format(_selectedDate),
          //                     style: const TextStyle(fontSize: 16),
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //           const SizedBox(height: 16),
          //           ElevatedButton.icon(
          //             style: ElevatedButton.styleFrom(
          //               minimumSize: const Size.fromHeight(50),
          //             ),
          //             onPressed: _isLoading ? null : _addTransaction,
          //             icon: const Icon(Icons.add),
          //             label: const Text("Add Transaction"),
          //           )
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          const Divider(height: 20),
          // Transaction List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('userId', isEqualTo: userId) // Filter by user ID
                      .snapshots(),
                  builder: (context, snapshot) {
                    double total = 0;
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        total += (doc['amount'] as num).toDouble();
                      }
                    }
                    return Text(
                      'Total: ${_formatCurrency(total)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Transaction List
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: userId) // Filter by user ID
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet\nAdd your first expense!', 
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  );
                }
                
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num).toDouble();
                    final date = (data['date'] as Timestamp).toDate();
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: amount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            amount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: amount > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          data['description'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat.yMMMd().format(date),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(amount.abs()),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: amount > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['category'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showTransactionDetails(docs[i].id, data),
                        onLongPress: () => _deleteTransaction(docs[i].id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Show transaction details
  void _showTransactionDetails(String id, Map<String, dynamic> data) {
    final amount = (data['amount'] as num).toDouble();
    final date = (data['date'] as Timestamp).toDate();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${_formatCurrency(amount)}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Description: ${data['description']}'),
            const SizedBox(height: 10),
            Text('Category: ${data['category']}'),
            const SizedBox(height: 10),
            Text('Date: ${DateFormat.yMMMd().add_jm().format(date)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTransaction(id);
            },
          ),
        ],
      ),
    );
  }
}