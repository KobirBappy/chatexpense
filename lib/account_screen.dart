
/// enhanced_account_screen.dart

import 'package:chatapp/page1_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EnhancedAccountScreen extends StatefulWidget {
  const EnhancedAccountScreen({super.key});

  @override
  _EnhancedAccountScreenState createState() => _EnhancedAccountScreenState();
}

class _EnhancedAccountScreenState extends State<EnhancedAccountScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _currentPlan = 'Free';
  bool _isLoading = true;
  Usage _currentUsage = Usage.zero();
  DateTime? _resetDate;
  late TabController _tabController;

  // Profile editing controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditingProfile = false;

  String? get userId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (userId != null) {
      _loadData();
      _initializeControllers();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController.text = currentUser?.displayName ?? '';
  }

  Future<void> _loadData() async {
    if (userId == null) return;
    
    try {
      final futures = await Future.wait([
        _firestore.collection('users').doc(userId!).get(),
        _firestore.collection('usage').doc(userId!).get(),
      ]);
      
      final userDoc = futures[0];
      final usageDoc = futures[1];
      
      setState(() {
        _currentPlan = userDoc.data()?['subscription_plan'] ?? 'Free';
        
        if (usageDoc.exists) {
          final data = usageDoc.data()!;
          _currentUsage = Usage(
            chatMessages: data['chatMessages'] ?? 0,
            imageEntries: data['imageEntries'] ?? 0,
            voiceEntries: data['voiceEntries'] ?? 0,
            aiQueries: data['aiQueries'] ?? 0,
          );
          _resetDate = (data['resetDate'] as Timestamp?)?.toDate();
        } else {
          _currentUsage = Usage.zero();
        }
        
        // Load additional profile data
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _nameController.text = userData['displayName'] ?? currentUser?.displayName ?? '';
          _phoneController.text = userData['phone'] ?? '';
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading account data: $e');
      _showErrorSnackBar('Failed to load account data');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSubscription(String plan) async {
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(userId!).update({
        'subscription_plan': plan,
        'subscription_date': FieldValue.serverTimestamp(),
      });
      setState(() {
        _currentPlan = plan;
        _isLoading = false;
      });
      _showSuccessSnackBar('$plan plan activated successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to update subscription: ${e.toString()}');
    }
  }

  Future<void> _updateProfile() async {
    if (userId == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Update Firebase Auth profile
      await currentUser?.updateDisplayName(_nameController.text);
      
      // Update Firestore user document
      await _firestore.collection('users').doc(userId!).update({
        'displayName': _nameController.text,
        'phone': _phoneController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _isEditingProfile = false;
        _isLoading = false;
      });
      
      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    }
  }

  Future<void> _exportData() async {
    try {
      setState(() => _isLoading = true);
      
      // Simulate data export
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() => _isLoading = false);
      _showSuccessSnackBar('Data export initiated! Check your email for download link.');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to export data');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to sign out');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view account information',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: _loadData,
        //     tooltip: 'Refresh',
        //   ),
        //   PopupMenuButton<String>(
        //     onSelected: (value) {
        //       switch (value) {
        //         case 'export':
        //           _exportData();
        //           break;
        //         case 'logout':
        //           _showLogoutDialog();
        //           break;
        //       }
        //     },
        //     itemBuilder: (context) => [
        //       const PopupMenuItem(
        //         value: 'export',
        //         child: Row(
        //           children: [
        //             Icon(Icons.download),
        //             SizedBox(width: 8),
        //             Text('Export Data'),
        //           ],
        //         ),
        //       ),
        //       const PopupMenuItem(
        //         value: 'logout',
        //         child: Row(
        //           children: [
        //             Icon(Icons.logout, color: Colors.red),
        //             SizedBox(width: 8),
        //             Text('Sign Out', style: TextStyle(color: Colors.red)),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ],
        bottom: TabBar(
          unselectedLabelColor: Colors.black,
          controller: _tabController,
          // labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.analytics), text: 'Usage'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Plans'),
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
                  Text('Loading account data...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildUsageTab(),
                _buildPlansTab(),
              ],
            ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: currentUser?.photoURL != null
                            ? NetworkImage(currentUser!.photoURL!)
                            : null,
                        child: currentUser?.photoURL == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: () {
                              _showSuccessSnackBar('Photo upload feature coming soon!');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditingProfile) ...[
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : 'No name set',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser?.email ?? 'No email',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phoneController.text.isNotEmpty ? _phoneController.text : 'No phone number',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditingProfile = true),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditingProfile = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Account Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow('Current Plan', _currentPlan, _getPlanColor(_currentPlan)),
                  _buildStatusRow('Member Since', _getMemberSince(), Colors.grey),
                  _buildStatusRow('Email Verified', 
                      currentUser?.emailVerified == true ? 'Yes' : 'No',
                      currentUser?.emailVerified == true ? Colors.green : Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: valueColor.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Usage Overview Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Usage',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (_resetDate != null)
                        Chip(
                          label: Text(
                            'Resets ${DateFormat.MMMd().format(_resetDate!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildEnhancedUsageItem(
                    'Chat Messages',
                    _currentUsage.chatMessages,
                    _getLimitFor('chatMessages'),
                    Icons.chat,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildEnhancedUsageItem(
                    'Image Entries',
                    _currentUsage.imageEntries,
                    _getLimitFor('imageEntries'),
                    Icons.image,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildEnhancedUsageItem(
                    'Voice Entries',
                    _currentUsage.voiceEntries,
                    _getLimitFor('voiceEntries'),
                    Icons.mic,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildEnhancedUsageItem(
                    'AI Queries',
                    _currentUsage.aiQueries,
                    _getLimitFor('aiQueries'),
                    Icons.psychology,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Usage Tips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Usage Tips',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Use voice entries for quick expense logging'),
                  _buildTipItem('Batch similar transactions to save AI queries'),
                  _buildTipItem('Upgrade to Pro for 5x more features'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  Widget _buildPlansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade anytime to unlock more features',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          _buildEnhancedPlanCard(
            planName: 'Free',
            price: 'Forever Free',
            features: const [
              '60 Chat Messages / Month',
              '10 Image Entries / Month',
              '10 Voice Entries / Month',
              '3 Custom Categories',
              'Unlimited Manual Entries',
              'Data retention limit is 90 days',
              '10 AI Queries / Month',
            ],
            isCurrent: _currentPlan == 'Free',
            buttonText: _currentPlan == 'Free' ? 'Current Plan' : 'Select Free',
            accentColor: Colors.teal,
          ),
          const SizedBox(height: 16),
          _buildEnhancedPlanCard(
            planName: 'Pro',
            price: '\$5.99 / month',
            subtitle: 'Most Popular',
            features: const [
              '250 Chat Messages / Month',
              '50 Image Entries / Month',
              '50 Voice Entries / month',
              '10 Custom Categories',
              'Unlimited Manual Entries',
              'Data retention limit is 180 days',
              '30 AI Queries / Month',
              'Priority Support',
            ],
            isCurrent: _currentPlan == 'Pro',
            buttonText: _currentPlan == 'Pro' ? 'Current Plan' : 'Upgrade to Pro',
            accentColor: Colors.blue,
            isRecommended: true,
          ),
          const SizedBox(height: 16),
          _buildEnhancedPlanCard(
            planName: 'Power User',
            price: '\$12.99 / month',
            subtitle: 'For Heavy Users',
            features: const [
              '1000 Chat Messages / month',
              '200 Image Entries / month',
              '200 Voice Entries / month',
              '25 Custom Categories',
              'Unlimited Manual Entries',
              'No data retention limit',
              'Data export in CSV format',
              '75 AI Queries / Month',
              'Advanced Analytics',
              'Premium Support',
            ],
            isCurrent: _currentPlan == 'Power User',
            buttonText: _currentPlan == 'Power User' ? 'Current Plan' : 'Upgrade to Power',
            accentColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedUsageItem(
    String title,
    int used,
    int total,
    IconData icon,
    Color color,
  ) {
    final percentage = total > 0 ? used / total : 0.0;
    Color barColor = color;
    if (percentage > 0.75) barColor = Colors.orange;
    if (percentage > 0.9) barColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$used / $total used',
                      style: TextStyle(
                        color: percentage > 0.9 ? Colors.red : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: percentage > 0.9 ? Colors.red : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            color: barColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlanCard({
    required String planName,
    required String price,
    String? subtitle,
    required List<String> features,
    required bool isCurrent,
    required String buttonText,
    Color accentColor = Colors.teal,
    bool isRecommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent || isRecommended ? accentColor : Colors.grey.shade300,
          width: isCurrent || isRecommended ? 2 : 1,
        ),
        gradient: isCurrent
            ? LinearGradient(
                colors: [accentColor.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (isRecommended && !isCurrent)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () => _updateSubscription(planName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey : accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isCurrent ? 0 : 2,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getMemberSince() {
    final user = currentUser;
    if (user?.metadata.creationTime != null) {
      return DateFormat.yMMMd().format(user!.metadata.creationTime!);
    }
    return 'Unknown';
  }

  Color _getPlanColor(String plan) {
    switch (plan) {
      case 'Pro': return Colors.blue;
      case 'Power User': return Colors.deepPurple;
      default: return Colors.teal;
    }
  }

  int _getLimitFor(String type) {
    switch (_currentPlan) {
      case 'Pro':
        switch (type) {
          case 'chatMessages': return 250;
          case 'imageEntries': return 50;
          case 'voiceEntries': return 50;
          case 'aiQueries': return 30;
          default: return 0;
        }
      case 'Power User':
        switch (type) {
          case 'chatMessages': return 1000;
          case 'imageEntries': return 200;
          case 'voiceEntries': return 200;
          case 'aiQueries': return 75;
          default: return 0;
        }
      default: // Free
        switch (type) {
          case 'chatMessages': return 60;
          case 'imageEntries': return 10;
          case 'voiceEntries': return 10;
          case 'aiQueries': return 10;
          default: return 0;
        }
    }
  }
}