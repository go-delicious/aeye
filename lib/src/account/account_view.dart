import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/llm_service.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final _apiKeyController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isApiKeyVisible = false;
  String _selectedMainModel = 'google/gemini-2.0-flash-001';
  String _selectedImageModel = 'google/gemini-2.0-flash-001';
  List<ModelInfo> _allModels = [];
  List<ModelInfo> _filteredModels = [];
  
  static const String _apiKeyPrefKey = 'openrouter_api_key';
  static const String _mainModelPrefKey = 'selected_model';
  static const String _imageModelPrefKey = 'selected_image_model';
  static const String _mainModelSystemMsgPrefKey = 'main_model_system_msg';
  static const String _imageModelSystemMsgPrefKey = 'image_model_system_msg';
  LLMService? _llmService;

  static const String _defaultMainSystemMsg = 
    'You are a helpful AI assistant with expertise in computer vision and image analysis. '
    'Your role is to assist users with their questions and tasks, providing clear, accurate, '
    'and well-structured responses. When appropriate, break down complex explanations into '
    'steps or bullet points for better clarity. Be concise yet thorough, and always aim to '
    'provide practical, actionable information.';

  static const String _defaultImageSystemMsg = 
    'You are a computer vision expert specializing in analyzing images and providing detailed, '
    'accurate descriptions. When analyzing images, focus on key visual elements, spatial relationships, '
    'and relevant details that help answer the user\'s query. If the image contains text, read and '
    'incorporate it into your analysis. Provide clear, structured responses that help users understand '
    'what you see in the image and how it relates to their questions.';

  String _mainModelSystemMsg = '';
  String _imageModelSystemMsg = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _searchController.addListener(_filterModels);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterModels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredModels = _allModels.where((model) {
        return model.id.toLowerCase().contains(query) ||
               model.name.toLowerCase().contains(query) ||
               model.description.toLowerCase().contains(query) ||
               model.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyPrefKey) ?? '';
    
    setState(() {
      _apiKeyController.text = apiKey;
      _selectedMainModel = prefs.getString(_mainModelPrefKey) ?? 'mistralai/mistral-7b-instruct';
      _selectedImageModel = prefs.getString(_imageModelPrefKey) ?? 'google/gemini-pro-vision';
      _mainModelSystemMsg = prefs.getString(_mainModelSystemMsgPrefKey) ?? _defaultMainSystemMsg;
      _imageModelSystemMsg = prefs.getString(_imageModelSystemMsgPrefKey) ?? _defaultImageSystemMsg;
      
      if (apiKey.isNotEmpty) {
        _llmService = LLMService(apiKey: apiKey);
      }
    });
    
    if (_llmService != null) {
      await _fetchModels();
    }
  }

  Future<void> _fetchModels() async {
    if (_llmService == null) return;

    try {
      final models = await _llmService!.getAvailableModels();
      setState(() {
        _allModels = models;
        _filteredModels = models;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch models: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey);
    
    setState(() {
      _llmService = LLMService(apiKey: apiKey);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key saved successfully')),
      );
      await _fetchModels();
    }
  }

  Future<void> _saveMainModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mainModelPrefKey, model);
    setState(() {
      _selectedMainModel = model;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Main model preference saved'),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            right: 20,
            left: 20,
          ),
        ),
      );
    }
  }

  Future<void> _saveImageModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageModelPrefKey, model);
    setState(() {
      _selectedImageModel = model;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image model preference saved'),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            right: 20,
            left: 20,
          ),
        ),
      );
    }
  }

  Future<void> _saveSystemMessage(String message, bool forImageModel) async {
    final prefs = await SharedPreferences.getInstance();
    final key = forImageModel ? _imageModelSystemMsgPrefKey : _mainModelSystemMsgPrefKey;
    await prefs.setString(key, message);
    setState(() {
      if (forImageModel) {
        _imageModelSystemMsg = message;
      } else {
        _mainModelSystemMsg = message;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System message saved')),
      );
    }
  }

  void _editSystemMessage(bool forImageModel) {
    final currentMsg = forImageModel ? _imageModelSystemMsg : _mainModelSystemMsg;
    final defaultMsg = forImageModel ? _defaultImageSystemMsg : _defaultMainSystemMsg;
    final textController = TextEditingController(text: currentMsg);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${forImageModel ? 'Image' : 'Main'} Model System Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter system message...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Default'),
              onPressed: () {
                textController.text = defaultMsg;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _saveSystemMessage(textController.text, forImageModel);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchOpenRouterWebsite() async {
    final Uri url = Uri.parse('https://openrouter.ai/keys');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open OpenRouter website')),
        );
      }
    }
  }

  Future<void> _refreshModels() async {
    try {
      await _llmService!.clearModelsCache();
      await _fetchModels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Models refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh models: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visionModels = _filteredModels.where((m) => m.supportsVision).toList();
    final allModels = _filteredModels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshModels,
            tooltip: 'Refresh models',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'LLM Provider Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'OpenRouter API Key',
              helperText: 'Enter your OpenRouter API key',
              suffixIcon: IconButton(
                icon: Icon(
                  _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isApiKeyVisible = !_isApiKeyVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            obscureText: !_isApiKeyVisible,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _saveApiKey(_apiKeyController.text),
            child: const Text('Save API Key'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Model Selection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Main Model',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ModelDisplay(
                          models: allModels,
                          selectedId: _selectedMainModel,
                          defaultId: 'mistralai/mistral-7b-instruct',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showModelSearch(false),
                        tooltip: 'Change main model',
                      ),
                      IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () => _editSystemMessage(false),
                        tooltip: 'Edit system message',
                      ),
                    ],
                  ),
                  if (_mainModelSystemMsg.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'System Message: $_mainModelSystemMsg',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Image Model (Fallback)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Used when the main model does not support image input',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ModelDisplay(
                          models: visionModels,
                          selectedId: _selectedImageModel,
                          defaultId: 'google/gemini-pro-vision',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showModelSearch(true),
                        tooltip: 'Change image model',
                      ),
                      IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () => _editSystemMessage(true),
                        tooltip: 'Edit system message',
                      ),
                    ],
                  ),
                  if (_imageModelSystemMsg.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'System Message: $_imageModelSystemMsg',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Note: Your settings are stored securely on your device.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _launchOpenRouterWebsite,
            child: const Text('Get an OpenRouter API Key'),
          ),
        ],
      ),
    );
  }

  void _showModelSearch(bool forImageModel) {
    const pageSize = 100;  // Increased page size for better initial load
    ValueNotifier<int> currentPage = ValueNotifier(0);
    final ScrollController scrollController = ScrollController();
    final TextEditingController modalSearchController = TextEditingController();
    List<ModelInfo> modalFilteredModels = [];
    
    // Add scroll listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        // Pre-load next page when near the bottom
        currentPage.value++;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, _) => StatefulBuilder(
          builder: (context, setModalState) {
            // Filter models based on search text
            final searchQuery = modalSearchController.text.toLowerCase();
            modalFilteredModels = _allModels.where((model) {
              if (forImageModel && !model.supportsVision) return false;
              return searchQuery.isEmpty || 
                     model.id.toLowerCase().contains(searchQuery) ||
                     model.name.toLowerCase().contains(searchQuery) ||
                     model.description.toLowerCase().contains(searchQuery) ||
                     model.tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
                     model.capabilities.any((cap) => cap.toLowerCase().contains(searchQuery));
            }).toList();
            
            // Sort models by date using the compareByDate method
            modalFilteredModels.sort((a, b) => a.compareByDate(b));

            return Column(
              children: [
                AppBar(
                  title: Text('Select ${forImageModel ? 'Image' : 'Main'} Model'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: modalSearchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Models',
                          hintText: 'Search by name, description, or capabilities',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setModalState(() {
                            currentPage.value = 0;  // Reset to first page on search
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Showing ${modalFilteredModels.length} models',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (modalFilteredModels.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No models found'),
                    ),
                  )
                else
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: currentPage,
                      builder: (context, page, _) {
                        final endIndex = ((page + 1) * pageSize).clamp(0, modalFilteredModels.length);
                        final displayedModels = modalFilteredModels.sublist(0, endIndex);
                        final hasMore = endIndex < modalFilteredModels.length;

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: displayedModels.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == displayedModels.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final model = displayedModels[index];
                            return ListTile(
                              title: Text(model.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(model.id),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      if (model.supportsVision)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(red: 0, green: 255, blue: 0, alpha: 26),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.image, size: 12, color: Colors.green),
                                              SizedBox(width: 4),
                                              Text(
                                                'Vision',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ...model.capabilities.map((cap) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cap,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: (forImageModel 
                                  ? model.id == _selectedImageModel 
                                  : model.id == _selectedMainModel)
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                if (forImageModel) {
                                  _saveImageModel(model.id);
                                } else {
                                  _saveMainModel(model.id);
                                }
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModelDisplay extends StatelessWidget {
  final List<ModelInfo> models;
  final String selectedId;
  final String defaultId;

  const _ModelDisplay({
    required this.models,
    required this.selectedId,
    required this.defaultId,
  });

  @override
  Widget build(BuildContext context) {
    final model = models.firstWhere(
      (m) => m.id == selectedId,
      orElse: () => models.firstWhere(
        (m) => m.id == defaultId,
        orElse: () => ModelInfo(
          id: defaultId,
          name: defaultId.split('/').last,
          description: '',
          contextLength: 0,
          promptPrice: 0,
          completionPrice: 0,
          tags: const [],
          capabilities: const [],
          architecture: const {'modality': 'text->text'},
          created: 0,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.name,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        Text(
          model.id,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (model.supportsVision)
          const Row(
            children: [
              Icon(Icons.image, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(
                'Vision capable',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
      ],
    );
  }
} 