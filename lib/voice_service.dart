import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isListening = false;
  static bool _isInitialized = false;
  
  static bool get isListening => _isListening;
  
  static Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
      
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      
      return _isInitialized;
    } catch (e) {
      print('Voice service initialization error: $e');
      return false;
    }
  }
  
  static Future<String?> startListening({
    required Function(String) onResult,
    Function? onListening,
    Function? onComplete,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }
    
    if (_isListening) {
      await stopListening();
      return null;
    }
    
    _isListening = true;
    onListening?.call();
    
    String finalResult = '';
    
    await _speech.listen(
      onResult: (result) {
        finalResult = result.recognizedWords;
        onResult(finalResult);
        
        if (result.finalResult) {
          _isListening = false;
          onComplete?.call();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
    
    return finalResult;
  }
  
  static Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
  
  static void dispose() {
    _speech.cancel();
    _isListening = false;
  }
}