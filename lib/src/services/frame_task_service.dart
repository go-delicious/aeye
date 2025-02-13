import 'dart:async';
import 'dart:typed_data';
import '../services/bluetooth_service.dart';
import '../services/llm_service.dart';

class FrameTaskService {
  final BluetoothService _bluetoothService;
  final LLMService _llmService;
  StreamSubscription? _tapSubscription;

  FrameTaskService({
    required BluetoothService bluetoothService,
    required LLMService llmService,
  })  : _bluetoothService = bluetoothService,
        _llmService = llmService;

  Future<void> startTapToAnalyze() async {
    // Cancel any existing subscription
    await _tapSubscription?.cancel();

    // Start listening for tap events
    _tapSubscription = _bluetoothService.onTap.listen((event) async {
      try {
        // Show processing message
        await _bluetoothService.displayText('Processing...');

        // Take photo
        final imageBytes = await _bluetoothService.takePhoto();
        if (imageBytes == null) {
          await _bluetoothService.displayText('Failed to capture image');
          return;
        }

        // Show analyzing message
        await _bluetoothService.displayText('Analyzing image...');

        // Analyze image with AI
        final result = await _analyzeImage(imageBytes);
        
        // Display result
        await _displayAnalysisResult(result);
      } catch (e) {
        await _bluetoothService.displayText('Error: $e');
      }
    });
  }

  Future<void> stopTapToAnalyze() async {
    await _tapSubscription?.cancel();
    _tapSubscription = null;
  }

  Future<String> _analyzeImage(Uint8List imageBytes) async {
    const prompt = 'Please describe what you see in this image concisely in 2-3 sentences, focusing on the main subject and any notable details.';
    
    try {
      return await _llmService.analyzeImage(
        imageBytes: imageBytes,
        prompt: prompt,
      );
    } catch (e) {
      throw 'Failed to analyze image: $e';
    }
  }

  Future<void> _displayAnalysisResult(String result) async {
    try {
      // First display the full result briefly
      await _bluetoothService.displayText(result);
      await Future.delayed(const Duration(seconds: 3));
      
      // Then scroll it for better readability
      await _bluetoothService.scrollText(result);
    } catch (e) {
      throw 'Failed to display result: $e';
    }
  }
} 