import 'package:chatapp/page1_models.dart';
import 'package:chatapp/page5_main_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// Complete examples showing how to use the refactored GeminiService
/// Copy these patterns to implement in your actual app screens

class GeminiServiceExamplesWidget extends StatefulWidget {
  const GeminiServiceExamplesWidget({super.key});

  @override
  State<GeminiServiceExamplesWidget> createState() => _GeminiServiceExamplesWidgetState();
}

class _GeminiServiceExamplesWidgetState extends State<GeminiServiceExamplesWidget> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _geminiService.initialize();
    _checkServiceStatus();
  }

  void _checkServiceStatus() async {
    final status = _geminiService.getServiceStatus();
    print('Service Status: $status');
  }

  /// Example 1: Simple AI Chat
  Future<void> _askAI() async {
    if (_inputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await _geminiService.getTextResponse(_inputController.text);
      
      if (response.success) {
        setState(() => _result = response.text ?? 'No response');
      } else {
        setState(() => _result = 'Error: ${response.error}');
      }
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Example 2: Get Complete Financial Insights
  Future<void> _getFinancialInsights() async {
    setState(() => _isLoading = true);
    
    try {
      if (!_geminiService.isUserAuthenticated) {
        setState(() => _result = 'Please log in to view insights');
        return;
      }

      final insights = await _geminiService.getUserInsights();
      final financialData = insights['financialSummary']['financialData'] as FinancialData;
      final recommendations = insights['recommendations'] as List<SmartRecommendation>;
      
      String insightText = '''
📊 FINANCIAL HEALTH SUMMARY
${'-' * 40}
💰 Total Income: ৳${financialData.totalIncome.toStringAsFixed(2)}
💸 Total Expenses: ৳${financialData.totalExpenses.toStringAsFixed(2)}
💵 Net Savings: ৳${financialData.netSavings.toStringAsFixed(2)}
📈 Savings Rate: ${financialData.savingsRate.toStringAsFixed(1)}%
📊 Transactions: ${financialData.transactionCount}

🎯 TOP RECOMMENDATIONS
${'-' * 40}
${recommendations.take(3).map((r) => '${r.priorityEmoji} ${r.message}').join('\n\n')}
      ''';
      
      setState(() => _result = insightText);
    } catch (e) {
      setState(() => _result = 'Error getting insights: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Example 3: Generate Smart Recommendations
  Future<void> _getRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      final recommendations = await _geminiService.generateSmartRecommendations();
      
      String recText = '🧠 SMART RECOMMENDATIONS\n${'=' * 40}\n\n';
      
      for (int i = 0; i < recommendations.length; i++) {
        final rec = recommendations[i];
        recText += '${i + 1}. ${rec.priorityEmoji} ${rec.typeEmoji} ${rec.message}\n';
        
        if (rec.expectedImpact != null) {
          recText += '   💡 Impact: ${rec.expectedImpact}\n';
        }
        
        if (rec.timeframe != null) {
          recText += '   ⏰ Timeframe: ${rec.timeframe}\n';
        }
        
        recText += '\n';
      }
      
      setState(() => _result = recText);
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Example 4: Check Usage Limits and Status
  Future<void> _checkUsageLimits() async {
    setState(() => _isLoading = true);
    
    try {
      final batchData = await _geminiService.getBatchUserData();
      final usage = batchData['usage'] as Usage;
      final limits = batchData['limits'] as PlanLimits;
      final percentages = batchData['usagePercentages'] as Map<String, double>;
      
      String usageText = '''
📊 USAGE STATUS & LIMITS
${'=' * 40}

💬 Chat Messages: ${usage.chatMessages}/${limits.chatMessages}
   Progress: ${percentages['chatMessages']!.toStringAsFixed(1)}%
   ${_getProgressBar(percentages['chatMessages']!)}

🖼️ Image Entries: ${usage.imageEntries}/${limits.imageEntries}
   Progress: ${percentages['imageEntries']!.toStringAsFixed(1)}%
   ${_getProgressBar(percentages['imageEntries']!)}

🧠 AI Queries: ${usage.aiQueries}/${limits.aiQueries}
   Progress: ${percentages['aiQueries']!.toStringAsFixed(1)}%
   ${_getProgressBar(percentages['aiQueries']!)}

🎤 Voice Entries: ${usage.voiceEntries}/${limits.voiceEntries}
   Progress: ${percentages['voiceEntries']!.toStringAsFixed(1)}%
   ${_getProgressBar(percentages['voiceEntries']!)}

✅ FEATURE AVAILABILITY
${'-' * 40}
      ''';
      
      final availability = await _geminiService.getFeatureAvailability();
      availability.forEach((feature, available) {
        final icon = available ? "✅" : "❌";
        final status = available ? "Available" : "Limit reached";
        usageText += '$icon $feature: $status\n';
      });
      
      setState(() => _result = usageText);
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getProgressBar(double percentage) {
    final filled = (percentage / 10).round();
    final empty = 10 - filled;
    return '[${'█' * filled}${'░' * empty}]';
  }

  /// Example 5: Generate Financial Report
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _geminiService.generateFinancialReport();
      
      if (response.success) {
        setState(() => _result = response.text ?? 'No report generated');
      } else {
        setState(() => _result = 'Error: ${response.error}');
      }
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Example 6: Check if can use feature before using
  Future<void> _checkFeatureAndUse() async {
    final canUseAI = await _geminiService.canUseFeature('aiQueries');
    
    if (!canUseAI) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI query limit reached. Please upgrade your plan.'),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () {
              // Navigate to upgrade screen
              print('Navigate to upgrade screen');
            },
          ),
        ),
      );
      return;
    }
    
    // Proceed with AI feature
    await _getRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Service Examples'),
        backgroundColor: Colors.blue[50],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input field for AI chat
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Ask AI about your finances...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chat),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _askAI,
                        child: const Text('Ask AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getFinancialInsights,
                          icon: const Icon(Icons.insights),
                          label: const Text('Insights'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkFeatureAndUse,
                          icon: const Icon(Icons.recommend),
                          label: const Text('Smart Rec'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkUsageLimits,
                          icon: const Icon(Icons.analytics),
                          label: const Text('Usage'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateReport,
                          icon: const Icon(Icons.assessment),
                          label: const Text('Report'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loading indicator
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Processing...'),
                    ],
                  ),
                ),
              ),
            
            // Results display
            if (!_isLoading && _result.isNotEmpty)
              Expanded(
                child: Card(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Results',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _result));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          Text(
                            _result,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _geminiService.dispose();
    super.dispose();
  }
}

/// Example of how to initialize the service in your main app
class AppInitializationExample {
  static Future<void> initializeServices() async {
    try {
      // Initialize Gemini service on app startup
      final geminiService = GeminiService();
      await geminiService.initialize();
      
      // Check service status
      final status = geminiService.getServiceStatus();
      print('✅ Gemini Service initialized: ${status['services']}');
      
    } catch (e) {
      print('❌ Error initializing Gemini Service: $e');
    }
  }
}

/// Example widget showing how to use recommendations in your UI
class RecommendationsWidget extends StatelessWidget {
  const RecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SmartRecommendation>>(
      future: GeminiService().generateSmartRecommendations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }
        
        final recommendations = snapshot.data ?? [];
        
        if (recommendations.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 8),
                  Text('All good! No recommendations at this time.'),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final rec = recommendations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPriorityColor(rec.priority).withOpacity(0.1),
                  child: Text(
                    rec.typeEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(
                  rec.message,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: rec.expectedImpact != null 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('💡 Impact: ${rec.expectedImpact}'),
                          if (rec.timeframe != null)
                            Text('⏰ ${rec.timeframe}'),
                        ],
                      )
                    : null,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(rec.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec.priority.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  // Handle recommendation tap - maybe show details or action
                  _showRecommendationDetails(context, rec);
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return Colors.red;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.low:
        return Colors.green;
    }
  }

  void _showRecommendationDetails(BuildContext context, SmartRecommendation rec) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(rec.typeEmoji),
            const SizedBox(width: 8),
            Expanded(child: Text('${rec.type.name.toUpperCase()} Recommendation')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rec.message),
            if (rec.actionSteps != null) ...[
              const SizedBox(height: 16),
              const Text('Action Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...rec.actionSteps!.map((step) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $step'),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (rec.actionable)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle taking action on recommendation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Take Action'),
            ),
        ],
      ),
    );
  }
}

/// Example usage in main.dart
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Gemini Service
  await AppInitializationExample.initializeServices();
  
  runApp(MyApp());
}
*/