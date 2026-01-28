import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import '../../core/theme/modern_theme.dart';

class EasterEggWidget extends StatefulWidget {
  final Widget child;
  final String soundFile;
  final String emoji;
  final String message;
  final Color messageColor;

  const EasterEggWidget({
    super.key,
    required this.child,
    required this.soundFile,
    required this.emoji,
    required this.message,
    this.messageColor = ModernTheme.primaryOrange,
  });

  @override
  State<EasterEggWidget> createState() => _EasterEggWidgetState();
}

class _EasterEggWidgetState extends State<EasterEggWidget> {
  final _audioPlayer = AudioPlayer();
  int _tapCount = 0;
  DateTime? _lastTapTime;
  OverlayEntry? _emojiRainfallOverlay;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _emojiRainfallOverlay?.remove();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final now = DateTime.now();
    
    // Reset counter if more than 2 seconds since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _tapCount = 0;
    }
    
    _lastTapTime = now;
    _tapCount++;
    
    // Easter egg: Trigger after 3-4 taps
    if (_tapCount >= 3 && _tapCount <= 4) {
      HapticFeedback.heavyImpact();
      try {
        await _audioPlayer.play(AssetSource(widget.soundFile));
        
        // Show emoji rainfall
        _showEmojiRainfall();
        
        // Show fun message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(widget.emoji),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: widget.messageColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Reset counter after playing
        _tapCount = 0;
      } catch (e) {
        // Silent error handling for production
      }
    }
  }

  void _showEmojiRainfall() {
    // Remove existing overlay if any
    _emojiRainfallOverlay?.remove();
    
    // Create new overlay
    _emojiRainfallOverlay = OverlayEntry(
      builder: (context) => _EmojiRainfall(
        emoji: widget.emoji,
        onComplete: () {
          _emojiRainfallOverlay?.remove();
          _emojiRainfallOverlay = null;
        },
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_emojiRainfallOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: widget.child,
    );
  }
}

// Emoji Rainfall Widget
class _EmojiRainfall extends StatefulWidget {
  final String emoji;
  final VoidCallback onComplete;

  const _EmojiRainfall({
    required this.emoji,
    required this.onComplete,
  });

  @override
  State<_EmojiRainfall> createState() => _EmojiRainfallState();
}

class _EmojiRainfallState extends State<_EmojiRainfall> {
  @override
  void initState() {
    super.initState();
    // Auto-remove after 5 seconds (increased from 3)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final random = Random();

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: List.generate(35, (index) { // Increased from 20 to 35
            final leftPosition = random.nextDouble() * screenWidth;
            final duration = 3.5 + random.nextDouble() * 1.5; // 3.5-5 seconds (increased)
            final delay = index * 0.12; // Slightly increased delay
            final rotation = random.nextDouble() * 0.6 - 0.3; // More rotation

            return Positioned(
              left: leftPosition,
              top: -50,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 36), // Increased from 32
              )
                  .animate()
                  .moveY(
                    begin: 0,
                    end: screenHeight + 50,
                    duration: Duration(milliseconds: (duration * 1000).toInt()),
                    delay: Duration(milliseconds: (delay * 1000).toInt()),
                    curve: Curves.easeIn,
                  )
                  .fadeIn(duration: 400.ms) // Increased fade duration
                  .then()
                  .fadeOut(duration: 400.ms, delay: Duration(milliseconds: (duration * 800).toInt()))
                  .rotate(
                    begin: 0,
                    end: rotation,
                    duration: Duration(milliseconds: (duration * 1000).toInt()),
                  )
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.3, 1.3), // More scale variation
                    duration: Duration(milliseconds: (duration * 500).toInt()),
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.3, 1.3),
                    end: const Offset(0.7, 0.7),
                    duration: Duration(milliseconds: (duration * 500).toInt()),
                  ),
            );
          }),
        ),
      ),
    );
  }
}
