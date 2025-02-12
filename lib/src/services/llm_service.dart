import 'dart:convert';
import 'package:http/http.dart' as http;
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
    final choices = json['choices'] as List<dynamic>;
    final firstChoice = choices.isNotEmpty ? choices[0] as Map<String, dynamic> : {};
    final message = firstChoice['message'] as Map<String, dynamic>? ?? {};

    return LLMResponse(
      content: message['content'] as String? ?? '',
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
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKeyPrefKey = 'openrouter_api_key';
  static const String _modelPrefKey = 'selected_model';
  static const String _modelsCacheKey = 'models_cache';
  static const Duration _modelsCacheExpiry = Duration(minutes: 2);
  static const String _fallbackVisionModel = 'google/gemini-2.0-pro-exp-02-05:free';

  ModelInfo? _selectedModelInfo;
  final Dio _dio = Dio();
  String? _apiKey;

  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPrefKey);
    return _apiKey;
  }

  Future<String> _getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelPrefKey) ?? 'google/gemini-2.0-pro-exp-02-05:free';
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
    await prefs.setString(_modelsCacheKey, jsonEncode(cache));
  }

  Future<List<ModelInfo>?> _getCachedModels() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString(_modelsCacheKey);
    if (cacheJson == null) return null;

    try {
      final cache = jsonDecode(cacheJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cache['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > _modelsCacheExpiry) {
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

      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found. Please set your OpenRouter API key in the Account settings.');
      }

      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://github.com/yourusername/aeye',
          },
        ),
      );

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

  Future<ModelInfo?> _getSelectedModelInfo() async {
    if (_selectedModelInfo != null) return _selectedModelInfo;
    
    final modelId = await _getSelectedModel();
    final models = await getAvailableModels();
    _selectedModelInfo = models.firstWhere(
      (m) => m.id == modelId,
      orElse: () => models.first,
    );
    return _selectedModelInfo;
  }

  Future<LLMResponse> sendMessage(String message, {
    bool stream = false,
    String? base64Image,
    String? mimeType,
  }) async {
    if (stream) {
      throw Exception('Use streamMessage for streaming responses');
    }

    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key not found. Please set your OpenRouter API key in the Account settings.');
    }

    final selectedModel = await _getSelectedModelInfo();
    if (selectedModel == null) {
      throw Exception('No model selected');
    }

    final List<Map<String, dynamic>> messages = [];
    String? imageDescription;
    bool usedFallback = false;
    
    if (base64Image != null) {
      if (!selectedModel.supportsVision) {
        usedFallback = true;
        // Use fallback vision model to get image description
        imageDescription = await _getImageDescription(
          message,
          base64Image,
          mimeType ?? 'image/jpeg',
          apiKey,
        );
        
        // Add the image description to the message
        messages.add({
          'role': 'system',
          'content': 'The following is a description of an image that was provided: $imageDescription',
        });
        
        // Add the user's message
        if (message.isNotEmpty) {
          messages.add({
            'role': 'user',
            'content': message,
          });
        }
      } else {
        // Model supports vision, add image directly
        messages.add({
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image'
              }
            }
          ]
        });
        
        if (message.isNotEmpty) {
          messages.add({
            'role': 'user',
            'content': message,
          });
        }
      }
    } else if (message.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': message,
      });
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/yourusername/aeye',
      },
      body: jsonEncode({
        'model': selectedModel.id,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Add fallback information to the response
      jsonResponse['used_fallback_model'] = usedFallback;
      jsonResponse['image_description'] = imageDescription;
      return LLMResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<String> _getImageDescription(
    String userPrompt,
    String base64Image,
    String mimeType,
    String apiKey,
  ) async {
    final prompt = userPrompt.isEmpty 
        ? 'Please provide a detailed description of this image.'
        : 'Please describe this image in detail, focusing on aspects relevant to the following question or request: $userPrompt';

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/yourusername/aeye',
      },
      body: jsonEncode({
        'model': _fallbackVisionModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image'
                }
              },
              {
                'type': 'text',
                'text': prompt,
              }
            ]
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final description = LLMResponse.fromJson(jsonResponse).content;
      return description;
    } else {
      throw Exception('Failed to get image description: ${response.body}');
    }
  }

  Stream<String> streamMessage(String message, {
    String? base64Image,
    String? mimeType,
  }) async* {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key not found. Please set your OpenRouter API key in the Account settings.');
    }

    final selectedModel = await _getSelectedModelInfo();
    if (selectedModel == null) {
      throw Exception('No model selected');
    }

    final List<Map<String, dynamic>> messages = [];
    String? imageDescription;
    
    if (base64Image != null) {
      if (!selectedModel.supportsVision) {
        // Get image description first
        imageDescription = await _getImageDescription(
          message,
          base64Image,
          mimeType ?? 'image/jpeg',
          apiKey,
        );
        
        messages.add({
          'role': 'system',
          'content': 'The following is a description of an image that was provided: $imageDescription',
        });
        
        if (message.isNotEmpty) {
          messages.add({
            'role': 'user',
            'content': message,
          });
        }
      } else {
        messages.add({
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image'
              }
            }
          ]
        });
        
        if (message.isNotEmpty) {
          messages.add({
            'role': 'user',
            'content': message,
          });
        }
      }
    } else if (message.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': message,
      });
    }

    final client = http.Client();
    try {
      final response = await client.send(
        http.Request(
          'POST',
          Uri.parse('$_baseUrl/chat/completions'),
        )
          ..headers.addAll({
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://github.com/yourusername/aeye',
          })
          ..body = jsonEncode({
            'model': selectedModel.id,
            'messages': messages,
            'stream': true,
          }),
      );

      if (response.statusCode != 200) {
        final error = await response.stream.bytesToString();
        throw Exception('Failed to stream message: $error');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final events = chunk.split('\n\n');
        for (final event in events) {
          if (event.trim().isEmpty || event.trim() == 'data: [DONE]') continue;
          
          if (event.startsWith('data: ')) {
            try {
              final jsonData = jsonDecode(event.substring(6));
              final content = jsonData['choices']?[0]?['delta']?['content'] as String?;
              if (content != null) {
                yield content;
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> clearModelsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modelsCacheKey);
    
  }
} 
