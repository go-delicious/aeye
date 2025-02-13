import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class ModelInfo {
  final String id;
  final String name;
  final String description;
  final double contextLength;
  final double promptPrice;
  final double completionPrice;
  final List<String> tags;
  final List<String> capabilities;
  final Map<String, dynamic> architecture;
  final int created;

  ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.contextLength,
    required this.promptPrice,
    required this.completionPrice,
    required this.tags,
    required this.capabilities,
    required this.architecture,
    required this.created,
  });

  bool get supportsVision {
    // Check architecture modality first (most reliable)
    final modality = architecture['modality']?.toString().toLowerCase() ?? '';
    if (modality.contains('image') || modality.contains('vision')) {
      return true;
    }

    // Check capabilities
    if (capabilities.any((c) => 
      c.toLowerCase().contains('vision') ||
      c.toLowerCase().contains('multimodal') ||
      c.toLowerCase().contains('image'))) {
      return true;
    }

    // Check tags
    if (tags.any((t) => 
      t.toLowerCase().contains('vision') ||
      t.toLowerCase().contains('multimodal') ||
      t.toLowerCase().contains('image-to-text'))) {
      return true;
    }

    // Check description as a last resort
    final desc = description.toLowerCase();
    return desc.contains('vision capabilities') ||
           desc.contains('visual input') ||
           desc.contains('multimodal') ||
           desc.contains('image input') ||
           desc.contains('process images') ||
           desc.contains('analyze images');
  }

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final pricing = json['pricing'] as Map<String, dynamic>? ?? {};
    final capabilities = <String>[];
    final tags = <String>[];
    
    // Extract capabilities from architecture
    final architecture = json['architecture'] as Map<String, dynamic>? ?? {};
    final modality = architecture['modality']?.toString() ?? '';
    if (modality.isNotEmpty) {
      capabilities.add(modality);
    }

    // Add any additional capabilities from the model's features
    final features = json['features'] as Map<String, dynamic>? ?? {};
    capabilities.addAll(features.keys);

    // Extract capabilities from top_provider
    final topProvider = json['top_provider'] as Map<String, dynamic>? ?? {};
    if (topProvider.containsKey('is_moderated')) {
      capabilities.add('moderated');
    }

    return ModelInfo(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String? ?? '',
      contextLength: parseDouble(json['context_length']),
      promptPrice: parseDouble(pricing['prompt']),
      completionPrice: parseDouble(pricing['completion']),
      tags: tags,
      capabilities: capabilities,
      architecture: architecture,
      created: json['created'] as int? ?? 0,
    );
  }

  // Simple comparison method using created timestamp
  int compareByDate(ModelInfo other) {
    return other.created.compareTo(created); // Reverse order for newest first
  }
}

class LLMResponse {
  final String content;
  final String model;
  final int promptTokens;
  final int completionTokens;
  final double cost;
  final bool usedFallbackModel;
  final String? imageDescription;

  LLMResponse({
    required this.content,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.cost,
    this.usedFallbackModel = false,
    this.imageDescription,
  });

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper function to safely convert to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final usage = json['usage'] as Map<String, dynamic>? ?? {};
    final model = json['model'] as String? ?? 'unknown';
    
    // Add type checking for choices
    final choices = json['choices'];
    if (choices == null) {
      throw FormatException('Invalid JSON: required "choices" field is missing in $json');
    }
    if (choices is! List) {
      throw FormatException('Invalid JSON: "choices" must be a List but was ${choices.runtimeType} in $json');
    }
    if (choices.isEmpty) {
      throw FormatException('Invalid JSON: "choices" list is empty in $json');
    }

    final firstChoice = choices[0];
    if (firstChoice is! Map<String, dynamic>) {
      throw FormatException('Invalid JSON: first choice must be a Map but was ${firstChoice.runtimeType} in $json');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw FormatException('Invalid JSON: "message" must be a Map but was ${message?.runtimeType} in $json');
    }

    final content = message['content'];
    if (content is! String) {
      throw FormatException('Invalid JSON: "content" must be a String but was ${content?.runtimeType} in $json');
    }

    return LLMResponse(
      content: content,
      model: model,
      promptTokens: parseInt(usage['prompt_tokens']),
      completionTokens: parseInt(usage['completion_tokens']),
      cost: parseDouble(usage['cost_usd']),
      usedFallbackModel: json['used_fallback_model'] as bool? ?? false,
      imageDescription: json['image_description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'content': content,
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
    'cost': cost,
    'used_fallback_model': usedFallbackModel,
    'image_description': imageDescription,
  };
}

class LLMService {
  final Dio _dio;
  static const String _logsPrefKey = 'llm_service_logs';
  static const int _maxLogs = 100;  // Keep last 100 logs

  LLMService({
    required String apiKey,
    String baseUrl = 'https://openrouter.ai/api/v1',
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'HTTP-Referer': 'https://github.com/go-delicious/aeye',
            'X-Title': 'AEye App',
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  Future<void> _addLog(String message, {bool isError = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getLogs();
    
    logs.insert(0, {
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      'isError': isError,
    });

    // Keep only the last _maxLogs entries
    if (logs.length > _maxLogs) {
      logs.removeRange(_maxLogs, logs.length);
    }

    await prefs.setString(_logsPrefKey, jsonEncode(logs));
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_logsPrefKey);
    if (logsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(logsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsPrefKey);
  }

  Future<void> _cacheModels(List<ModelInfo> models) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = {
      'timestamp': DateTime.now().toIso8601String(),
      'models': models.map((m) => {
        'id': m.id,
        'name': m.name,
        'description': m.description,
        'context_length': m.contextLength,
        'pricing': {
          'prompt': m.promptPrice,
          'completion': m.completionPrice,
        },
        'tags': m.tags,
        'capabilities': m.capabilities,
        'architecture': m.architecture,
      }).toList(),
    };
    await prefs.setString('models_cache', jsonEncode(cache));
  }

  Future<List<ModelInfo>?> _getCachedModels() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString('models_cache');
    if (cacheJson == null) return null;

    try {
      final cache = jsonDecode(cacheJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cache['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > const Duration(minutes: 2)) {
        return null;  // Cache expired
      }

      return (cache['models'] as List)
          .map((m) => ModelInfo.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;  // Invalid cache
    }
  }

  Future<List<ModelInfo>> getAvailableModels() async {
    try {
      // Try to get models from cache first
      final cachedModels = await _getCachedModels();
      if (cachedModels != null) {
        return cachedModels;
      }

      final response = await _dio.get('/models');

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final rawModels = data['data'] as List;
          final modelList = rawModels
              .map((model) => ModelInfo.fromJson(model))
              .toList();

          // Sort models by date
          modelList.sort((a, b) => a.compareByDate(b));

          // Cache the models for future use
          await _cacheModels(modelList);
          
          return modelList;
        }
      }

      throw Exception('Failed to parse models from API response. Status: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_model') ?? 'google/gemini-2.0-flash-001';
  }

  Future<String> _getSelectedImageModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_image_model') ?? 'google/gemini-2.0-flash-001';
  }

  Future<LLMResponse> sendMessage(String message, {
    bool stream = false,
    String? base64Image,
    String? mimeType,
  }) async {
    if (stream) {
      throw Exception('Use streamChat for streaming responses');
    }

    final model = await (base64Image != null ? _getSelectedImageModel() : _getSelectedModel());
    await _addLog('Sending message to model: $model${base64Image != null ? " (with image)" : ""}');

    final messageContent = base64Image != null
        ? [
            {'type': 'text', 'text': message},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:${mimeType ?? "image/jpeg"};base64,$base64Image',
              },
            },
          ]
        : message;

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': messageContent,
            },
          ],
          'max_tokens': 150,
          'provider': {
            'data_collection': 'deny',
            'require_parameters': true,
            'allow_fallbacks': false,
          },
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        await _addLog('Message sent successfully');
        return LLMResponse.fromJson(jsonResponse);
      } else {
        final error = 'Failed to send message: ${response.statusCode}';
        await _addLog(error, isError: true);
        throw Exception(error);
      }
    } on DioException catch (e) {
      String errorMessage;
      if (e.response?.statusCode == 429) {
        errorMessage = 'Rate limit exceeded. Please wait a moment before trying again.';
      } else {
        errorMessage = 'API Error: ${e.response?.data?['error']?['message'] ?? e.message}';
      }
      await _addLog(errorMessage, isError: true);
      throw Exception(errorMessage);
    }
  }

  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final model = await _getSelectedImageModel();
      await _addLog('Analyzing image with model: $model');

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 150,
          'provider': {
            'data_collection': 'deny',
            'require_parameters': true,
            'allow_fallbacks': false,
          },
        },
      );

      if (response.statusCode == 200) {
        if (response.data == null || !response.data.containsKey('choices')) {
          const error = 'Invalid API response: missing choices field';
          await _addLog(error, isError: true);
          throw error;
        }
        final choices = response.data['choices'] as List;
        if (choices.isEmpty) {
          const error = 'Invalid API response: empty choices list';
          await _addLog(error, isError: true);
          throw error;
        }
        final content = choices[0]['message']['content'] as String;
        await _addLog('Image analysis completed successfully');
        return content.trim();
      } else {
        final error = 'Failed to analyze image: ${response.statusCode}';
        await _addLog(error, isError: true);
        throw error;
      }
    } on DioException catch (e) {
      String errorMessage;
      if (e.response?.statusCode == 429) {
        errorMessage = 'Rate limit exceeded. Please wait a moment before trying again.';
      } else {
        errorMessage = 'API Error: ${e.response?.data?['error']?['message'] ?? e.message}';
      }
      await _addLog(errorMessage, isError: true);
      throw errorMessage;
    } catch (e) {
      final error = 'Failed to analyze image: $e';
      await _addLog(error, isError: true);
      throw error;
    }
  }

  Stream<String> streamChat({
    required String message,
    String? base64Image,
    String? mimeType,
  }) async* {
    try {
      final model = await (base64Image != null ? _getSelectedImageModel() : _getSelectedModel());

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': base64Image != null ? [
                {'type': 'text', 'text': message},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:${mimeType ?? "image/jpeg"};base64,$base64Image',
                  },
                },
              ] : message,
            },
          ],
          'stream': true,
          'provider': {
            'data_collection': 'deny',
            'require_parameters': true,
            'allow_fallbacks': false,
          },
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n').where((line) => line.isNotEmpty);
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;
            
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'] as String?;
              if (content != null) {
                yield content;
              }
            } catch (e) {
              // Skip malformed JSON
              continue;
            }
          }
        }
      }
    } catch (e) {
      throw 'Failed to stream chat: $e';
    }
  }

  Future<void> clearModelsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('models_cache');
  }
} 
