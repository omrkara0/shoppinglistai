import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> initialize() async {
    _isAvailable = await _speech.initialize();
  }

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!_isAvailable) return;

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
  }
}
