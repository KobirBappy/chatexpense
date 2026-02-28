import 'dart:convert';
import 'dart:typed_data';
import 'package:chatapp/transaction_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw Exception(
        'Missing GEMINI_API_KEY in .env. Add GEMINI_API_KEY=your_key and restart the app.',
      );
    }
    return key;
  }

  static const List<String> _textModelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-pro',
  ];
  static const List<String> _visionModelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];
  
  static void initialize() {}
  
  static Future<Map<String, dynamic>?> analyzeReceipt(Uint8List imageBytes) async {
    try {
      const prompt = '''
      Analyze this receipt/bill image and extract the following information in JSON format:
      {
        "total_amount": number,
        "date": "YYYY-MM-DD",
        "vendor": "string",
        "category": "string (Food/Transport/Shopping/Bills/Entertainment/Other)",
        "items": [{"name": "string", "price": number}],
        "description": "brief description of the purchase"
      }
      
      If you cannot extract certain information, use null for that field.
      ''';
      
      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await _generateContentWithFallback(
        models: _visionModelCandidates,
        contents: [
        Content.multi([
          TextPart(prompt),
          imagePart,
        ])
      ],
      );
      
      final responseText = response.text;
      if (responseText == null || responseText.trim().isEmpty) {
        return null;
      }

      final parsed = _extractJsonObject(responseText);
      if (parsed == null) {
        return null;
      }

      final normalizedAmount = _toDouble(parsed['total_amount']);
      if (normalizedAmount == null) {
        return null;
      }

      return {
        'total_amount': normalizedAmount,
        'date': parsed['date'],
        'vendor': parsed['vendor'],
        'category': parsed['category'] ?? 'Other',
        'items': parsed['items'],
        'description': parsed['description'] ?? 'Receipt',
      };
    } catch (e) {
      print('Gemini analyze receipt error: $e');
      return null;
    }
  }
  
  static Future<Map<String, dynamic>?> processVoiceCommand(String transcription) async {
    try {
      final prompt = '''
      You are a financial assistant. Extract transaction information from this voice command and return ONLY valid JSON:
      
      Voice command: "$transcription"
      
      Analyze the command and extract:
      1. Transaction type (income, expense, loan_given, loan_received)
      2. Amount (extract numeric value, handle words like hundred, thousand, lakh, etc.)
      3. Category (Food, Transport, Shopping, Bills, Entertainment, Healthcare, Education, Salary, Other)
      4. Description (brief description of the transaction)
      5. Person name (only for loans)
      
      Rules:
      - For spending/bought/paid/purchased -> type: "expense"
      - For received/earned/got salary -> type: "income"
      - For lent/gave loan to -> type: "loan_given"
      - For borrowed/took loan from -> type: "loan_received"
      - Convert currency words: taka/rs/dollars to numbers
      - Handle number words: hundred=100, thousand=1000, lakh=100000
      
      Return ONLY this JSON format:
      {
        "type": "expense",
        "amount": 500,
        "category": "Food",
        "description": "Groceries",
        "person": null
      }
      
      Examples:
      - "Spent 500 taka on groceries" -> {"type": "expense", "amount": 500, "category": "Food", "description": "Groceries", "person": null}
      - "Received 5000 as salary" -> {"type": "income", "amount": 5000, "category": "Salary", "description": "Monthly salary", "person": null}
      - "Lent 2000 to John" -> {"type": "loan_given", "amount": 2000, "category": "Other", "description": "Loan to John", "person": "John"}
      - "Paid 100 for bus fare" -> {"type": "expense", "amount": 100, "category": "Transport", "description": "Bus fare", "person": null}
      ''';
      
      final response = await _generateContentWithFallback(
        models: _textModelCandidates,
        contents: [Content.text(prompt)],
      );
      
      final responseText = response.text;
      print('Gemini Response: $responseText'); // Debug log
      
      if (responseText != null) {
        // Clean the response and extract JSON
        final cleanedResponse = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        // Find JSON in the response
        final jsonStart = cleanedResponse.indexOf('{');
        final jsonEnd = cleanedResponse.lastIndexOf('}');
        
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = cleanedResponse.substring(jsonStart, jsonEnd + 1);
          try {
            final parsed = json.decode(jsonString);
            
            // Validate and clean the parsed data
            return {
              'type': parsed['type'] ?? 'expense',
              'amount': _parseAmount(parsed['amount']),
              'category': parsed['category'] ?? 'Other',
              'description': parsed['description'] ?? transcription,
              'person': parsed['person'],
            };
          } catch (e) {
            print('JSON parsing error: $e');
            // Return a default response if parsing fails
            return _createDefaultResponse(transcription);
          }
        } else {
          return _createDefaultResponse(transcription);
        }
      }
      
      return null;
    } catch (e) {
      print('Gemini process voice error: $e');
      return _createDefaultResponse(transcription);
    }
  }
  
  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      // Try to parse the string to a number
      final parsed = double.tryParse(amount);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  static Map<String, dynamic>? _extractJsonObject(String text) {
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      return null;
    }

    try {
      final decoded = json.decode(cleaned.substring(jsonStart, jsonEnd + 1));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<GenerateContentResponse> _generateContentWithFallback({
    required List<String> models,
    required List<Content> contents,
  }) async {
    Object? lastError;
    for (final modelName in models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
        );
        return await model.generateContent(contents);
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('No supported Gemini model available. Last error: $lastError');
  }
  
  static Map<String, dynamic> _createDefaultResponse(String transcription) {
    // Simple pattern matching for common commands
    final lowerCase = transcription.toLowerCase();
    
    // Extract amount using regex
    final amountRegex = RegExp(r'(\d+\.?\d*)');
    final amountMatch = amountRegex.firstMatch(lowerCase);
    final amount = amountMatch != null ? double.tryParse(amountMatch.group(1)!) ?? 0.0 : 0.0;
    
    // Determine type
    String type = 'expense';
    if (lowerCase.contains('received') || lowerCase.contains('earned') || lowerCase.contains('got')) {
      type = 'income';
    } else if (lowerCase.contains('lent') || lowerCase.contains('gave') && lowerCase.contains('loan')) {
      type = 'loan_given';
    } else if (lowerCase.contains('borrowed') || lowerCase.contains('took') && lowerCase.contains('loan')) {
      type = 'loan_received';
    }
    
    // Determine category
    String category = 'Other';
    if (lowerCase.contains('food') || lowerCase.contains('lunch') || lowerCase.contains('dinner') || 
        lowerCase.contains('breakfast') || lowerCase.contains('groceries') || lowerCase.contains('restaurant')) {
      category = 'Food';
    } else if (lowerCase.contains('transport') || lowerCase.contains('bus') || lowerCase.contains('taxi') || 
               lowerCase.contains('uber') || lowerCase.contains('fuel') || lowerCase.contains('petrol')) {
      category = 'Transport';
    } else if (lowerCase.contains('shopping') || lowerCase.contains('clothes') || lowerCase.contains('shoes')) {
      category = 'Shopping';
    } else if (lowerCase.contains('bill') || lowerCase.contains('electricity') || lowerCase.contains('water') || 
               lowerCase.contains('rent') || lowerCase.contains('internet')) {
      category = 'Bills';
    } else if (lowerCase.contains('movie') || lowerCase.contains('entertainment') || lowerCase.contains('game')) {
      category = 'Entertainment';
    } else if (lowerCase.contains('salary') || lowerCase.contains('payment') && type == 'income') {
      category = 'Salary';
    }
    
    return {
      'type': type,
      'amount': amount,
      'category': category,
      'description': transcription,
      'person': null,
    };
  }
  
  static Future<Map<String, dynamic>?> generateFinancialInsights(
    List<TransactionModel> transactions,
  ) async {
    try {
      // Prepare transaction summary
      final summary = transactions.map((t) => {
        'type': t.type.name,
        'amount': t.amount,
        'category': t.category,
        'date': t.date.toIso8601String(),
      }).toList();
      
      final prompt = '''
      Analyze these financial transactions and provide insights:
      ${json.encode(summary)}
      
      Return JSON with:
      {
        "total_income": number,
        "total_expenses": number,
        "savings_rate": percentage,
        "top_categories": [{"category": "string", "amount": number, "percentage": number}],
        "spending_trend": "increasing/decreasing/stable",
        "recommendations": ["string"],
        "anomalies": ["string"]
      }
      ''';
      
      final response = await _generateContentWithFallback(
        models: _textModelCandidates,
        contents: [Content.text(prompt)],
      );
      
      final responseText = response.text;
      if (responseText != null) {
        final jsonStart = responseText.indexOf('{');
        final jsonEnd = responseText.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = responseText.substring(jsonStart, jsonEnd + 1);
          return json.decode(jsonString);
        }
      }
      
      return null;
    } catch (e) {
      print('Gemini generate insights error: $e');
      return null;
    }
  }
}
