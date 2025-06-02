
import 'package:chatapp/page5_main_service.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'tax_profile_model.dart';
import 'tax_calculator.dart';

class TaxProfileScreen extends StatefulWidget {
  const TaxProfileScreen({Key? key}) : super(key: key);

  @override
  State<TaxProfileScreen> createState() => _TaxProfileScreenState();
}

class _TaxProfileScreenState extends State<TaxProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TabController? _tabController;
  BangladeshTaxProfile? _taxProfile;
  bool _isLoading = true;
  bool _isGeneratingAdvice = false;
  bool _isSaving = false;
  String _taxAdvice = '';
  String? _lastError; // Added for better error handling
  double _estimatedTax = 0;
  double _taxSavingPotential = 0;
  final GeminiService _geminiService = GeminiService();

  // Controllers for better form management
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProfile();
    _checkServiceStatus(); // Added service status check
  }

  @override
  void dispose() {
    _tabController?.dispose();
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // Helper methods for safe calculations
  double get totalIncome => _taxProfile?.incomeSources.values.fold(0.0, (a, b) => a! + b) ?? 0.0;
  double get totalExpenses => _taxProfile?.lifestyleExpenses.values.fold(0.0, (a, b) => a! + b) ?? 0.0;
  double get totalInvestments => _taxProfile?.investments.values.fold(0.0, (a, b) => a! + b) ?? 0.0;
  double get totalAssets => _taxProfile?.assets.values.fold(0.0, (a, b) => a! + b) ?? 0.0;

  // Check service status on init
  Future<void> _checkServiceStatus() async {
    if (!_geminiService.isUserAuthenticated) {
      setState(() => _lastError = 'Please log in to use AI tax advice features');
      return;
    }

    final status = _geminiService.getServiceStatus();
    if (!status['aiService']['configured']) {
      setState(() => _lastError = 'AI service not configured. Tax advice features may not work.');
    }
  }

  Future<void> _loadProfile() async {
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _lastError = 'Please log in to manage your tax profile';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('taxProfiles')
          .doc(userId!)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _taxProfile = BangladeshTaxProfile.fromJson(doc.data()!);
          _isLoading = false;
          _estimatedTax = BangladeshTaxCalculator.calculateTax(_taxProfile!);
          _calculateTaxSavingPotential();
        });
        _initializeControllers();
      } else {
        setState(() {
          _taxProfile = _createDefaultProfile();
          _isLoading = false;
          _estimatedTax = BangladeshTaxCalculator.calculateTax(_taxProfile!);
          _calculateTaxSavingPotential();
        });
        _initializeControllers();
      }
    } catch (e) {
      print("Error loading tax profile: $e");
      setState(() {
        _taxProfile = _createDefaultProfile();
        _isLoading = false;
        _lastError = 'Error loading profile: ${e.toString()}';
      });
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    if (_taxProfile == null) return;
    
    _controllers['name'] = TextEditingController(text: _taxProfile!.name);
    _controllers['nid'] = TextEditingController(text: _taxProfile!.nid);
    _controllers['tin'] = TextEditingController(text: _taxProfile!.tin);
    _controllers['circle'] = TextEditingController(text: _taxProfile!.circle);
    _controllers['taxZone'] = TextEditingController(text: _taxProfile!.taxZone);
    _controllers['assessmentYear'] = TextEditingController(text: _taxProfile!.assessmentYear);
    _controllers['address'] = TextEditingController(text: _taxProfile!.address);
    _controllers['phone'] = TextEditingController(text: _taxProfile!.phone);
    _controllers['email'] = TextEditingController(text: _taxProfile!.email);
    _controllers['employerName'] = TextEditingController(text: _taxProfile!.employerName ?? '');
  }

BangladeshTaxProfile _createDefaultProfile() {
  final user = FirebaseAuth.instance.currentUser;
  return BangladeshTaxProfile(
    name: user?.displayName ?? "Enter Your Name",
    nid: "",
    tin: "",
    circle: "Circle-008 (Salary)",
    taxZone: "Dhaka",
    assessmentYear: "2024-2025",
    // Added missing required fields
    annualIncome: 0.0,
    age: 25, // Default age, can be updated later
    gender: "Male", // Default gender, can be updated later
    dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 30)),
    address: "",
    phone: "",
    email: user?.email ?? "",
    employerName: "",
    isFemale: false,
    isSeniorCitizen: false,
    isDisabled: false,
    totalIncome: 0,
    taxableIncome: 0,
    taxExemptIncome: 0,
    taxLiability: 0,
    taxPaid: 0,
    incomeSources: {
      "Salary": 0,
      "Business": 0,
      "Rental": 0,
      "Investment": 0,
    },
    investments: {
      "Life Insurance": 0,
      "DPS/Pension": 0,
      "Government Securities": 0,
      "Stock Market": 0,
      "Mutual Funds": 0,
    },
    lifestyleExpenses: {
      "Housing": 0,
      "Food & Daily": 0,
      "Transport": 0,
      "Healthcare": 0,
      "Education": 0,
      "Entertainment": 0,
    },
    assets: {
      "Cash & Bank": 0,
      "Property": 0,
      "Vehicles": 0,
      "Investments": 0,
      "Others": 0,
    },
  );
}

  void _calculateTaxSavingPotential() {
    if (_taxProfile == null) return;
    
    // Calculate potential savings with maximum investments
    final maxInvestment = (_taxProfile!.taxableIncome * 0.25).clamp(0, 1500000);
    final optimizedProfile = _taxProfile!.copyWith(
      investments: {
        ..._taxProfile!.investments,
        "Life Insurance": maxInvestment * 0.4,
        "DPS/Pension": maxInvestment * 0.3,
        "Government Securities": maxInvestment * 0.3,
      }
    );
    
    final currentTax = BangladeshTaxCalculator.calculateTax(_taxProfile!);
    final optimizedTax = BangladeshTaxCalculator.calculateTax(optimizedProfile);
    
    setState(() {
      _taxSavingPotential = currentTax - optimizedTax;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _taxProfile == null || userId == null) return;

    setState(() => _isSaving = true);

    try {
      // Update profile with controller values
      _updateProfileFromControllers();
      
      await FirebaseFirestore.instance
          .collection('taxProfiles')
          .doc(userId!)
          .set(_taxProfile!.toJson());

      _estimatedTax = BangladeshTaxCalculator.calculateTax(_taxProfile!);
      _calculateTaxSavingPotential();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tax profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updateProfileFromControllers() {
    if (_taxProfile == null) return;
    
    _taxProfile = _taxProfile!.copyWith(
      name: _controllers['name']?.text ?? _taxProfile!.name,
      nid: _controllers['nid']?.text ?? _taxProfile!.nid,
      tin: _controllers['tin']?.text ?? _taxProfile!.tin,
      circle: _controllers['circle']?.text ?? _taxProfile!.circle,
      taxZone: _controllers['taxZone']?.text ?? _taxProfile!.taxZone,
      assessmentYear: _controllers['assessmentYear']?.text ?? _taxProfile!.assessmentYear,
      address: _controllers['address']?.text ?? _taxProfile!.address,
      phone: _controllers['phone']?.text ?? _taxProfile!.phone,
      email: _controllers['email']?.text ?? _taxProfile!.email,
      employerName: _controllers['employerName']?.text,
    );
  }

  void _calculateTax() {
    if (_taxProfile == null) return;
    
    setState(() {
      _estimatedTax = BangladeshTaxCalculator.calculateTax(_taxProfile!);
      _calculateTaxSavingPotential();
    });
  }

  // UPDATED: Fixed to work with new AIResponse system
  Future<void> _generateTaxAdvice() async {
    if (_taxProfile == null || userId == null) {
      setState(() => _lastError = 'Tax profile or user authentication required');
      return;
    }

    // Check if user can use AI features
    if (!await _geminiService.canUseFeature('aiQueries')) {
      setState(() => _lastError = 'AI query limit reached. Please upgrade your plan.');
      return;
    }

    setState(() {
      _isGeneratingAdvice = true;
      _lastError = null; // Clear previous errors
    });

    try {
      // FIXED: Updated method call to include userId parameter and handle AIResponse
      final response = await _geminiService.getTaxOptimizationAdvice(_taxProfile!, userId!);
      
      if (response.success && response.text != null) {
        setState(() {
          _taxAdvice = response.text!;
          _lastError = null;
        });
      } else {
        setState(() {
          _taxAdvice = '';
          _lastError = response.error ?? 'Failed to generate tax advice';
        });
      }
    } catch (e) {
      print("Error generating tax advice: $e");
      setState(() {
        _taxAdvice = '';
        _lastError = "Error generating advice: ${e.toString()}";
      });
    } finally {
      setState(() => _isGeneratingAdvice = false);
    }
  }

  // UPDATED: Enhanced to show usage limits and warnings
  Future<void> _checkAIUsageLimits() async {
    try {
      final usage = await _geminiService.getCurrentUsage();
      final limits = await _geminiService.getPlanLimits();
      final percentages = await _geminiService.getUsagePercentages();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Usage Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Queries: ${usage.aiQueries}/${limits.aiQueries}'),
              LinearProgressIndicator(
                value: percentages['aiQueries']! / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentages['aiQueries']! > 80 ? Colors.red : Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              if (percentages['aiQueries']! > 80)
                const Text(
                  'You\'re near your AI query limit. Consider upgrading your plan.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error checking usage limits: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to manage your tax profile'),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tax Profile Management"),
        elevation: 0,
        actions: [
          // ADDED: Usage status button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _checkAIUsageLimits,
            tooltip: 'Check AI Usage',
          ),
          IconButton(
            icon: _isSaving 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
        bottom: _tabController == null 
          ? null 
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              // labelColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.person, ), text: 'Personal'),
                Tab(icon: Icon(Icons.attach_money, ), text: 'Income'),
                Tab(icon: Icon(Icons.trending_down, ), text: 'Expenses'),
                Tab(icon: Icon(Icons.account_balance, ), text: 'Tax & Benefits'),
                Tab(icon: Icon(Icons.analytics, ), text: 'Analysis'),
              ],
            ),
      ),

      

      
      body: Column(
        children: [
          // ADDED: Error display banner
          if (_lastError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastError!,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _lastError = null),
                  ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: _tabController == null 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalTab(),
                    _buildIncomeTab(),
                    _buildExpensesTab(),
                    _buildTaxBenefitsTab(),
                    _buildAnalysisTab(),
                  ],
                ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _saveProfile,
      //   icon: const Icon(Icons.save),
      //   label: const Text('Save Profile'),
      // ),
    );
  }

  // Personal Information Tab
  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information', Icons.person),
            const SizedBox(height: 16),
            
            _buildEnhancedTextField(
              controller: _controllers['name']!,
              label: 'Full Name',
              icon: Icons.person_outline,
              required: true,
            ),
            
            _buildEnhancedTextField(
              controller: _controllers['nid']!,
              label: 'National ID (NID)',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              maxLength: 17,
              required: true,
            ),
            
            _buildEnhancedTextField(
              controller: _controllers['tin']!,
              label: 'Taxpayer Identification Number (TIN)',
              icon: Icons.assignment_ind,
              keyboardType: TextInputType.number,
              maxLength: 12,
              required: true,
            ),
            
            _buildDatePickerField(),
            
            _buildEnhancedTextField(
              controller: _controllers['address']!,
              label: 'Address',
              icon: Icons.location_on,
              maxLines: 2,
              required: true,
            ),
            
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedTextField(
                    controller: _controllers['phone']!,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedTextField(
                    controller: _controllers['email']!,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    required: true,
                  ),
                ),
              ],
            ),
            
            _buildEnhancedTextField(
              controller: _controllers['employerName']!,
              label: 'Employer Name (Optional)',
              icon: Icons.business,
            ),
            
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedTextField(
                    controller: _controllers['taxZone']!,
                    label: 'Tax Zone',
                    icon: Icons.location_city,
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedTextField(
                    controller: _controllers['circle']!,
                    label: 'Tax Circle',
                    icon: Icons.account_balance,
                    required: true,
                  ),
                ),
              ],
            ),
            
            _buildEnhancedTextField(
              controller: _controllers['assessmentYear']!,
              label: 'Assessment Year',
              icon: Icons.calendar_today,
              required: true,
            ),
          ],
        ),
      ),
    );
  }

  // Income Tab
  Widget _buildIncomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Income Sources', Icons.attach_money),
          const SizedBox(height: 16),
          
          // Total Income Summary Card
          _buildSummaryCard(
            'Total Annual Income',
            totalIncome,
            Colors.green,
            Icons.trending_up,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('Income Breakdown'),
          
          ..._taxProfile!.incomeSources.entries.map((entry) {
            return _buildIncomeSourceCard(entry.key, entry.value);
          }),
          
          const SizedBox(height: 16),
          _buildAddButton('Add Income Source', () => _addIncomeSource()),
          
          const SizedBox(height: 20),
          _buildSectionTitle('Tax Calculation'),
          
          _buildNumberField(
            'Total Income',
            _taxProfile!.totalIncome,
            (val) => setState(() => _taxProfile = _taxProfile!.copyWith(totalIncome: val)),
            icon: Icons.account_balance_wallet,
          ),
          
          _buildNumberField(
            'Tax Exempt Income',
            _taxProfile!.taxExemptIncome,
            (val) => setState(() => _taxProfile = _taxProfile!.copyWith(taxExemptIncome: val)),
            icon: Icons.money_off,
          ),
          
          _buildNumberField(
            'Taxable Income',
            _taxProfile!.taxableIncome,
            (val) => setState(() => _taxProfile = _taxProfile!.copyWith(taxableIncome: val)),
            icon: Icons.monetization_on,
          ),
        ],
      ),
    );
  }

  // Expenses Tab
  Widget _buildExpensesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Lifestyle Expenses', Icons.trending_down),
          const SizedBox(height: 16),
          
          // Total Expenses Summary Card
          _buildSummaryCard(
            'Total Annual Expenses',
            totalExpenses,
            Colors.red,
            Icons.trending_down,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('Expense Breakdown'),
          
          ..._taxProfile!.lifestyleExpenses.entries.map((entry) {
            return _buildExpenseCard(entry.key, entry.value);
          }),
          
          const SizedBox(height: 16),
          _buildAddButton('Add Expense Category', () => _addExpenseCategory()),
          
          const SizedBox(height: 20),
          _buildSectionTitle('Assets'),
          
          ..._taxProfile!.assets.entries.map((entry) {
            return _buildAssetCard(entry.key, entry.value);
          }),
          
          const SizedBox(height: 16),
          _buildAddButton('Add Asset', () => _addAsset()),
        ],
      ),
    );
  }

  // Tax & Benefits Tab
  Widget _buildTaxBenefitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tax Benefits & Investments', Icons.account_balance),
          const SizedBox(height: 16),
          
          // Tax Benefits
          _buildSectionTitle('Tax Benefit Categories'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Female Taxpayer (25% discount)',
                    _taxProfile!.isFemale,
                    (value) => setState(() => _taxProfile = _taxProfile!.copyWith(isFemale: value)),
                    Icons.female,
                  ),
                  _buildSwitchTile(
                    'Senior Citizen 65+ (25% discount)',
                    _taxProfile!.isSeniorCitizen,
                    (value) => setState(() => _taxProfile = _taxProfile!.copyWith(isSeniorCitizen: value)),
                    Icons.elderly,
                  ),
                  _buildSwitchTile(
                    'Person with Disability (50% discount)',
                    _taxProfile!.isDisabled,
                    (value) => setState(() => _taxProfile = _taxProfile!.copyWith(isDisabled: value)),
                    Icons.accessible,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Investment Summary
          _buildSummaryCard(
            'Total Investments',
            totalInvestments,
            Colors.blue,
            Icons.trending_up,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('Investment Portfolio'),
          
          ..._taxProfile!.investments.entries.map((entry) {
            return _buildInvestmentCard(entry.key, entry.value);
          }),
          
          const SizedBox(height: 16),
          _buildAddButton('Add Investment', () => _addInvestment()),
          
          const SizedBox(height: 20),
          _buildNumberField(
            'Tax Already Paid',
            _taxProfile!.taxPaid,
            (val) => setState(() => _taxProfile = _taxProfile!.copyWith(taxPaid: val)),
            icon: Icons.payment,
          ),
        ],
      ),
    );
  }

  // UPDATED: Enhanced Analysis Tab with better AI integration
  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tax Analysis & Optimization', Icons.analytics),
          const SizedBox(height: 16),
          
          // Tax Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Estimated Tax',
                  _estimatedTax,
                  Colors.orange,
                  Icons.calculate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Potential Savings',
                  _taxSavingPotential,
                  Colors.green,
                  Icons.savings,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Tax Calculation Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _calculateTax,
                          icon: const Icon(Icons.calculate),
                          label: const Text('Recalculate Tax'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingAdvice ? null : _generateTaxAdvice,
                          icon: _isGeneratingAdvice 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lightbulb_outline),
                          label: Text(_isGeneratingAdvice ? 'Generating...' : 'Get AI Advice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_estimatedTax > 0) ...[
                    Text(
                      'Estimated Annual Tax: ৳${_estimatedTax.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Monthly Tax: ৳${(_estimatedTax / 12).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Tax Slabs Information
          _buildTaxSlabsCard(),
          
          const SizedBox(height: 20),
          
          // UPDATED: Enhanced AI Tax Advice Section
          if (_isGeneratingAdvice)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Generating personalized tax advice...'),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few moments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_taxAdvice.isNotEmpty)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'AI Tax Optimization Advice',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _taxAdvice,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _checkAIUsageLimits,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Usage Limits'),
                        ),
                        TextButton.icon(
                          onPressed: _generateTaxAdvice,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Advice'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Get Personalized Tax Advice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Click "Get AI Advice" to receive personalized tax optimization recommendations based on your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateTaxAdvice,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Get AI Tax Advice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper Widgets (keeping all existing helper widgets but updated where needed)

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: required
          ? (value) => value?.isEmpty == true ? '$label is required' : null
          : null,
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date of Birth'),
          subtitle: Text(DateFormat('dd MMM yyyy').format(_taxProfile!.dateOfBirth)),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _taxProfile!.dateOfBirth,
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _taxProfile = _taxProfile!.copyWith(dateOfBirth: date));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '৳${value.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    double value,
    Function(double) onChanged, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value.toStringAsFixed(0),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '৳',
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (val) => onChanged(double.tryParse(val) ?? 0),
      ),
    );
  }

  Widget _buildIncomeSourceCard(String name, double amount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.attach_money, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    initialValue: amount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '৳',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final newIncomeSources = Map<String, double>.from(_taxProfile!.incomeSources);
                      newIncomeSources[name] = double.tryParse(val) ?? 0;
                      setState(() => _taxProfile = _taxProfile!.copyWith(incomeSources: newIncomeSources));
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeIncomeSource(name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(String name, double amount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.trending_down, color: Colors.red[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    initialValue: amount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '৳',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final newExpenses = Map<String, double>.from(_taxProfile!.lifestyleExpenses);
                      newExpenses[name] = double.tryParse(val) ?? 0;
                      setState(() => _taxProfile = _taxProfile!.copyWith(lifestyleExpenses: newExpenses));
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeExpenseCategory(name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(String name, double amount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.trending_up, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '15% tax rebate applicable',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: amount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '৳',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final newInvestments = Map<String, double>.from(_taxProfile!.investments);
                      newInvestments[name] = double.tryParse(val) ?? 0;
                      setState(() => _taxProfile = _taxProfile!.copyWith(investments: newInvestments));
                      _calculateTaxSavingPotential();
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeInvestment(name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(String name, double amount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.purple[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    initialValue: amount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '৳',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final newAssets = Map<String, double>.from(_taxProfile!.assets);
                      newAssets[name] = double.tryParse(val) ?? 0;
                      setState(() => _taxProfile = _taxProfile!.copyWith(assets: newAssets));
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeAsset(name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.teal,
      ),
    );
  }

  Widget _buildAddButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTaxSlabsCard() {
    final slabs = BangladeshTaxCalculator.getTaxSlabs();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Bangladesh Tax Slabs 2024-25',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...slabs.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.right,
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

  // Add/Remove Functions (keeping all existing functions unchanged)

  void _addIncomeSource() {
    showDialog(
      context: context,
      builder: (context) => _buildAddDialog(
        title: 'Add Income Source',
        hint: 'e.g., Freelancing, Rent, etc.',
        onAdd: (name) {
          final newIncomeSources = Map<String, double>.from(_taxProfile!.incomeSources);
          newIncomeSources[name] = 0;
          setState(() => _taxProfile = _taxProfile!.copyWith(incomeSources: newIncomeSources));
        },
      ),
    );
  }

  void _addExpenseCategory() {
    showDialog(
      context: context,
      builder: (context) => _buildAddDialog(
        title: 'Add Expense Category',
        hint: 'e.g., Insurance, Utilities, etc.',
        onAdd: (name) {
          final newExpenses = Map<String, double>.from(_taxProfile!.lifestyleExpenses);
          newExpenses[name] = 0;
          setState(() => _taxProfile = _taxProfile!.copyWith(lifestyleExpenses: newExpenses));
        },
      ),
    );
  }

  void _addInvestment() {
    showDialog(
      context: context,
      builder: (context) => _buildAddDialog(
        title: 'Add Investment',
        hint: 'e.g., PPF, NSC, FDR, etc.',
        onAdd: (name) {
          final newInvestments = Map<String, double>.from(_taxProfile!.investments);
          newInvestments[name] = 0;
          setState(() => _taxProfile = _taxProfile!.copyWith(investments: newInvestments));
        },
      ),
    );
  }

  void _addAsset() {
    showDialog(
      context: context,
      builder: (context) => _buildAddDialog(
        title: 'Add Asset',
        hint: 'e.g., Jewelry, Bonds, etc.',
        onAdd: (name) {
          final newAssets = Map<String, double>.from(_taxProfile!.assets);
          newAssets[name] = 0;
          setState(() => _taxProfile = _taxProfile!.copyWith(assets: newAssets));
        },
      ),
    );
  }

  Widget _buildAddDialog({
    required String title,
    required String hint,
    required Function(String) onAdd,
  }) {
    final controller = TextEditingController();
    
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              onAdd(controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _removeIncomeSource(String name) {
    _showRemoveDialog('Remove Income Source', name, () {
      final newIncomeSources = Map<String, double>.from(_taxProfile!.incomeSources);
      newIncomeSources.remove(name);
      setState(() => _taxProfile = _taxProfile!.copyWith(incomeSources: newIncomeSources));
    });
  }

  void _removeExpenseCategory(String name) {
    _showRemoveDialog('Remove Expense Category', name, () {
      final newExpenses = Map<String, double>.from(_taxProfile!.lifestyleExpenses);
      newExpenses.remove(name);
      setState(() => _taxProfile = _taxProfile!.copyWith(lifestyleExpenses: newExpenses));
    });
  }

  void _removeInvestment(String name) {
    _showRemoveDialog('Remove Investment', name, () {
      final newInvestments = Map<String, double>.from(_taxProfile!.investments);
      newInvestments.remove(name);
      setState(() => _taxProfile = _taxProfile!.copyWith(investments: newInvestments));
      _calculateTaxSavingPotential();
    });
  }

  void _removeAsset(String name) {
    _showRemoveDialog('Remove Asset', name, () {
      final newAssets = Map<String, double>.from(_taxProfile!.assets);
      newAssets.remove(name);
      setState(() => _taxProfile = _taxProfile!.copyWith(assets: newAssets));
    });
  }

  void _showRemoveDialog(String title, String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Are you sure you want to remove "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}