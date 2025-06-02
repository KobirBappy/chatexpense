// Data models for the Gemini service

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

  factory PlanLimits.fromSubscriptionPlan(String plan) {
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

  Map<String, dynamic> toJson() => {
    'chatMessages': chatMessages,
    'imageEntries': imageEntries,
    'voiceEntries': voiceEntries,
    'aiQueries': aiQueries,
  };
}

class Usage {
  final int chatMessages;
  final int imageEntries;
  final int voiceEntries;
  final int aiQueries;
  final DateTime? resetDate;

  Usage({
    required this.chatMessages,
    required this.imageEntries,
    required this.voiceEntries,
    required this.aiQueries,
    this.resetDate,
  });

  factory Usage.zero() => Usage(
        chatMessages: 0,
        imageEntries: 0,
        voiceEntries: 0,
        aiQueries: 0,
      );

  factory Usage.fromFirestore(Map<String, dynamic> data) => Usage(
        chatMessages: data['chatMessages'] ?? 0,
        imageEntries: data['imageEntries'] ?? 0,
        voiceEntries: data['voiceEntries'] ?? 0,
        aiQueries: data['aiQueries'] ?? 0,
        resetDate: data['resetDate']?.toDate(),
      );

  Map<String, dynamic> toJson() => {
    'chatMessages': chatMessages,
    'imageEntries': imageEntries,
    'voiceEntries': voiceEntries,
    'aiQueries': aiQueries,
    if (resetDate != null) 'resetDate': resetDate,
  };

  bool hasExceededLimit(PlanLimits limits, String type) {
    switch (type) {
      case 'chatMessages':
        return chatMessages >= limits.chatMessages;
      case 'imageEntries':
        return imageEntries >= limits.imageEntries;
      case 'voiceEntries':
        return voiceEntries >= limits.voiceEntries;
      case 'aiQueries':
        return aiQueries >= limits.aiQueries;
      default:
        return false;
    }
  }

  double getUsagePercentage(PlanLimits limits, String type) {
    switch (type) {
      case 'chatMessages':
        return limits.chatMessages > 0 ? (chatMessages / limits.chatMessages) * 100 : 0;
      case 'imageEntries':
        return limits.imageEntries > 0 ? (imageEntries / limits.imageEntries) * 100 : 0;
      case 'voiceEntries':
        return limits.voiceEntries > 0 ? (voiceEntries / limits.voiceEntries) * 100 : 0;
      case 'aiQueries':
        return limits.aiQueries > 0 ? (aiQueries / limits.aiQueries) * 100 : 0;
      default:
        return 0;
    }
  }
}

class SmartRecommendation {
  final String message;
  final RecommendationType type;
  final RecommendationPriority priority;
  final bool actionable;
  final String? expectedImpact;
  final List<String>? actionSteps;
  final String? timeframe;
  final String? category;
  final double? potentialSavings;
  final String? implementationTips;

  SmartRecommendation({
    required this.message,
    required this.type,
    required this.priority,
    required this.actionable,
    this.expectedImpact,
    this.actionSteps,
    this.timeframe,
    this.category,
    this.potentialSavings,
    this.implementationTips,
  });

  factory SmartRecommendation.fromJson(Map<String, dynamic> json) {
    return SmartRecommendation(
      message: json['message'] ?? '',
      type: RecommendationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecommendationType.general,
      ),
      priority: RecommendationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => RecommendationPriority.medium,
      ),
      actionable: json['actionable'] ?? true,
      expectedImpact: json['expectedImpact'],
      actionSteps: json['actionSteps'] != null 
          ? List<String>.from(json['actionSteps']) 
          : null,
      timeframe: json['timeframe'],
      category: json['category'],
      potentialSavings: json['potentialSavings']?.toDouble(),
      implementationTips: json['implementationTips'],
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'type': type.name,
    'priority': priority.name,
    'actionable': actionable,
    if (expectedImpact != null) 'expectedImpact': expectedImpact,
    if (actionSteps != null) 'actionSteps': actionSteps,
    if (timeframe != null) 'timeframe': timeframe,
    if (category != null) 'category': category,
    if (potentialSavings != null) 'potentialSavings': potentialSavings,
    if (implementationTips != null) 'implementationTips': implementationTips,
  };

  String get priorityEmoji {
    switch (priority) {
      case RecommendationPriority.high:
        return '🔴';
      case RecommendationPriority.medium:
        return '🟡';
      case RecommendationPriority.low:
        return '🟢';
    }
  }

  String get typeEmoji {
    switch (type) {
      case RecommendationType.savings:
        return '💰';
      case RecommendationType.budget:
        return '📊';
      case RecommendationType.tax:
        return '🏛️';
      case RecommendationType.investment:
        return '📈';
      case RecommendationType.emergency:
        return '🆘';
      case RecommendationType.debt:
        return '💳';
      case RecommendationType.upgrade:
        return '⭐';
      case RecommendationType.general:
        return '💡';
    }
  }
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

class FinancialData {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final double savingsRate;
  final double avgMonthlyIncome;
  final double avgMonthlyExpenses;
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final Map<String, double> monthlyExpenses;
  final Map<String, double> monthlyIncome;
  final int transactionCount;
  final String topExpenseCategory;
  final double expenseConcentration;
  final int incomeSourceCount;
  final int expenseCategoryCount;

  FinancialData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.savingsRate,
    required this.avgMonthlyIncome,
    required this.avgMonthlyExpenses,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.monthlyExpenses,
    required this.monthlyIncome,
    required this.transactionCount,
    required this.topExpenseCategory,
    required this.expenseConcentration,
    required this.incomeSourceCount,
    required this.expenseCategoryCount,
  });

  String get summaryText => '''
Total Income (12 months): ৳${totalIncome.toStringAsFixed(2)}
Total Expenses (12 months): ৳${totalExpenses.toStringAsFixed(2)}
Net Savings: ৳${netSavings.toStringAsFixed(2)}
Savings Rate: ${savingsRate.toStringAsFixed(1)}%
Average Monthly Income: ৳${avgMonthlyIncome.toStringAsFixed(2)}
Average Monthly Expenses: ৳${avgMonthlyExpenses.toStringAsFixed(2)}
Transaction Count: $transactionCount
Top Expense Category: $topExpenseCategory (${expenseConcentration.toStringAsFixed(1)}%)
Income Sources: $incomeSourceCount
Expense Categories: $expenseCategoryCount
  ''';

  String get expenseBreakdownText => expenseByCategory.entries
      .map((e) => '${e.key}: ৳${e.value.toStringAsFixed(2)} (${((e.value / totalExpenses) * 100).toStringAsFixed(1)}%)')
      .join('\n');

  String get incomeBreakdownText => incomeByCategory.entries
      .map((e) => '${e.key}: ৳${e.value.toStringAsFixed(2)} (${((e.value / totalIncome) * 100).toStringAsFixed(1)}%)')
      .join('\n');

  String get monthlyTrendsText => monthlyExpenses.entries
      .map((e) => '${e.key}: Expenses ৳${e.value.toStringAsFixed(2)}, Income ৳${(monthlyIncome[e.key] ?? 0).toStringAsFixed(2)}')
      .join('\n');

  Map<String, dynamic> toJson() => {
    'totalIncome': totalIncome,
    'totalExpenses': totalExpenses,
    'netSavings': netSavings,
    'savingsRate': savingsRate,
    'avgMonthlyIncome': avgMonthlyIncome,
    'avgMonthlyExpenses': avgMonthlyExpenses,
    'expenseByCategory': expenseByCategory,
    'incomeByCategory': incomeByCategory,
    'monthlyExpenses': monthlyExpenses,
    'monthlyIncome': monthlyIncome,
    'transactionCount': transactionCount,
    'topExpenseCategory': topExpenseCategory,
    'expenseConcentration': expenseConcentration,
    'incomeSourceCount': incomeSourceCount,
    'expenseCategoryCount': expenseCategoryCount,
  };
}

class AIResponse {
  final String? text;
  final bool success;
  final String? error;
  final DateTime timestamp;

  AIResponse({
    this.text,
    required this.success,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIResponse.success(String text) => AIResponse(
        text: text,
        success: true,
      );

  factory AIResponse.error(String error) => AIResponse(
        success: false,
        error: error,
      );

  Map<String, dynamic> toJson() => {
    if (text != null) 'text': text,
    'success': success,
    if (error != null) 'error': error,
    'timestamp': timestamp.toIso8601String(),
  };
}