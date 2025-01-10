import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglistai/constants.dart';

class SpeechFAB extends StatelessWidget {
  final bool isAvailable;
  final bool isListening;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final Animation<double> animation;

  const SpeechFAB({
    super.key,
    required this.isAvailable,
    required this.isListening,
    required this.onStart,
    required this.onStop,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isAvailable ? (isListening ? onStop : onStart) : null,
      backgroundColor: isListening ? AppColors.darkGrey : AppColors.accent,
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          isListening ? 'Dinlemeyi Durdur' : 'Sesli Komut',
          key: ValueKey<bool>(isListening),
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w500,
            color: AppColors.lightText,
          ),
        ),
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          key: ValueKey<bool>(isListening),
          color: AppColors.lightText,
        ),
      ),
      elevation: 4,
    );
  }
}
