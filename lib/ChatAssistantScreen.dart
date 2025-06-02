

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:chatapp/page5_main_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';

class ChatAssistantScreen extends StatefulWidget {
  const ChatAssistantScreen({Key? key}) : super(key: key);

  @override
  State<ChatAssistantScreen> createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends State<ChatAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;
  bool _isListening = false;
  String? _lastError;
  String _voiceText = '';
  
  // Get current user ID
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic>? _parseTransactionFromVoice(String text) {
    try {
      // 1. Extract amount
      final amountRegex = RegExp(r'(\d+([\.,]\d{1,2})?)\s*(dollars|taka|\$|tk)?', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(text);
      if (amountMatch == null) return null;

      final amountStr = amountMatch.group(1)!.replaceAll(',', '.');
      final amount = double.tryParse(amountStr);
      if (amount == null) return null;

      // 2. Determine if it's earning or expense
      final isEarning = text.contains(RegExp(r'earn|income|salary|received', caseSensitive: false));
      final type = isEarning ? 'earning' : 'expense';

      // 3. Extract date
      DateTime date = DateTime.now();
      final now = DateTime.now();
      
      if (text.contains('yesterday')) {
        date = now.subtract(const Duration(days: 1));
      } 
      else if (text.contains('last week')) {
        date = now.subtract(const Duration(days: 7));
      }
      else {
        final dateRegex = RegExp(
          r'(\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?\b|\d{1,2}(?:st|nd|rd|th)?\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*)|(\d{4}[-/]\d{1,2}[-/]\d{1,2})',
          caseSensitive: false,
        );
        
        final dateMatch = dateRegex.firstMatch(text);
        if (dateMatch != null) {
          final dateStr = dateMatch.group(0)!;
          try {
            date = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
          } catch (e) {
            try {
              date = DateFormat('MMMM d', 'en_US').parse(dateStr);
            } catch (_) {}
          }
        }
      }

      // 4. Extract category
      String category = isEarning ? 'Income' : 'Uncategorized';
      final categoryKeywords = {
        'Food': ['coffee', 'dining', 'restaurant', 'cafe', 'lunch', 'dinner', 'food'],
        'Transport': ['transport', 'bus', 'taxi', 'uber', 'fuel', 'gas'],
        'Shopping': ['shopping', 'clothes', 'electronics', 'store'],
        'Bills': ['electricity', 'water', 'gas', 'internet', 'phone', 'rent', 'lease'],
        'Entertainment': ['movie', 'concert', 'ticket', 'netflix', 'game'],
        'Health': ['hospital', 'doctor', 'medicine', 'pharmacy'],
        'Education': ['school', 'course', 'book', 'tuition'],
        'Others': ['grocery', 'supermarket', 'market'],
      };

      for (final entry in categoryKeywords.entries) {
        if (entry.value.any((keyword) => text.toLowerCase().contains(keyword))) {
          category = entry.key;
          break;
        }
      }

      // 5. Extract description
      String description = isEarning ? 'Voice earning' : 'Voice expense';
      final descriptionRegex = RegExp(r'(?:on|for|from)\s+([^.?!]+)', caseSensitive: false);
      final descriptionMatch = descriptionRegex.firstMatch(text);
      if (descriptionMatch != null) {
        description = descriptionMatch.group(1)!.trim();
      }

      return {
        'amount': isEarning ? amount : -amount,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'category': category,
        'description': description,
        'type': type,
        'taxable': isEarning,
      };
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final status = _geminiService.getServiceStatus();
    print('Gemini Service Status: $status');
    
    if (!_geminiService.isUserAuthenticated) {
      setState(() => _lastError = 'Please log in to use AI features');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    
    if (!_geminiService.isUserAuthenticated) {
      setState(() => _lastError = 'Please log in to send messages');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    final userMessage = {
      'text': text.trim(),
      'sender': 'user',
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Add user message to Firestore
      await FirebaseFirestore.instance.collection('messages').add(userMessage);
      _controller.clear();

      // Get AI response using the new service
      final aiResponse = await _geminiService.getTextResponse(text);
      
      if (aiResponse.success && aiResponse.text != null) {
        // Add AI response to Firestore
        await FirebaseFirestore.instance.collection('messages').add({
          'text': aiResponse.text!,
          'sender': 'assistant',
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Handle AI error
        await FirebaseFirestore.instance.collection('messages').add({
          'text': '❌ ${aiResponse.error ?? "Sorry, I couldn't process your request."}',
          'sender': 'assistant',
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      setState(() => _lastError = 'Failed to send message: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _listenToVoice() async {
    if (_isListening) {
      _stopListening();
      return;
    }

    // Check voice usage limit using the new service
    if (!await _geminiService.canUseFeature('voiceEntries')) {
      setState(() => _lastError = 'Voice entry limit reached. Upgrade plan for more');
      return;
    }

    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(onStatus: (status) {
      if (status == 'notListening') {
        _handleVoiceResult(_voiceText);
      }
    });

    if (!available) {
      setState(() => _lastError = 'Microphone not available');
      return;
    }

    setState(() {
      _isListening = true;
      _voiceText = '';
      _controller.text = '';
    });
    
    _speech.listen(
      onResult: (result) {
        setState(() {
          _voiceText = result.recognizedWords;
          _controller.text = _voiceText;
        });
      },
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _handleVoiceResult(String text) async {
    _stopListening();
    if (text.isEmpty) return;

    final transaction = _parseTransactionFromVoice(text);
    if (transaction != null) {
      await _saveTransaction(transaction, '');
      // Note: Usage tracking is now handled internally by the service
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${transaction['type'] == 'earning' ? 'Earning' : 'Expense'} saved: ${transaction['description']}')),
      );
    } else {
      _sendMessage(text);
    }
  }

  void _pickImageFromGallery() => _uploadAndProcessImage(ImageSource.gallery);
  void _captureImageWithCamera() => _uploadAndProcessImage(ImageSource.camera);

  Future<void> _uploadAndProcessImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final file = File(pickedFile.path);
      final fileName = "uploads/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      final Uint8List bytes = await file.readAsBytes();
      await _processImageWithGemini(bytes, downloadUrl);
    } catch (e) {
      setState(() => _lastError = "Image processing failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processImageWithGemini(Uint8List imageBytes, String imageUrl) async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      // Use the new processReceiptImage method
      final response = await _geminiService.processReceiptImage(imageBytes);
      
      if (!response.success) {
        setState(() => _lastError = response.error ?? 'Image processing failed');
        return;
      }

      if (response.text == null || response.text!.isEmpty) {
        setState(() => _lastError = 'No transaction data found in image');
        return;
      }

      // Clean and parse the JSON response
      final cleanedText = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = _parseTransactionJson(cleanedText);
      
      if (parsed != null && parsed['amount'] != null) {
        await _saveTransaction(parsed, imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${parsed['type'] == 'earning' ? 'Earning' : 'Expense'} saved!')),
        );
      } else {
        // Fallback to regex extraction
        final regexData = _extractTransactionFromText(response.text!);
        if (regexData.isNotEmpty && regexData['amount'] != null) {
          await _saveTransaction(regexData, imageUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction saved!')),
          );
        } else {
          setState(() => _lastError = 'No valid transaction data found in image');
        }
      }
    } catch (e) {
      setState(() => _lastError = 'Image processing error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _parseTransactionJson(String text) {
    try {
      final data = json.decode(text) as Map<String, dynamic>;
      
      // Check for error in response
      if (data.containsKey('error')) {
        setState(() => _lastError = data['error'].toString());
        return null;
      }
      
      // Determine type if not provided
      String type = 'expense';
      if (data['type'] != null) {
        type = data['type'].toString().toLowerCase();
      } else if (data['description']?.toString().toLowerCase().contains('salary') == true) {
        type = 'earning';
      }

      // Handle amount sign
      double amount = data['amount'] is num ? data['amount'].toDouble() : 0.0;
      if (type == 'expense' && amount > 0) amount = -amount;
      if (type == 'earning' && amount < 0) amount = amount.abs();

      return {
        'amount': amount,
        'date': data['date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'category': data['category']?.toString() ?? (type == 'earning' ? 'Income' : 'Others'),
        'description': data['description']?.toString() ?? 'Transaction from receipt',
        'type': type,
        'taxable': type == 'earning',
      };
    } catch (e) {
      print('JSON parsing error: $e');
      return null;
    }
  }

  Map<String, dynamic> _extractTransactionFromText(String text) {
    final Map<String, dynamic> data = {};
    
    final amountRegex = RegExp(r'\b(\d+\.\d{2})\b|\b(\d+)\b');
    final dateRegex = RegExp(r'\b(\d{4}[-/]\d{2}[-/]\d{2})\b');
    final categoryRegex = RegExp(
      r'(food|transport|shopping|bill|grocery|rent|utilities|dining|entertainment|salary|income|health|education)',
      caseSensitive: false,
    );

    final amountMatch = amountRegex.firstMatch(text);
    final dateMatch = dateRegex.firstMatch(text);
    final categoryMatch = categoryRegex.firstMatch(text);

    if (amountMatch != null) {
      final amountString = amountMatch.group(0);
      if (amountString != null) {
        data['amount'] = double.tryParse(amountString) ?? 0.0;
      }
    }
    
    data['date'] = dateMatch?.group(0) ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    data['category'] = categoryMatch != null ? _capitalize(categoryMatch.group(0)!) : 'Others';
    
    // Determine type
    final isEarning = text.toLowerCase().contains(RegExp(r'earn|income|salary|received'));
    data['type'] = isEarning ? 'earning' : 'expense';
    data['amount'] = (data['amount'] ?? 0.0) * (isEarning ? 1 : -1);
    data['description'] = text.length > 100 ? text.substring(0, 100) : text;
    data['taxable'] = isEarning;

    return data;
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<void> _saveTransaction(Map<String, dynamic> data, String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DateTime expenseDate;
      if (data['date'] is String) {
        expenseDate = DateTime.tryParse(data['date']) ?? DateTime.now();
      } else {
        expenseDate = DateTime.now();
      }

      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'amount': data['amount'],
        'description': data['description'] ?? 'Transaction from assistant',
        'category': data['category'] ?? (data['type'] == 'earning' ? 'Income' : 'Others'),
        'date': expenseDate,
        'imageUrl': imageUrl,
        'source': imageUrl.isEmpty ? 'voice' : 'image',
        'type': data['type'] ?? 'expense',
        'taxable': data['taxable'] ?? (data['type'] == 'earning'),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (data['category'] != null && data['category'] != 'Uncategorized') {
        await _updateCategory(data['category']!);
      }
    } catch (e) {
      setState(() => _lastError = 'Failed to save transaction: $e');
    }
  }

  Future<void> _updateCategory(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final categories = FirebaseFirestore.instance.collection('categories');
    final snapshot = await categories
        .where('name', isEqualTo: category)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await categories.add({
        'name': category,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildBubble(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final bool isUser = data['sender'] == 'user';
    final String text = data['text'] ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'You' : 'Assistant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.blue.shade800 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateFinancialReport() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      // Use the new generateFinancialReport method
      final response = await _geminiService.generateFinancialReport();
      
      if (response.success && response.text != null) {
        await FirebaseFirestore.instance.collection('messages').add({
          'text': "📊 Financial Health Report:\n\n${response.text!}",
          'sender': 'assistant',
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        setState(() => _lastError = response.error ?? 'Failed to generate report');
      }
    } catch (e) {
      setState(() => _lastError = 'Report error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _showUsageStatus() async {
    try {
      final usage = await _geminiService.getCurrentUsage();
      final limits = await _geminiService.getPlanLimits();
      final percentages = await _geminiService.getUsagePercentages();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Usage Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat Messages: ${usage.chatMessages}/${limits.chatMessages} (${percentages['chatMessages']!.toStringAsFixed(1)}%)'),
              Text('Image Entries: ${usage.imageEntries}/${limits.imageEntries} (${percentages['imageEntries']!.toStringAsFixed(1)}%)'),
              Text('Voice Entries: ${usage.voiceEntries}/${limits.voiceEntries} (${percentages['voiceEntries']!.toStringAsFixed(1)}%)'),
              Text('AI Queries: ${usage.aiQueries}/${limits.aiQueries} (${percentages['aiQueries']!.toStringAsFixed(1)}%)'),
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
      setState(() => _lastError = 'Failed to get usage status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_geminiService.isUserAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to use the assistant'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Assistant"),
        actions: [
          IconButton(
            icon: _isListening
                ? const Icon(Icons.hearing, color: Colors.redAccent)
                : const Icon(Icons.mic),
            onPressed: _isLoading ? null : _listenToVoice,
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _isLoading ? null : _pickImageFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _isLoading ? null : _captureImageWithCamera,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _isLoading ? null : _generateFinancialReport,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showUsageStatus,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_lastError != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_lastError!)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _lastError = null),
                  )
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ask me about financial advice!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _buildBubble(docs[index]);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}