// import 'dart:typed_data';
// import 'package:chatapp/tax_profile_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:intl/intl.dart';

// class GeminiService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _apiKey;

//   GeminiService() {
//     _loadEnv();
//   }

//   Future<void> _loadEnv() async {
//     await dotenv.load(fileName: ".env");
//     _apiKey = dotenv.env['GEMINI_API_KEY'];
//   }

//   Future<PlanLimits> getPlanLimits() async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception("User not authenticated");

//     final userDoc = await _firestore.collection('users').doc(user.uid).get();
//     final plan = userDoc['subscription_plan'] ?? 'Free';

//     switch (plan) {
//       case 'Pro':
//         return PlanLimits(
//           chatMessages: 250,
//           imageEntries: 50,
//           voiceEntries: 50,
//           aiQueries: 30,
//         );
//       case 'Power User':
//         return PlanLimits(
//           chatMessages: 1000,
//           imageEntries: 200,
//           voiceEntries: 200,
//           aiQueries: 75,
//         );
//       default: // Free
//         return PlanLimits(
//           chatMessages: 60,
//           imageEntries: 10,
//           voiceEntries: 10,
//           aiQueries: 10,
//         );
//     }
//   }

//   Future<Usage> getCurrentUsage() async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception("User not authenticated");

//     final doc = await _firestore.collection('usage').doc(user.uid).get();
//     if (doc.exists) {
//       return Usage(
//         chatMessages: doc['chatMessages'] ?? 0,
//         imageEntries: doc['imageEntries'] ?? 0,
//         voiceEntries: doc['voiceEntries'] ?? 0,
//         aiQueries: doc['aiQueries'] ?? 0,
//       );
//     }
//     return Usage.zero();
//   }

//   Future<void> incrementUsage(String type) async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     final now = DateTime.now();
//     final monthStart = DateTime(now.year, now.month, 1);

//     final usageRef = _firestore.collection('usage').doc(user.uid);
//     await _firestore.runTransaction((transaction) async {
//       final doc = await transaction.get(usageRef);

//       if (!doc.exists ||
//           (doc['resetDate'] as Timestamp).toDate().isBefore(monthStart)) {
//         transaction.set(usageRef, {
//           'chatMessages': 0,
//           'imageEntries': 0,
//           'voiceEntries': 0,
//           'aiQueries': 0,
//           'resetDate': Timestamp.fromDate(monthStart),
//         });
//       }

//       transaction.update(usageRef, {
//         type: FieldValue.increment(1),
//       });
//     });
//   }

//   Future<String?> getTextResponse(String input) async {
//     if (_apiKey == null) return 'API key not configured';

//     final usage = await getCurrentUsage();
//     final limits = await getPlanLimits();

//     if (usage.chatMessages >= limits.chatMessages) {
//       return 'Monthly chat message limit reached. Upgrade your plan.';
//     }

//     try {
//       final model = GenerativeModel(
//         model: 'gemini-1.5-flash',
//         apiKey: _apiKey!,
//         generationConfig: GenerationConfig(
//           maxOutputTokens: 500,
//           temperature: 0.7,
//         ),
//       );

//       final response = await model.generateContent([
//         Content.text("You're a helpful financial assistant. $input"),
//       ]);

//       await incrementUsage('chatMessages');
//       return response.text?.trim();
//     } catch (e) {
//       return "Connection issue. Please check your internet.";
//     }
//   }

//   Future<String?> processImage(Uint8List imageBytes) async {
//     if (_apiKey == null) return 'API key not configured';

//     final usage = await getCurrentUsage();
//     final limits = await getPlanLimits();

//     if (usage.imageEntries >= limits.imageEntries) {
//       return 'Image entry limit reached. Upgrade your plan.';
//     }

//     try {
//       final model = GenerativeModel(
//         model: 'gemini-1.5-pro',
//         apiKey: _apiKey!,
//         generationConfig: GenerationConfig(
//           maxOutputTokens: 500,
//           temperature: 0.7,
//         ),
//       );

//       final prompt = '''
//       Analyze this receipt/image and extract financial details. Return ONLY a JSON object with these keys:
//       - "amount" (number): The total amount
//       - "date" (string): Transaction date in YYYY-MM-DD format
//       - "category" (string): Financial category
//       - "description" (string): Brief description
//       - "type" (string): "expense" or "earning"
      
//       Example expense:
//       {
//         "amount": 15.99,
//         "date": "2023-11-15",
//         "category": "Food",
//         "description": "Coffee shop purchase",
//         "type": "expense"
//       }
      
//       Example earning:
//       {
//         "amount": 5000.00,
//         "date": "2023-11-20",
//         "category": "Freelance",
//         "description": "Web development project",
//         "type": "earning"
//       }
//       ''';

//       final response = await model.generateContent([
//         Content.multi([
//           TextPart(prompt),
//           DataPart('image/jpeg', imageBytes),
//         ])
//       ]);

//       await incrementUsage('imageEntries');
//       return response.text?.trim();
//     } catch (e) {
//       return "Image processing failed: ${e.toString()}";
//     }
//   }

//   Future<String> getTaxOptimizationAdvice(BangladeshTaxProfile profile) async {
//     final usage = await getCurrentUsage();
//     final limits = await getPlanLimits();
    
//     if (usage.aiQueries >= limits.aiQueries) {
//       return 'Monthly AI analysis limit reached. Upgrade your plan.';
//     }

//     try {
//       final model = GenerativeModel(
//         model: 'gemini-1.5-pro',
//         apiKey: _apiKey!,
//         generationConfig: GenerationConfig(
//           maxOutputTokens: 1500,
//           temperature: 0.4,
//         ),
//       );

//       final prompt = '''
//       As a tax consultant specializing in Bangladesh tax law, analyze this tax profile:
//       ${profile.toJson()}
      
//       Provide specific, actionable advice on:
//       1. Tax-saving investment opportunities under Section 44
//       2. Deductions available for this profile
//       3. Tax bracket optimization strategies
//       4. Compliance requirements for ${profile.assessmentYear}
//       5. Estimated tax liability reduction potential
      
//       Format your response with:
//       - Clear headings and bullet points
//       - Bangladeshi Taka (BDT) for all amounts
//       - Concrete examples based on the profile data
//       - Warnings about potential compliance issues
//       ''';
      
//       final response = await model.generateContent([Content.text(prompt)]);
//       await incrementUsage('aiQueries');
//       return response.text?.trim() ?? 'No advice generated.';
//     } catch (e) {
//       return "Tax advice generation failed: ${e.toString()}";
//     }
//   }

//   Future<String> generateFinancialReport() async {
//     final usage = await getCurrentUsage();
//     final limits = await getPlanLimits();

//     if (usage.aiQueries >= limits.aiQueries) {
//       return 'Monthly AI analysis limit reached. Upgrade your plan.';
//     }

//     final user = _auth.currentUser;
//     if (user == null) return 'User not authenticated. Please sign in.';

//     try {
//       final transactions = await _firestore
//           .collection('transactions')
//           .where('userId', isEqualTo: user.uid)
//           .orderBy('date', descending: true)
//           .get();

//       if (transactions.docs.isEmpty) {
//         return 'No transactions found. Add expenses/earnings to generate a report.';
//       }

//       final formatted = transactions.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         final amount = data['amount'];
//         final sign = amount < 0 ? '-' : '+';
//         return "${DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate())} | ${data['category']} | $sign${amount.abs().toStringAsFixed(2)} | ${data['description']}";
//       }).join('\n');

//       final prompt = '''
//       Analyze this financial data and create a comprehensive report:
//       $formatted

//       Include:
//       1. Spending vs earnings breakdown
//       2. Spending by category (percentages and amounts)
//       3. Monthly spending/earning trends
//       4. Largest expense categories
//       5. Potential savings opportunities
//       6. Financial health score (1-10)
//       7. Practical advice for improvement
//       8. Tax implications for Bangladesh based on:
//         - Current tax slabs
//         - Investment deductions
//         - Special categories (female, senior, disabled)
//         - NBR compliance requirements
//       9. Estimated tax liability for the year
//       10. Tax optimization strategies

//       Format as markdown with headings and bullet points.
//       ''';

//       final model = GenerativeModel(
//         model: 'gemini-1.5-pro',
//         apiKey: _apiKey!,
//         generationConfig: GenerationConfig(
//           maxOutputTokens: 2000,
//           temperature: 0.4,
//         ),
//       );

//       final response = await model.generateContent([Content.text(prompt)]);
//       await incrementUsage('aiQueries');
//       return response.text?.trim() ?? 'No response generated.';
//     } catch (e) {
//       return "Report generation failed: ${e.toString()}";
//     }
//   }
// }

// class PlanLimits {
//   final int chatMessages;
//   final int imageEntries;
//   final int voiceEntries;
//   final int aiQueries;

//   PlanLimits({
//     required this.chatMessages,
//     required this.imageEntries,
//     required this.voiceEntries,
//     required this.aiQueries,
//   });
// }

// class Usage {
//   final int chatMessages;
//   final int imageEntries;
//   final int voiceEntries;
//   final int aiQueries;

//   Usage({
//     required this.chatMessages,
//     required this.imageEntries,
//     required this.voiceEntries,
//     required this.aiQueries,
//   });

//   factory Usage.zero() => Usage(
//         chatMessages: 0,
//         imageEntries: 0,
//         voiceEntries: 0,
//         aiQueries: 0,
//       );
// }



import 'dart:typed_data';
import 'package:chatapp/tax_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class GeminiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _apiKey;

  GeminiService() {
    _loadEnv();
  }

  Future<void> _loadEnv() async {
    await dotenv.load(fileName: ".env");
    _apiKey = dotenv.env['GEMINI_API_KEY'];
  }

  Future<PlanLimits> getPlanLimits() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final plan = userDoc['subscription_plan'] ?? 'Free';

    switch (plan) {
      case 'Pro':
        return PlanLimits(
          chatMessages: 250,
          imageEntries: 50,
          voiceEntries: 50,
          aiQueries: 30,
        );
      case 'Power User':
        return PlanLimits(
          chatMessages: 1000,
          imageEntries: 200,
          voiceEntries: 200,
          aiQueries: 75,
        );
      default: // Free
        return PlanLimits(
          chatMessages: 60,
          imageEntries: 10,
          voiceEntries: 10,
          aiQueries: 10,
        );
    }
  }

  Future<Usage> getCurrentUsage() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final doc = await _firestore.collection('usage').doc(user.uid).get();
    if (doc.exists) {
      return Usage(
        chatMessages: doc['chatMessages'] ?? 0,
        imageEntries: doc['imageEntries'] ?? 0,
        voiceEntries: doc['voiceEntries'] ?? 0,
        aiQueries: doc['aiQueries'] ?? 0,
      );
    }
    return Usage.zero();
  }

  Future<void> incrementUsage(String type) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final usageRef = _firestore.collection('usage').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(usageRef);

      if (!doc.exists ||
          (doc['resetDate'] as Timestamp).toDate().isBefore(monthStart)) {
        transaction.set(usageRef, {
          'chatMessages': 0,
          'imageEntries': 0,
          'voiceEntries': 0,
          'aiQueries': 0,
          'resetDate': Timestamp.fromDate(monthStart),
        });
      }

      transaction.update(usageRef, {
        type: FieldValue.increment(1),
      });
    });
  }

  Future<String?> getTextResponse(String input) async {
    if (_apiKey == null) return 'API key not configured';

    final usage = await getCurrentUsage();
    final limits = await getPlanLimits();

    if (usage.chatMessages >= limits.chatMessages) {
      return 'Monthly chat message limit reached. Upgrade your plan.';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 500,
          temperature: 0.7,
        ),
      );

      final response = await model.generateContent([
        Content.text("You're a helpful financial assistant. $input"),
      ]);

      await incrementUsage('chatMessages');
      return response.text?.trim();
    } catch (e) {
      return "Connection issue. Please check your internet.";
    }
  }

  Future<String?> processImage(Uint8List imageBytes) async {
    if (_apiKey == null) return 'API key not configured';

    final usage = await getCurrentUsage();
    final limits = await getPlanLimits();

    if (usage.imageEntries >= limits.imageEntries) {
      return 'Image entry limit reached. Upgrade your plan.';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 500,
          temperature: 0.7,
        ),
      );

      final prompt = '''
      Analyze this receipt/image and extract financial details. Return ONLY a JSON object with these keys:
      - "amount" (number): The total amount
      - "date" (string): Transaction date in YYYY-MM-DD format
      - "category" (string): Financial category
      - "description" (string): Brief description
      - "type" (string): "expense" or "earning"
      
      Example expense:
      {
        "amount": 15.99,
        "date": "2023-11-15",
        "category": "Food",
        "description": "Coffee shop purchase",
        "type": "expense"
      }
      
      Example earning:
      {
        "amount": 5000.00,
        "date": "2023-11-20",
        "category": "Freelance",
        "description": "Web development project",
        "type": "earning"
      }
      ''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      await incrementUsage('imageEntries');
      return response.text?.trim();
    } catch (e) {
      return "Image processing failed: ${e.toString()}";
    }
  }

  // Enhanced tax optimization advice with actual user data
  Future<String> getTaxOptimizationAdvice(BangladeshTaxProfile profile) async {
    final usage = await getCurrentUsage();
    final limits = await getPlanLimits();
    
    if (usage.aiQueries >= limits.aiQueries) {
      return 'Monthly AI analysis limit reached. Upgrade your plan.';
    }

    final user = _auth.currentUser;
    if (user == null) return 'User not authenticated. Please sign in.';

    try {
      // Get user's actual financial data
      final userFinancialData = await _getUserFinancialData(user.uid);
      
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 2000,
          temperature: 0.3,
        ),
      );

      final prompt = '''
      As a tax consultant specializing in Bangladesh tax law, analyze this comprehensive profile:
      
      TAX PROFILE:
      ${profile.toJson()}
      
      ACTUAL FINANCIAL DATA:
      ${userFinancialData['summary']}
      
      SPENDING PATTERNS:
      ${userFinancialData['expenseBreakdown']}
      
      INCOME PATTERNS:
      ${userFinancialData['incomeBreakdown']}
      
      MONTHLY TRENDS:
      ${userFinancialData['monthlyTrends']}
      
      Based on this real financial data and Bangladesh tax regulations for ${profile.assessmentYear}, provide:
      
      1. **PERSONALIZED TAX OPTIMIZATION STRATEGIES:**
         - Specific investment recommendations under Section 44 based on current income
         - Deduction opportunities aligned with spending patterns
         - Tax bracket optimization strategies for this income level
         
      2. **INVESTMENT RECOMMENDATIONS:**
         - Recommended allocation to tax-saving instruments
         - Specific amounts for DPS, life insurance, provident fund
         - Real estate investment advice based on income capacity
         
      3. **EXPENSE-BASED TAX PLANNING:**
         - Medical expense deductions based on health spending
         - Education deductions based on education expenses
         - Professional development deductions
         
      4. **COMPLIANCE & PLANNING:**
         - Return filing requirements and deadlines
         - Advance tax payment recommendations
         - Documentation requirements
         
      5. **PROJECTED TAX SAVINGS:**
         - Current estimated tax liability
         - Potential savings with optimization
         - Monthly saving targets to achieve tax efficiency
         
      6. **RISK WARNINGS:**
         - Areas of potential non-compliance
         - Common audit triggers to avoid
         - Record-keeping recommendations
      
      Format response with clear sections, specific BDT amounts, and actionable steps.
      Use the actual spending and income data to make realistic recommendations.
      ''';
      
      final response = await model.generateContent([Content.text(prompt)]);
      await incrementUsage('aiQueries');
      return response.text?.trim() ?? 'No tax advice generated.';
    } catch (e) {
      return "Tax advice generation failed: ${e.toString()}";
    }
  }

  // Enhanced smart recommendations generator
  Future<List<SmartRecommendation>> generateSmartRecommendations() async {
    final usage = await getCurrentUsage();
    final limits = await getPlanLimits();

    if (usage.aiQueries >= limits.aiQueries) {
      return [SmartRecommendation(
        message: 'Monthly AI analysis limit reached. Upgrade your plan for personalized recommendations.',
        type: RecommendationType.upgrade,
        priority: RecommendationPriority.high,
        actionable: false,
      )];
    }

    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Get comprehensive user data
      final userFinancialData = await _getUserFinancialData(user.uid);
      final taxProfile = await _getUserTaxProfile(user.uid);
      
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 1500,
          temperature: 0.4,
        ),
      );

      final prompt = '''
      As a financial advisor, analyze this user's complete financial profile and generate 5-8 specific, actionable recommendations:

      FINANCIAL SUMMARY:
      ${userFinancialData['summary']}
      
      SPENDING ANALYSIS:
      ${userFinancialData['expenseBreakdown']}
      
      INCOME ANALYSIS:
      ${userFinancialData['incomeBreakdown']}
      
      SPENDING TRENDS:
      ${userFinancialData['monthlyTrends']}
      
      TAX PROFILE:
      ${taxProfile != null ? 'Available - ${taxProfile['annualIncome']} BDT annual income' : 'Not set up'}
      
      BEHAVIORAL PATTERNS:
      ${userFinancialData['behaviorPatterns']}

      Generate recommendations in this EXACT JSON format:
      [
        {
          "message": "Specific actionable advice with numbers",
          "type": "savings|budget|tax|investment|emergency|debt",
          "priority": "high|medium|low",
          "expectedImpact": "Monthly/yearly impact in BDT",
          "actionSteps": ["Step 1", "Step 2", "Step 3"],
          "timeframe": "immediate|1month|3months|6months",
          "category": "expense category affected or general"
        }
      ]

      Focus on:
      1. Specific spending reduction opportunities with exact amounts
      2. Savings rate optimization based on current income
      3. Tax efficiency improvements
      4. Emergency fund planning
      5. Investment opportunities suitable for Bangladesh
      6. Debt optimization if applicable
      7. Budget reallocation suggestions
      8. Long-term financial planning

      Make recommendations data-driven and include specific BDT amounts where possible.
      ''';
      
      final response = await model.generateContent([Content.text(prompt)]);
      await incrementUsage('aiQueries');
      
      if (response.text != null) {
        return _parseRecommendationsFromAI(response.text!);
      }
      
      return _getFallbackRecommendations(userFinancialData);
    } catch (e) {
      print("Smart recommendations generation failed: $e");
      final userFinancialData = await _getUserFinancialData(user.uid);
      return _getFallbackRecommendations(userFinancialData);
    }
  }

  // Enhanced financial report with actual user data
  Future<String> generateFinancialReport() async {
    final usage = await getCurrentUsage();
    final limits = await getPlanLimits();

    if (usage.aiQueries >= limits.aiQueries) {
      return 'Monthly AI analysis limit reached. Upgrade your plan.';
    }

    final user = _auth.currentUser;
    if (user == null) return 'User not authenticated. Please sign in.';

    try {
      // Get comprehensive financial data
      final userFinancialData = await _getUserFinancialData(user.uid);
      final taxProfile = await _getUserTaxProfile(user.uid);
      
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 2500,
          temperature: 0.3,
        ),
      );

      final prompt = '''
      Generate a comprehensive financial health report for this Bangladesh-based user:

      FINANCIAL DATA:
      ${userFinancialData['summary']}
      
      EXPENSE BREAKDOWN:
      ${userFinancialData['expenseBreakdown']}
      
      INCOME ANALYSIS:
      ${userFinancialData['incomeBreakdown']}
      
      MONTHLY TRENDS (Last 12 months):
      ${userFinancialData['monthlyTrends']}
      
      TAX PROFILE:
      ${taxProfile != null ? taxProfile.toString() : 'Not configured'}
      
      BEHAVIORAL INSIGHTS:
      ${userFinancialData['behaviorPatterns']}

      Create a detailed report covering:

      ## 📊 Executive Summary
      - Overall financial health score (1-100)
      - Key strengths and areas for improvement
      - Net worth trajectory

      ## 💰 Income & Expense Analysis
      - Income stability and growth trends
      - Expense categorization and efficiency
      - Savings rate analysis
      - Spending habit insights

      ## 📈 Financial Performance Metrics
      - Monthly burn rate and runway
      - Expense-to-income ratios by category
      - Seasonal spending patterns
      - Year-over-year comparisons

      ## 🎯 Goal Achievement Assessment
      - Emergency fund status
      - Savings targets vs actual
      - Investment allocation effectiveness

      ## 🏦 Bangladesh Tax Optimization
      - Current tax liability estimation
      - Tax-saving opportunities under Bangladesh law
      - Section 44 investment recommendations
      - Compliance status and requirements

      ## ⚠️ Risk Assessment
      - Financial vulnerabilities
      - Over-spending categories
      - Income concentration risks
      - Emergency preparedness

      ## 🚀 Strategic Recommendations
      - Short-term action items (next 30 days)
      - Medium-term goals (3-6 months)
      - Long-term wealth building strategy
      - Specific BDT amounts for each recommendation

      ## 📋 Action Plan
      - Prioritized action items with timelines
      - Budget adjustments needed
      - Investment reallocation suggestions
      - Monitoring metrics to track progress

      Use actual data and provide specific, actionable insights with real numbers in BDT.
      Format as markdown with clear headings and bullet points for easy reading.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      await incrementUsage('aiQueries');
      return response.text?.trim() ?? 'No response generated.';
    } catch (e) {
      return "Report generation failed: ${e.toString()}";
    }
  }

  // Helper method to get comprehensive user financial data
  Future<Map<String, dynamic>> _getUserFinancialData(String userId) async {
    try {
      final now = DateTime.now();
      final last12Months = now.subtract(const Duration(days: 365));
      final last30Days = now.subtract(const Duration(days: 30));

      // Get transactions for analysis
      final allTransactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: last12Months)
          .orderBy('date', descending: true)
          .get();

      final recentTransactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: last30Days)
          .orderBy('date', descending: true)
          .get();

      // Calculate financial metrics
      double totalIncome = 0;
      double totalExpenses = 0;
      double recentIncome = 0;
      double recentExpenses = 0;
      Map<String, double> expenseByCategory = {};
      Map<String, double> incomeByCategory = {};
      Map<String, double> monthlyExpenses = {};
      Map<String, double> monthlyIncome = {};
      Map<String, int> transactionFrequency = {};

      // Process all transactions
      for (var doc in allTransactions.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final category = data['category'] as String? ?? 'Uncategorized';
        final date = (data['date'] as Timestamp).toDate();
        final monthKey = DateFormat('yyyy-MM').format(date);

        if (amount < 0) {
          // Expense
          final absAmount = amount.abs();
          totalExpenses += absAmount;
          expenseByCategory[category] = (expenseByCategory[category] ?? 0) + absAmount;
          monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + absAmount;
        } else {
          // Income
          totalIncome += amount;
          incomeByCategory[category] = (incomeByCategory[category] ?? 0) + amount;
          monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + amount;
        }

        transactionFrequency[category] = (transactionFrequency[category] ?? 0) + 1;
      }

      // Process recent transactions
      for (var doc in recentTransactions.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();

        if (amount < 0) {
          recentExpenses += amount.abs();
        } else {
          recentIncome += amount;
        }
      }

      // Calculate insights
      final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;
      final avgMonthlyExpenses = monthlyExpenses.values.isNotEmpty 
          ? monthlyExpenses.values.reduce((a, b) => a + b) / monthlyExpenses.length 
          : 0;
      final avgMonthlyIncome = monthlyIncome.values.isNotEmpty 
          ? monthlyIncome.values.reduce((a, b) => a + b) / monthlyIncome.length 
          : 0;

      // Behavioral patterns
      final topExpenseCategory = expenseByCategory.entries.isNotEmpty
          ? expenseByCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'None';
      
      final expenseConcentration = expenseByCategory.isNotEmpty && totalExpenses > 0
          ? (expenseByCategory.values.reduce((a, b) => a > b ? a : b) / totalExpenses) * 100
          : 0;

      return {
        'summary': '''
Total Income (12 months): ৳${totalIncome.toStringAsFixed(2)}
Total Expenses (12 months): ৳${totalExpenses.toStringAsFixed(2)}
Net Savings: ৳${(totalIncome - totalExpenses).toStringAsFixed(2)}
Savings Rate: ${savingsRate.toStringAsFixed(1)}%
Recent Income (30 days): ৳${recentIncome.toStringAsFixed(2)}
Recent Expenses (30 days): ৳${recentExpenses.toStringAsFixed(2)}
Average Monthly Income: ৳${avgMonthlyIncome.toStringAsFixed(2)}
Average Monthly Expenses: ৳${avgMonthlyExpenses.toStringAsFixed(2)}
Transaction Count: ${allTransactions.docs.length}
        ''',
        'expenseBreakdown': expenseByCategory.entries.map((e) => 
          '${e.key}: ৳${e.value.toStringAsFixed(2)} (${((e.value / totalExpenses) * 100).toStringAsFixed(1)}%)'
        ).join('\n'),
        'incomeBreakdown': incomeByCategory.entries.map((e) => 
          '${e.key}: ৳${e.value.toStringAsFixed(2)} (${((e.value / totalIncome) * 100).toStringAsFixed(1)}%)'
        ).join('\n'),
        'monthlyTrends': monthlyExpenses.entries.map((e) => 
          '${e.key}: Expenses ৳${e.value.toStringAsFixed(2)}, Income ৳${(monthlyIncome[e.key] ?? 0).toStringAsFixed(2)}'
        ).join('\n'),
        'behaviorPatterns': '''
Top Expense Category: $topExpenseCategory (${expenseConcentration.toStringAsFixed(1)}% concentration)
Transaction Frequency: ${(allTransactions.docs.length / 12).toStringAsFixed(1)} per month
Income Stability: ${incomeByCategory.length} income sources
Expense Diversification: ${expenseByCategory.length} categories
        ''',
        'rawData': {
          'totalIncome': totalIncome,
          'totalExpenses': totalExpenses,
          'savingsRate': savingsRate,
          'expenseByCategory': expenseByCategory,
          'incomeByCategory': incomeByCategory,
          'avgMonthlyExpenses': avgMonthlyExpenses,
          'avgMonthlyIncome': avgMonthlyIncome,
        }
      };
    } catch (e) {
      print("Error getting user financial data: $e");
      return {
        'summary': 'No financial data available',
        'expenseBreakdown': 'No expense data',
        'incomeBreakdown': 'No income data',
        'monthlyTrends': 'No trend data',
        'behaviorPatterns': 'No behavioral data available',
        'rawData': {},
      };
    }
  }

  // Helper method to get user tax profile
  Future<Map<String, dynamic>?> _getUserTaxProfile(String userId) async {
    try {
      final doc = await _firestore.collection('taxProfiles').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error getting tax profile: $e");
      return null;
    }
  }

  // Helper method to parse AI recommendations
  List<SmartRecommendation> _parseRecommendationsFromAI(String aiResponse) {
    try {
      // Try to extract JSON from AI response
      final jsonStart = aiResponse.indexOf('[');
      final jsonEnd = aiResponse.lastIndexOf(']') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = aiResponse.substring(jsonStart, jsonEnd);
        final List<dynamic> recommendationsJson = List<dynamic>.from(
          jsonString.split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => line.trim())
              .toList()
        );
        
        // For now, return fallback recommendations
        // In a real implementation, you'd parse the JSON properly
        return _getFallbackRecommendations({});
      }
    } catch (e) {
      print("Error parsing AI recommendations: $e");
    }
    
    return _getFallbackRecommendations({});
  }

  // Fallback recommendations based on user data
  List<SmartRecommendation> _getFallbackRecommendations(Map<String, dynamic> userData) {
    List<SmartRecommendation> recommendations = [];
    
    final rawData = userData['rawData'] as Map<String, dynamic>? ?? {};
    final totalIncome = rawData['totalIncome'] as double? ?? 0;
    final totalExpenses = rawData['totalExpenses'] as double? ?? 0;
    final savingsRate = rawData['savingsRate'] as double? ?? 0;
    final expenseByCategory = rawData['expenseByCategory'] as Map<String, double>? ?? {};

    // Savings rate recommendation
    if (savingsRate < 10) {
      recommendations.add(SmartRecommendation(
        message: 'Your savings rate is ${savingsRate.toStringAsFixed(1)}%. Try to save at least 10% by reducing non-essential expenses.',
        type: RecommendationType.savings,
        priority: RecommendationPriority.high,
        actionable: true,
      ));
    }

    // Top expense category
    if (expenseByCategory.isNotEmpty && totalExpenses > 0) {
      final topExpense = expenseByCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
      final percentage = (topExpense.value / totalExpenses) * 100;
      
      if (percentage > 40) {
        recommendations.add(SmartRecommendation(
          message: '${topExpense.key} accounts for ${percentage.toStringAsFixed(1)}% of expenses. Consider reducing this category by ৳${(topExpense.value * 0.1).toStringAsFixed(2)}/month.',
          type: RecommendationType.budget,
          priority: RecommendationPriority.medium,
          actionable: true,
        ));
      }
    }

    // Emergency fund
    final monthlyExpenses = rawData['avgMonthlyExpenses'] as double? ?? 0;
    if (monthlyExpenses > 0 && (totalIncome - totalExpenses) < (monthlyExpenses * 3)) {
      recommendations.add(SmartRecommendation(
        message: 'Build an emergency fund of ৳${(monthlyExpenses * 6).toStringAsFixed(2)} (6 months of expenses) for financial security.',
        type: RecommendationType.emergency,
        priority: RecommendationPriority.high,
        actionable: true,
      ));
    }

    // Investment opportunity
    if (savingsRate > 15) {
      recommendations.add(SmartRecommendation(
        message: 'Great savings rate! Consider investing ৳${((totalIncome - totalExpenses) * 0.3).toStringAsFixed(2)} in tax-saving instruments for better returns.',
        type: RecommendationType.investment,
        priority: RecommendationPriority.medium,
        actionable: true,
      ));
    }

    return recommendations;
  }
}

// Enhanced recommendation classes
class SmartRecommendation {
  final String message;
  final RecommendationType type;
  final RecommendationPriority priority;
  final bool actionable;
  final String? expectedImpact;
  final List<String>? actionSteps;
  final String? timeframe;
  final String? category;

  SmartRecommendation({
    required this.message,
    required this.type,
    required this.priority,
    required this.actionable,
    this.expectedImpact,
    this.actionSteps,
    this.timeframe,
    this.category,
  });
}

enum RecommendationType {
  savings,
  budget,
  tax,
  investment,
  emergency,
  debt,
  upgrade,
  general
}

enum RecommendationPriority {
  high,
  medium,
  low
}

// Existing classes remain the same
class PlanLimits {
  final int chatMessages;
  final int imageEntries;
  final int voiceEntries;
  final int aiQueries;

  PlanLimits({
    required this.chatMessages,
    required this.imageEntries,
    required this.voiceEntries,
    required this.aiQueries,
  });
}

class Usage {
  final int chatMessages;
  final int imageEntries;
  final int voiceEntries;
  final int aiQueries;

  Usage({
    required this.chatMessages,
    required this.imageEntries,
    required this.voiceEntries,
    required this.aiQueries,
  });

  factory Usage.zero() => Usage(
        chatMessages: 0,
        imageEntries: 0,
        voiceEntries: 0,
        aiQueries: 0,
      );
}




