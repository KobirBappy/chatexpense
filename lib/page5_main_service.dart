import 'dart:typed_data';
import 'package:chatapp/page1_models.dart';
import 'package:chatapp/page2_usage_service.dart';
import 'package:chatapp/page3_financial_service.dart';
import 'package:chatapp/page4_ai_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/tax_profile_model.dart';

// Import all the modular services

/// Main service class that coordinates all Gemini AI functionality
/// This acts as a facade pattern for easier usage throughout the app
class GeminiService {
  // Service instances
  final UsageService _usageService = UsageService();
  final FinancialDataService _financialDataService = FinancialDataService();
  final GeminiAIService _aiService = GeminiAIService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Authentication helper
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _currentUserId != null;

  /// Get current user's plan limits
  Future<PlanLimits> getPlanLimits() async {
    if (!isUserAuthenticated) {
      throw Exception("User not authenticated");
    }
    return await _usageService.getPlanLimits();
  }

  /// Get current usage statistics
  Future<Usage> getCurrentUsage() async {
    if (!isUserAuthenticated) {
      throw Exception("User not authenticated");
    }
    return await _usageService.getCurrentUsage();
  }

  /// Check if a specific feature can be used (hasn't exceeded limits)
  Future<bool> canUseFeature(String featureType) async {
    if (!isUserAuthenticated) return false;
    return await _usageService.canUseFeature(featureType);
  }

  /// Get usage percentages for all features
  Future<Map<String, double>> getUsagePercentages() async {
    if (!isUserAuthenticated) {
      return {'chatMessages': 0, 'imageEntries': 0, 'voiceEntries': 0, 'aiQueries': 0};
    }
    return await _usageService.getUsagePercentages();
  }

  /// Get remaining quota for a specific feature
  Future<int> getRemainingQuota(String featureType) async {
    if (!isUserAuthenticated) return 0;
    return await _usageService.getRemainingQuota(featureType);
  }

  /// Check if user is near their usage limit
  Future<bool> isNearLimit(String featureType, {double threshold = 0.8}) async {
    if (!isUserAuthenticated) return false;
    return await _usageService.isNearLimit(featureType, threshold: threshold);
  }

  /// Get simple text response from AI
  Future<AIResponse> getTextResponse(String input) async {
    if (!isUserAuthenticated) {
      return AIResponse.error("Please log in to use AI features");
    }

    if (!_aiService.isConfigured) {
      return AIResponse.error("AI service not properly configured");
    }

    return await _aiService.getTextResponse(input);
  }

  /// Process receipt/financial document image
  Future<AIResponse> processReceiptImage(Uint8List imageBytes) async {
    if (!isUserAuthenticated) {
      return AIResponse.error("Please log in to use image processing");
    }

    if (!_aiService.isConfigured) {
      return AIResponse.error("AI service not properly configured");
    }

    return await _aiService.processReceiptImage(imageBytes);
  }

  /// Get personalized tax optimization advice
  Future<AIResponse> getTaxOptimizationAdvice(BangladeshTaxProfile profile, String s) async {
    if (!isUserAuthenticated) {
      return AIResponse.error("Please log in to get tax advice");
    }

    if (!_aiService.isConfigured) {
      return AIResponse.error("AI service not properly configured");
    }

    return await _aiService.getTaxOptimizationAdvice(profile, _currentUserId!);
  }

  /// Generate smart financial recommendations
  Future<List<SmartRecommendation>> generateSmartRecommendations() async {
    if (!isUserAuthenticated) {
      return [SmartRecommendation(
        message: 'Please log in to get personalized recommendations',
        type: RecommendationType.general,
        priority: RecommendationPriority.high,
        actionable: false,
      )];
    }

    if (!_aiService.isConfigured) {
      return [SmartRecommendation(
        message: 'AI service not configured. Please check your setup.',
        type: RecommendationType.general,
        priority: RecommendationPriority.high,
        actionable: false,
      )];
    }

    return await _aiService.generateSmartRecommendations(_currentUserId!);
  }

  /// Generate comprehensive financial report
  Future<AIResponse> generateFinancialReport() async {
    if (!isUserAuthenticated) {
      return AIResponse.error("Please log in to generate financial reports");
    }

    if (!_aiService.isConfigured) {
      return AIResponse.error("AI service not properly configured");
    }

    return await _aiService.generateFinancialReport(_currentUserId!);
  }

  /// Get user's financial data summary
  Future<FinancialData> getFinancialData({bool forceRefresh = false}) async {
    if (!isUserAuthenticated) {
      throw Exception("User not authenticated");
    }

    return await _financialDataService.getUserFinancialData(
      _currentUserId!, 
      forceRefresh: forceRefresh
    );
  }

  /// Get detailed financial summary with insights
  Future<Map<String, dynamic>> getFinancialSummary() async {
    if (!isUserAuthenticated) {
      throw Exception("User not authenticated");
    }

    return await _financialDataService.getFinancialSummary(_currentUserId!);
  }

  /// Get monthly spending trends
  Future<List<Map<String, dynamic>>> getMonthlyTrends({int months = 12}) async {
    if (!isUserAuthenticated) {
      return [];
    }

    return await _financialDataService.getMonthlyTrends(_currentUserId!, months: months);
  }

  /// Get category-wise spending for a period
  Future<Map<String, double>> getCategorySpending({int days = 30}) async {
    if (!isUserAuthenticated) {
      return {};
    }

    return await _financialDataService.getCategorySpending(_currentUserId!, days: days);
  }

  /// Clear all cached data (useful after major data changes)
  void clearAllCaches() {
    _usageService.clearCache();
    _financialDataService.clearCache();
  }

  /// Refresh user's financial data
  Future<FinancialData> refreshFinancialData() async {
    if (!isUserAuthenticated) {
      throw Exception("User not authenticated");
    }

    return await _financialDataService.refreshFinancialData(_currentUserId!);
  }

  /// Get service health status
  Map<String, dynamic> getServiceStatus() {
    final aiStatus = _aiService.getServiceStatus();
    
    return {
      'userAuthenticated': isUserAuthenticated,
      'userId': _currentUserId,
      'aiService': aiStatus,
      'services': {
        'usage': 'initialized',
        'financialData': 'initialized',
        'aiService': aiStatus['configured'] ? 'configured' : 'not_configured',
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Initialize services (call this in app startup)
  Future<void> initialize() async {
    try {
      // Services initialize themselves, but we can add any global setup here
      print("GeminiService initialized successfully");
    } catch (e) {
      print("Error initializing GeminiService: $e");
    }
  }

  /// Batch operations for efficiency
  Future<Map<String, dynamic>> getBatchUserData() async {
    if (!isUserAuthenticated) {
      throw Exception("User not authenticated");
    }

    try {
      final results = await Future.wait([
        getCurrentUsage(),
        getPlanLimits(),
        getFinancialData(),
        getUsagePercentages(),
      ]);

      return {
        'usage': results[0] as Usage,
        'limits': results[1] as PlanLimits,
        'financialData': results[2] as FinancialData,
        'usagePercentages': results[3] as Map<String, double>,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      print("Error getting batch user data: $e");
      rethrow;
    }
  }

  /// Get user insights and recommendations in one call
  Future<Map<String, dynamic>> getUserInsights() async {
    if (!isUserAuthenticated) {
      throw Exception("User not authenticated");
    }

    try {
      final results = await Future.wait([
        getFinancialSummary(),
        generateSmartRecommendations(),
        getMonthlyTrends(months: 6),
        getCategorySpending(days: 30),
      ]);

      return {
        'financialSummary': results[0] as Map<String, dynamic>,
        'recommendations': results[1] as List<SmartRecommendation>,
        'monthlyTrends': results[2] as List<Map<String, dynamic>>,
        'categorySpending': results[3] as Map<String, double>,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      print("Error getting user insights: $e");
      rethrow;
    }
  }

  /// Helper method to check if user can use premium features
  Future<bool> canUsePremiumFeatures() async {
    if (!isUserAuthenticated) return false;
    
    try {
      final limits = await getPlanLimits();
      // Consider premium if user has more than free tier limits
      return limits.aiQueries > 10 || limits.chatMessages > 60;
    } catch (e) {
      return false;
    }
  }

  /// Get feature availability summary
  Future<Map<String, bool>> getFeatureAvailability() async {
    if (!isUserAuthenticated) {
      return {
        'chatMessages': false,
        'imageEntries': false,
        'voiceEntries': false,
        'aiQueries': false,
      };
    }

    return {
      'chatMessages': await canUseFeature('chatMessages'),
      'imageEntries': await canUseFeature('imageEntries'),
      'voiceEntries': await canUseFeature('voiceEntries'),
      'aiQueries': await canUseFeature('aiQueries'),
    };
  }

  /// Development/testing helper methods
  Future<void> resetUsageForTesting() async {
    if (!isUserAuthenticated) return;
    await _usageService.resetUsageForTesting();
  }

  /// Dispose method for cleanup
  void dispose() {
    // Clean up any resources if needed
    clearAllCaches();
  }
}