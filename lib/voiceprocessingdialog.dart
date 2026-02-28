
import 'package:chatapp/theme_config.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceProcessingDialog extends StatefulWidget {
  final String? transcription;
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onCancel;

  const VoiceProcessingDialog({
    super.key,
    this.transcription,
    required this.isListening,
    required this.isProcessing,
    required this.onCancel,
  });

  @override
  State<VoiceProcessingDialog> createState() => _VoiceProcessingDialogState();
}

class _VoiceProcessingDialogState extends State<VoiceProcessingDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  int _currentTipIndex = 0;
  
  final List<Map<String, String>> _friendlyTips = [
    {
      'emoji': '🛒',
      'tip': '"I spent 200 on groceries"',
      'hint': 'Just say what you bought!'
    },
    {
      'emoji': '☕',
      'tip': '"Bought coffee for 50 taka"',
      'hint': 'Simple and natural!'
    },
    {
      'emoji': '🚕',
      'tip': '"Taxi fare 150"',
      'hint': 'No need to be formal!'
    },
    {
      'emoji': '💸',
      'tip': '"Got my salary 50000"',
      'hint': 'Income works too!'
    },
    {
      'emoji': '📱',
      'tip': '"Paid phone bill 499"',
      'hint': 'Bills are easy!'
    },
  ];
  
  final List<String> _encouragements = [
    "You're doing great! 🌟",
    "I'm all ears! 👂",
    "Take your time! ⏰",
    "Speak naturally! 💬",
    "Almost there! 🎯",
  ];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);
    
    // Cycle through tips
    Future.delayed(const Duration(seconds: 3), _cycleTips);
  }
  
  void _cycleTips() {
    if (mounted && widget.isListening) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _friendlyTips.length;
      });
      Future.delayed(const Duration(seconds: 3), _cycleTips);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon Section
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circles
                if (widget.isListening) ...[
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1 + (0.3 * math.sin(_waveAnimation.value)),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1 + (0.3 * math.sin(_waveAnimation.value + math.pi / 2)),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.15),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                
                // Main icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.isListening
                                ? [Colors.red.shade400, Colors.red.shade600]
                                : widget.isProcessing
                                    ? [AppTheme.secondaryColor, AppTheme.primaryColor]
                                    : [Colors.blue.shade400, Colors.blue.shade600],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.isListening ? Colors.red : Colors.blue).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isProcessing 
                              ? Icons.auto_awesome 
                              : Icons.mic,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Status Text with Animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                widget.isListening
                    ? _encouragements[_currentTipIndex % _encouragements.length]
                    : widget.isProcessing
                        ? 'Working my magic! ✨'
                        : 'Getting ready... 🎙️',
                key: ValueKey(widget.isListening ? _currentTipIndex : widget.isProcessing),
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            
            // Content Section
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: widget.transcription?.isNotEmpty == true
                  ? _buildTranscriptionView()
                  : _buildInstructionsView(),
            ),
            
            // Visual Indicator
            if (widget.isListening) ...[
              const SizedBox(height: 20),
              _buildSoundWaves(),
            ] else if (widget.isProcessing) ...[
              const SizedBox(height: 20),
              _buildProcessingIndicator(),
            ],
            
            const SizedBox(height: 20),
            
            // Cancel Button
            if (!widget.isProcessing)
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 18),
                    SizedBox(width: 8),
                    Text('Cancel'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTranscriptionView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            '"${widget.transcription}"',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInstructionsView() {
    if (widget.isProcessing) {
      return Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: AppTheme.primaryColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Understanding your transaction...',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'I\'ll add it automatically!',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    final currentTip = _friendlyTips[_currentTipIndex];
    
    return Column(
      children: [
        if (!widget.isListening) ...[
          Icon(
            Icons.touch_app_outlined,
            size: 40,
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the mic and tell me about your transaction',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_currentTipIndex),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    currentTip['emoji']!,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentTip['tip']!,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTip['hint']!,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildSoundWaves() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (index) {
          return AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              final delay = index * 0.1;
              final height = 20 + (15 * math.sin(_waveAnimation.value + delay));
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
  
  Widget _buildProcessingIndicator() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    size: 20,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Creating your transaction...',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
