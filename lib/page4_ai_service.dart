import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:chatapp/page1_models.dart';
import 'package:chatapp/page2_usage_service.dart';
import 'package:chatapp/page3_financial_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:chatapp/tax_profile_model.dart';


class GeminiAIService {
  String? _apiKey;
  final UsageService _usageService = UsageService();
  final FinancialDataService _financialDataService = FinancialDataService();

  // Cache for models to avoid recreation
  GenerativeModel? _chatModel;
  GenerativeModel? _imageModel;
  GenerativeModel? _analysisModel;

  GeminiAIService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await dotenv.load(fileName: ".env");
      _apiKey = dotenv.env['GEMINI_API_KEY'];
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        print("Warning: GEMINI_API_KEY not found in .env file");
      }
    } catch (e) {
      print("Error loading environment variables: $e");
    }
  }

  GenerativeModel _getChatModel() {
    if (_chatModel == null && _apiKey != null) {
      _chatModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 500,
          temperature: 0.7,
          topP: 0.8,
          topK: 40,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );
    }
    return _chatModel!;
  }

  GenerativeModel _getImageModel() {
    if (_imageModel == null && _apiKey != null) {
      _imageModel = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 1000,
          temperature: 0.3,
          topP: 0.9,
        ),
      );
    }
    return _imageModel!;
  }

  GenerativeModel _getAnalysisModel() {
    if (_analysisModel == null && _apiKey != null) {
      _analysisModel = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 2500,
          temperature: 0.3,
          topP: 0.9,
          topK: 20,
        ),
      );
    }
    return _analysisModel!;
  }

  Future<AIResponse> getTextResponse(String input) async {
    if (_apiKey == null) {
      return AIResponse.error('API key not configured. Please check your environment setup.');
    }

    // Check usage limits
    if (!await _usageService.canUseFeature('chatMessages')) {
      return AIResponse.error('Monthly chat message limit reached. Upgrade your plan for more messages.');
    }

    try {
      final model = _getChatModel();
      
      final enhancedPrompt = '''
You are a knowledgeable financial assistant specializing in personal finance for Bangladesh. 
Provide helpful, accurate, and practical advice. Keep responses concise but informative.
Focus on actionable insights and consider local financial practices and regulations.

User Query: $input
''';

      final response = await model.generateContent([
        Content.text(enhancedPrompt),
      ]);

      if (response.text?.isNotEmpty == true) {
        await _usageService.incrementUsage('chatMessages');
        return AIResponse.success(response.text!.trim());
      } else {
        return AIResponse.error('No response generated. Please try rephrasing your question.');
      }
    } catch (e) {
      print("Error in getTextResponse: $e");
      if (e.toString().contains('quota') || e.toString().contains('limit')) {
        return AIResponse.error('API quota exceeded. Please try again later.');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        return AIResponse.error('Network error. Please check your internet connection.');
      } else {
        return AIResponse.error('Service temporarily unavailable. Please try again.');
      }
    }
  }

  Future<AIResponse> processReceiptImage(Uint8List imageBytes) async {
    if (_apiKey == null) {
      return AIResponse.error('API key not configured');
    }

    if (!await _usageService.canUseFeature('imageEntries')) {
      return AIResponse.error('Monthly image processing limit reached. Upgrade your plan.');
    }

    try {
      final model = _getImageModel();

      final prompt = '''
Analyze this receipt/financial document and extract transaction details. 

CRITICAL: Return ONLY a valid JSON object with these exact keys:
{
  "amount": number (always positive, total amount),
  "date": "YYYY-MM-DD" (transaction date, use today if unclear),
  "category": "string" (one of: Food, Transport, Shopping, Bills, Entertainment, Health, Education, Others),
  "description": "string" (brief 2-4 word description),
  "type": "expense" or "earning"
}

Guidelines:
- For receipts/bills: type = "expense"
- For salary slips/income: type = "earning" 
- Amount should be the total/final amount only
- Use standard categories that match the app
- Keep description brief and clear
- If date is unclear, use today's date
- If it's not a financial document, return {"error": "Not a financial document"}

Examples:
Receipt: {"amount": 250.50, "date": "2024-01-15", "category": "Food", "description": "Restaurant meal", "type": "expense"}
Salary: {"amount": 45000, "date": "2024-01-01", "category": "Salary", "description": "Monthly salary", "type": "earning"}
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      if (response.text?.isNotEmpty == true) {
        await _usageService.incrementUsage('imageEntries');
        
        // Try to clean and validate the JSON response
        final cleanedResponse = _cleanJsonResponse(response.text!);
        return AIResponse.success(cleanedResponse);
      } else {
        return AIResponse.error('Could not process the image. Please try a clearer photo.');
      }
    } catch (e) {
      print("Error in processReceiptImage: $e");
      return AIResponse.error('Image processing failed. Please try again with a clearer image.');
    }
  }

  String _cleanJsonResponse(String rawResponse) {
    // Remove markdown formatting and extra text
    String cleaned = rawResponse.trim();
    
    // Find JSON object bounds
    int start = cleaned.indexOf('{');
    int end = cleaned.lastIndexOf('}');
    
    if (start != -1 && end != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }
    
    // Validate JSON
    try {
      final decoded = jsonDecode(cleaned);
      // Re-encode to ensure proper formatting
      return jsonEncode(decoded);
    } catch (e) {
      print("JSON validation failed: $e");
      // Return a fallback response
      return jsonEncode({
        'error': 'Could not extract transaction data. Please try manual entry.'
      });
    }
  }

  Future<AIResponse> getTaxOptimizationAdvice(BangladeshTaxProfile profile, String userId) async {
    if (!await _usageService.canUseFeature('aiQueries')) {
      return AIResponse.error('Monthly AI analysis limit reached. Upgrade your plan for personalized tax advice.');
    }

    try {
      final financialSummary = await _financialDataService.getFinancialSummary(userId);
      
      // Fix: Better null checking and type safety
      if (financialSummary['financialData'] == null) {
        return AIResponse.error('No financial data available. Please add some transactions first.');
      }
      
      final financialData = financialSummary['financialData'] as FinancialData;
      
      // Fix: Check if user has sufficient financial data
      if (financialData.transactionCount < 5) {
        return AIResponse.error('Please add more transactions (at least 5) for meaningful tax advice.');
      }
      
      final model = _getAnalysisModel();

      final prompt = '''
As a tax consultant specializing in Bangladesh tax law, provide comprehensive tax optimization advice based on this user's profile and actual financial data:

TAX PROFILE:
- Assessment Year: ${profile.assessmentYear}
- Annual Income: ৳${profile.annualIncome.toStringAsFixed(2)}
- Tax Zone: ${profile.taxZone}
- Age: ${profile.age}
- Gender: ${profile.gender}

ACTUAL FINANCIAL PERFORMANCE:
${financialData.summaryText}

SPENDING PATTERNS:
${financialData.expenseBreakdownText.isNotEmpty ? financialData.expenseBreakdownText : 'No expense data available'}

INCOME ANALYSIS:
${financialData.incomeBreakdownText.isNotEmpty ? financialData.incomeBreakdownText : 'No income data available'}

BEHAVIORAL PATTERNS:
${financialSummary['behaviorPatterns'] ?? 'No behavioral patterns identified'}

Based on Bangladesh tax regulations and this user's real financial data, provide specific advice on:

## 1. TAX-SAVING INVESTMENT OPPORTUNITIES
- Recommend specific amounts for Section 44 investments based on current income
- DPS, life insurance, and provident fund allocations suitable for this income level
- Real estate investment potential considering current savings capacity

## 2. DEDUCTION OPTIMIZATION
- Medical expense deductions based on health spending patterns
- Education expense benefits available
- Professional development and training deductions

## 3. FINANCIAL RESTRUCTURING
- Income timing strategies for tax efficiency
- Expense categorization for maximum tax benefits
- Investment reallocation recommendations

## 4. COMPLIANCE & FILING
- Required documentation checklist for this income bracket
- Filing deadlines and advance tax payment schedule
- Common audit triggers to avoid

## 5. PROJECTED SAVINGS & ACTION PLAN
- Current estimated tax liability: Calculate based on ${profile.annualIncome.toStringAsFixed(2)} BDT income
- Potential tax savings with recommended strategies
- Monthly savings targets: Suggest realistic amounts based on current expense patterns
- Specific action items with deadlines

IMPORTANT: Provide all monetary recommendations in BDT with realistic amounts based on the user's actual financial capacity shown in the data above.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text?.isNotEmpty == true) {
        await _usageService.incrementUsage('aiQueries');
        return AIResponse.success(response.text!.trim());
      } else {
        return AIResponse.error('Unable to generate tax advice. Please try again.');
      }
    } catch (e) {
      print("Error in getTaxOptimizationAdvice: $e");
      return AIResponse.error('Tax advice generation failed: ${e.toString()}');
    }
  }

  Future<List<SmartRecommendation>> generateSmartRecommendations(String userId) async {
    if (!await _usageService.canUseFeature('aiQueries')) {
      return [SmartRecommendation(
        message: 'Monthly AI analysis limit reached. Upgrade your plan for personalized recommendations.',
        type: RecommendationType.upgrade,
        priority: RecommendationPriority.high,
        actionable: false,
      )];
    }

    try {
      final financialSummary = await _financialDataService.getFinancialSummary(userId);
      
      // Fix: Better null checking and validation
      if (financialSummary['financialData'] == null) {
        return [SmartRecommendation(
          message: 'Add some transactions first to get personalized recommendations.',
          type: RecommendationType.general,
          priority: RecommendationPriority.medium,
          actionable: true,
        )];
      }
      
      final financialData = financialSummary['financialData'] as FinancialData;
      final taxProfile = financialSummary['taxProfile'];
      
      // Fix: Return basic recommendations if insufficient data
      if (financialData.transactionCount < 3) {
        return _getFallbackRecommendations(financialData);
      }
      
      final model = _getAnalysisModel();

      final prompt = '''
As an AI financial advisor, analyze this user's financial profile and generate 5-7 specific, actionable recommendations:

FINANCIAL SUMMARY:
${financialData.summaryText}

SPENDING BREAKDOWN:
${financialData.expenseByCategory.isNotEmpty ? financialData.expenseBreakdownText : 'Limited expense data - encourage more transaction recording'}

INCOME ANALYSIS:
${financialData.incomeByCategory.isNotEmpty ? financialData.incomeBreakdownText : 'Limited income data - encourage salary/income recording'}

BEHAVIORAL PATTERNS:
${financialSummary['behaviorPatterns'] ?? 'Insufficient data for behavioral analysis'}

RISK ASSESSMENT:
${financialSummary['riskAssessment'] != null ? financialSummary['riskAssessment'].toString() : 'Risk assessment pending more data'}

TAX PROFILE STATUS:
${taxProfile != null ? 'Tax profile configured' : 'Tax profile not set up - recommend tax planning setup'}

DATA QUALITY:
- Transaction Count: ${financialData.transactionCount}
- Data Period: Last 12 months
- Income Sources: ${financialData.incomeSourceCount}
- Expense Categories: ${financialData.expenseCategoryCount}

Generate recommendations in this EXACT JSON array format (ensure valid JSON):
[
  {
    "message": "Specific actionable advice with exact BDT amounts where applicable",
    "type": "savings|budget|tax|investment|emergency|debt|general",
    "priority": "high|medium|low",
    "expectedImpact": "Estimated monthly/yearly financial impact in BDT",
    "actionSteps": ["Specific step 1", "Specific step 2", "Specific step 3"],
    "timeframe": "immediate|1month|3months|6months",
    "category": "affected expense category or general",
    "potentialSavings": ${financialData.avgMonthlyIncome > 0 ? (financialData.avgMonthlyIncome * 0.05).toStringAsFixed(0) : 1000}
  }
]

Focus on these areas based on available data:
1. ${financialData.savingsRate < 10 ? 'URGENT: Improve savings rate (currently ${financialData.savingsRate.toStringAsFixed(1)}%)' : 'Optimize existing good savings habits'}
2. ${financialData.expenseConcentration > 50 ? 'Reduce expense concentration in ${financialData.topExpenseCategory}' : 'Diversify spending further'}
3. ${financialData.incomeSourceCount <= 1 ? 'Develop additional income sources' : 'Optimize existing income streams'}
4. ${taxProfile == null ? 'Set up tax planning profile' : 'Optimize tax efficiency'}
5. Emergency fund planning (target: ${(financialData.avgMonthlyExpenses * 6).toStringAsFixed(0)} BDT)
6. Investment opportunities suitable for Bangladesh market
7. Monthly budget optimization

CRITICAL: Return ONLY the JSON array. No extra text before or after. Each recommendation must include realistic BDT amounts based on the user's actual financial capacity.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text?.isNotEmpty == true) {
        await _usageService.incrementUsage('aiQueries');
        return _parseRecommendationsFromAI(response.text!, financialData);
      } else {
        return _getFallbackRecommendations(financialData);
      }
    } catch (e) {
      print("Error in generateSmartRecommendations: $e");
      // Fix: Always return fallback recommendations instead of crashing
      try {
        final financialData = await _financialDataService.getUserFinancialData(userId);
        return _getFallbackRecommendations(financialData);
      } catch (fallbackError) {
        print("Error getting fallback data: $fallbackError");
        return [SmartRecommendation(
          message: 'Unable to generate recommendations at this time. Please try again later.',
          type: RecommendationType.general,
          priority: RecommendationPriority.low,
          actionable: false,
        )];
      }
    }
  }

  // Fix: Enhanced recommendation parsing with better error handling
  List<SmartRecommendation> _parseRecommendationsFromAI(String aiResponse, FinancialData financialData) {
    try {
      // Clean the response more thoroughly
      String cleaned = aiResponse.trim();
      
      // Remove common AI response artifacts
      cleaned = cleaned.replaceAll(RegExp(r'^```json\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\s*```$'), '');
      cleaned = cleaned.replaceAll(RegExp(r'^```\s*'), '');
      
      // Find JSON array more robustly
      final jsonStart = cleaned.indexOf('[');
      final jsonEnd = cleaned.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        print("No valid JSON array found in AI response");
        return _getFallbackRecommendations(financialData);
      }
      
      final jsonString = cleaned.substring(jsonStart, jsonEnd);
      print("Attempting to parse JSON: ${jsonString.substring(0, math.min(200, jsonString.length))}...");
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      final recommendations = <SmartRecommendation>[];
      
      for (int i = 0; i < jsonList.length; i++) {
        try {
          final json = jsonList[i] as Map<String, dynamic>;
          
          // Validate required fields
          if (json['message'] == null || json['type'] == null || json['priority'] == null) {
            print("Skipping invalid recommendation at index $i: missing required fields");
            continue;
          }
          
          final recommendation = SmartRecommendation.fromJson(json);
          recommendations.add(recommendation);
        } catch (e) {
          print("Error parsing recommendation at index $i: $e");
          continue; // Skip this recommendation but continue with others
        }
      }
      
      // If we got some valid recommendations, return them
      if (recommendations.isNotEmpty) {
        return recommendations;
      }
      
      print("No valid recommendations parsed, returning fallback");
      return _getFallbackRecommendations(financialData);
      
    } catch (e) {
      print("JSON parsing error: $e");
      print("AI Response preview: ${aiResponse.substring(0, math.min(500, aiResponse.length))}");
      return _getFallbackRecommendations(financialData);
    }
  }

 // Fix: Enhanced fallback recommendations with better data handling
List<SmartRecommendation> _getFallbackRecommendations(FinancialData data) {
  List<SmartRecommendation> recommendations = [];

  try {
    // Savings rate recommendation with null safety
    if (data.savingsRate < 10) {
      final targetSavings = math.max(data.avgMonthlyIncome * 0.1, 5000).toDouble();
      final currentShortfall = (targetSavings - (data.avgMonthlyIncome - data.avgMonthlyExpenses)).toDouble();
      
      recommendations.add(SmartRecommendation(
        message: 'Your savings rate is ${data.savingsRate.toStringAsFixed(1)}%. Aim for 10% by saving an additional ৳${currentShortfall.toStringAsFixed(0)}/month.',
        type: RecommendationType.savings,
        priority: RecommendationPriority.high,
        actionable: true,
        expectedImpact: '৳${targetSavings.toStringAsFixed(0)}/month savings',
        potentialSavings: targetSavings, // Now this is double
        timeframe: '1month',
        category: 'general',
        actionSteps: [
          'Review monthly expenses for reduction opportunities',
          'Set up automatic savings transfer',
          'Track daily expenses to identify wasteful spending'
        ],
      ));
    }

    // Emergency fund recommendation with better calculations
    final emergencyFundMonths = data.avgMonthlyExpenses > 0 
        ? data.netSavings / data.avgMonthlyExpenses 
        : 0;
    
    if (emergencyFundMonths < 6) {
      final targetAmount = math.max(data.avgMonthlyExpenses * 6, 50000).toDouble();
      final currentShortfall = math.max(targetAmount - data.netSavings, 0).toDouble();
      final monthlySavingNeeded = (currentShortfall / 12).toDouble();
      
      recommendations.add(SmartRecommendation(
        message: 'Build an emergency fund of ৳${targetAmount.toStringAsFixed(0)} (6 months expenses). Save ৳${monthlySavingNeeded.toStringAsFixed(0)}/month to reach this goal in 1 year.',
        type: RecommendationType.emergency,
        priority: RecommendationPriority.high,
        actionable: true,
        expectedImpact: 'Financial security for 6 months',
        potentialSavings: monthlySavingNeeded, // Added potentialSavings for consistency
        timeframe: '6months',
        category: 'general',
        actionSteps: [
          'Open a separate high-yield savings account',
          'Set up automatic monthly transfer',
          'Avoid using emergency fund for non-emergencies'
        ],
      ));
    }

    // Investment opportunity with realistic amounts
    if (data.savingsRate > 15 && data.netSavings > 100000) {
      final investmentAmount = math.min(data.netSavings * 0.3, data.avgMonthlyIncome * 3).toDouble();
      recommendations.add(SmartRecommendation(
        message: 'Excellent savings rate! Consider investing ৳${investmentAmount.toStringAsFixed(0)} in tax-saving instruments like DPS or mutual funds.',
        type: RecommendationType.investment,
        priority: RecommendationPriority.medium,
        actionable: true,
        expectedImpact: 'Potential 8-12% annual returns',
        potentialSavings: investmentAmount * 0.1, // Estimated 10% return
        timeframe: '1month',
        category: 'general',
        actionSteps: [
          'Research DPS options from banks',
          'Consider tax-saving mutual funds',
          'Consult with a financial advisor'
        ],
      ));
    }

    // Top expense optimization with safety checks
    if (data.expenseByCategory.isNotEmpty && data.totalExpenses > 0) {
      final topExpenseEntry = data.expenseByCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final topExpense = topExpenseEntry.value;
      final topCategory = topExpenseEntry.key;
      final percentage = (topExpense / data.totalExpenses) * 100;
      
      if (percentage > 30 && topExpense > 10000) {
        final reductionTarget = math.min(topExpense * 0.15, data.avgMonthlyIncome * 0.1).toDouble();
        recommendations.add(SmartRecommendation(
          message: '$topCategory accounts for ${percentage.toStringAsFixed(1)}% of expenses. Reduce by ৳${reductionTarget.toStringAsFixed(0)}/month for better balance.',
          type: RecommendationType.budget,
          priority: RecommendationPriority.medium,
          actionable: true,
          expectedImpact: '৳${reductionTarget.toStringAsFixed(0)}/month savings',
          potentialSavings: reductionTarget, // Now this is double
          timeframe: '1month',
          category: topCategory,
          actionSteps: [
            'Track $topCategory expenses daily',
            'Find cheaper alternatives',
            'Set monthly spending limit for $topCategory'
          ],
        ));
      }
    }

    // Income diversification recommendation
    if (data.incomeSourceCount <= 1 && data.avgMonthlyIncome > 20000) {
      recommendations.add(SmartRecommendation(
        message: 'Consider developing additional income sources to reduce financial risk and increase earning potential.',
        type: RecommendationType.general,
        priority: RecommendationPriority.medium,
        actionable: true,
        expectedImpact: 'Reduced financial risk and potential income increase',
        potentialSavings: data.avgMonthlyIncome * 0.2, // Potential 20% income increase
        timeframe: '3months',
        category: 'general',
        actionSteps: [
          'Explore freelancing opportunities in your field',
          'Consider part-time work or consulting',
          'Develop passive income streams'
        ],
      ));
    }

    // Data improvement recommendation if insufficient data
    if (data.transactionCount < 10) {
      recommendations.add(SmartRecommendation(
        message: 'Add more transactions (${10 - data.transactionCount} more needed) to get better personalized financial advice.',
        type: RecommendationType.general,
        priority: RecommendationPriority.low,
        actionable: true,
        expectedImpact: 'Better financial insights and recommendations',
        potentialSavings: 0.0, // No direct savings, but better insights
        timeframe: 'immediate',
        category: 'general',
        actionSteps: [
          'Record all daily expenses',
          'Add income entries',
          'Upload receipt photos for automatic tracking'
        ],
      ));
    }

    return recommendations;
    
  } catch (e) {
    print("Error generating fallback recommendations: $e");
    return [SmartRecommendation(
      message: 'Start tracking your expenses regularly to get personalized financial recommendations.',
      type: RecommendationType.general,
      priority: RecommendationPriority.medium,
      actionable: true,
      expectedImpact: 'Better financial tracking',
      potentialSavings: 0.0,
      timeframe: 'immediate',
      category: 'general',
      actionSteps: [
        'Start recording daily expenses',
        'Add income sources',
        'Review spending patterns weekly'
      ],
    )];
  }
}

  Future<AIResponse> generateFinancialReport(String userId) async {
    if (!await _usageService.canUseFeature('aiQueries')) {
      return AIResponse.error('Monthly AI analysis limit reached. Upgrade your plan for detailed financial reports.');
    }

    try {
      final financialSummary = await _financialDataService.getFinancialSummary(userId);
      
      // Fix: Better null checking
      if (financialSummary['financialData'] == null) {
        return AIResponse.error('No financial data available. Please add some transactions first.');
      }
      
      final financialData = financialSummary['financialData'] as FinancialData;
      final taxProfile = financialSummary['taxProfile'];
      
      // Fix: Check for sufficient data
      if (financialData.transactionCount < 5) {
        return AIResponse.error('Please add more transactions (at least 5) for a comprehensive financial report.');
      }
      
      final model = _getAnalysisModel();

      final prompt = '''
Generate a comprehensive financial health report for this Bangladesh-based user:

FINANCIAL OVERVIEW:
${financialData.summaryText}

EXPENSE ANALYSIS:
${financialData.expenseBreakdownText.isNotEmpty ? financialData.expenseBreakdownText : 'Limited expense data available'}

INCOME BREAKDOWN:
${financialData.incomeBreakdownText.isNotEmpty ? financialData.incomeBreakdownText : 'Limited income data available'}

MONTHLY TRENDS:
${financialData.monthlyTrendsText.isNotEmpty ? financialData.monthlyTrendsText : 'Insufficient data for trend analysis'}

BEHAVIORAL INSIGHTS:
${financialSummary['behaviorPatterns'] ?? 'No behavioral patterns identified'}

RISK ASSESSMENT:
${financialSummary['riskAssessment'] != null ? financialSummary['riskAssessment'].toString() : 'Risk assessment pending more data'}

TAX PROFILE:
${taxProfile != null ? 'Tax profile configured with annual income data' : 'Tax profile not configured - recommend setup for tax optimization'}

DATA QUALITY:
- Total Transactions: ${financialData.transactionCount}
- Analysis Period: Last 12 months
- Income Sources: ${financialData.incomeSourceCount}
- Expense Categories: ${financialData.expenseCategoryCount}

Create a detailed markdown report with these sections:

# 📊 Financial Health Report

## Executive Summary
- Overall financial health score (1-100) based on savings rate, emergency fund, and debt status
- Key financial strengths and critical improvement areas
- Net worth trajectory and wealth building progress

## 💰 Income & Expense Analysis
- Income stability assessment (${financialData.incomeSourceCount} sources)
- Monthly cash flow: ৳${financialData.avgMonthlyIncome.toStringAsFixed(0)} income vs ৳${financialData.avgMonthlyExpenses.toStringAsFixed(0)} expenses
- Expense efficiency and optimization opportunities
- Savings rate: ${financialData.savingsRate.toStringAsFixed(1)}% vs recommended 10-20%

## 📈 Performance Metrics
- Monthly burn rate and financial runway calculation
- Category-wise spending efficiency analysis
- Year-over-year growth trends (if sufficient data)

## 🎯 Financial Goals Assessment
- Emergency fund status: Target ৳${(financialData.avgMonthlyExpenses * 6).toStringAsFixed(0)} (6 months expenses)
- Current savings: ৳${financialData.netSavings.toStringAsFixed(0)}
- Investment allocation recommendations for Bangladesh market

## 🏦 Bangladesh Tax Optimization
- Estimated tax liability based on current income patterns
- Section 44 investment opportunities (up to ৳1.5 lakhs tax exemption)
- Tax-saving strategies specific to ${financialData.avgMonthlyIncome > 50000 ? 'higher' : 'moderate'} income bracket

## ⚠️ Risk Assessment & Mitigation
- Identified financial vulnerabilities based on spending patterns
- Income concentration risk (${financialData.incomeSourceCount == 1 ? 'HIGH' : 'MODERATE'})
- Expense concentration: ${financialData.expenseConcentration.toStringAsFixed(1)}% in ${financialData.topExpenseCategory}

## 🚀 Strategic Action Plan

**Immediate Actions (Next 30 Days):**
- Specific action items with exact BDT amounts

**Medium-term Goals (3-6 Months):**
- Savings and investment targets with realistic timelines

**Long-term Strategy (1+ years):**
- Wealth building and financial independence roadmap

## 📋 Optimized Monthly Budget
- Recommended budget allocation by category based on current income
- Specific spending limits in BDT for major categories
- Automated saving strategies and investment plans

IMPORTANT: Use actual data from the analysis above to provide specific, actionable insights with real BDT amounts. Focus on practical advice suitable for Bangladesh's financial market.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text?.isNotEmpty == true) {
        await _usageService.incrementUsage('aiQueries');
        return AIResponse.success(response.text!.trim());
      } else {
        return AIResponse.error('Unable to generate financial report. Please try again.');
      }
    } catch (e) {
      print("Error in generateFinancialReport: $e");
      return AIResponse.error('Report generation failed: ${e.toString()}');
    }
  }

  // Check if service is properly configured
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  // Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'configured': isConfigured,
      'apiKeyPresent': _apiKey != null,
      'modelsInitialized': _chatModel != null || _imageModel != null || _analysisModel != null,
    };
  }
}