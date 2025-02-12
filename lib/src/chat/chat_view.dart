import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/llm_service.dart';
import 'chat_history.dart' show ChatHistoryView;
import 'chat_models.dart';
import 'package:flutter/services.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final LLMService _llmService = LLMService();
  late final List<Conversation> _conversations;
  late Conversation _currentConversation;
  bool _isLoading = false;
  String? _pendingImageData;
  String? _pendingImageMime;
  static const String _conversationsKey = 'chat_conversations';

  @override
  void initState() {
    super.initState();
    _conversations = <Conversation>[];
    _currentConversation = _createNewConversation();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Conversation _createNewConversation() {
    return Conversation(
      id: DateTime.now().toIso8601String(),
      messages: [],
      lastUpdated: DateTime.now(),
    );
  }

  void _startNewConversation() {
    setState(() {
      _currentConversation = _createNewConversation();
    });
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);
    if (conversationsJson != null) {
      final List<dynamic> decoded = jsonDecode(conversationsJson);
      setState(() {
        _conversations.clear();
        _conversations.addAll(
          decoded
              .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated)),
        );
      });
    }
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = jsonEncode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_conversationsKey, conversationsJson);
  }

  void _showHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatHistoryView(
          conversations: _conversations,
          onConversationSelected: (conversation) {
            setState(() {
              _currentConversation = conversation;
            });
            Navigator.of(context).pop();
          },
          onConversationDeleted: (id) {
            setState(() {
              _conversations.removeWhere((c) => c.id == id);
            });
            _saveConversations();
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _pendingImageData == null) return;

    final attachments = _pendingImageData != null
        ? [MessageAttachment(
            type: 'image',
            data: _pendingImageData!,
            mimeType: _pendingImageMime,
          )]
        : <MessageAttachment>[];

    final userMessage = Message(
      content: MessageContent(
        text: message,
        attachments: attachments,
      ),
      isUser: true,
    );

    setState(() {
      _currentConversation.messages.insert(0, userMessage);
      _isLoading = true;
      _messageController.clear();
    });

    try {
      // Create a placeholder message for streaming
      final assistantMessage = Message(
        content: MessageContent(text: ''),
        isUser: false,
        metadata: null,
      );

      // Create a status message that will be updated during the process
      final statusMessage = Message(
        content: MessageContent(text: ''),
        isUser: false,
        metadata: null,
      );

      setState(() {
        if (_pendingImageData != null) {
          _currentConversation.messages.insert(0, statusMessage);
        }
        _currentConversation.messages.insert(0, assistantMessage);
        if (_conversations.isEmpty || _conversations.first.id != _currentConversation.id) {
          _conversations.insert(0, _currentConversation);
        }
      });

      String fullResponse = '';
      await for (final chunk in _llmService.streamMessage(
        message,
        base64Image: _pendingImageData,
        mimeType: _pendingImageMime,
      )) {
        if (!mounted) break;
        
        setState(() {
          fullResponse += chunk;
          assistantMessage.content = MessageContent(text: fullResponse);
        });
      }

      // Update the message with final metadata
      final response = await _llmService.sendMessage(
        message,
        base64Image: _pendingImageData,
        mimeType: _pendingImageMime,
      );
      if (!mounted) return;

      setState(() {
        assistantMessage.content = MessageContent(text: response.content);
        assistantMessage.metadata = response;

        if (_pendingImageData != null) {
          if (response.usedFallbackModel) {
            statusMessage.content = MessageContent(
              text: '🔄 Image processed using fallback model: ${response.model}\n\n'
                   'Click to see the image description that was sent to the main model.',
            );
            statusMessage.metadata = response;
          } else {
            // Remove the status message if no fallback was used
            _currentConversation.messages.remove(statusMessage);
          }
        }

        _pendingImageData = null;
        _pendingImageMime = null;
      });
      
      await _saveConversations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 10 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large. Please choose a smaller image.')),
          );
          return;
        }
        
        setState(() {
          _pendingImageData = base64Encode(bytes);
          _pendingImageMime = image.mimeType ?? 'image/jpeg';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  void _showMessageDetails(Message message) {
    final metadata = message.metadata;
    if (metadata == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Response Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _DetailRow('Model', metadata.model),
              if (metadata.usedFallbackModel) ...[
                const _DetailRow(
                  'Processing',
                  'Used fallback model for image analysis',
                  color: Colors.orange,
                ),
                if (metadata.imageDescription != null)
                  _DetailRow(
                    'Image Description',
                    metadata.imageDescription!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
              _DetailRow(
                'Tokens',
                'Prompt: ${metadata.promptTokens}, Completion: ${metadata.completionTokens}',
              ),
              _DetailRow(
                'Cost',
                '\$${metadata.cost.toStringAsFixed(6)}',
              ),
              _DetailRow(
                'Time',
                message.timestamp.toLocal().toString(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Message'),
                onTap: () {
                  Navigator.pop(context);
                  // Copy the message text to clipboard
                  final text = message.content.text;
                  if (text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied to clipboard')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry Response'),
                onTap: () {
                  Navigator.pop(context);
                  // Find the index of this message
                  final index = _currentConversation.messages.indexOf(message);
                  if (index != -1) {
                    _retryResponse(index);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(Message message, int index) {
    if (!message.isUser) {
      _showMessageDetails(message);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Message Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rewrite Prompt'),
              onTap: () {
                Navigator.pop(context);
                _rewritePrompt(message, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _rewritePrompt(Message originalMessage, int index) {
    // Pre-fill the text field with the original message
    _messageController.text = originalMessage.content.text;
    
    // If there was an image, restore it
    if (originalMessage.content.attachments.isNotEmpty) {
      final imageAttachment = originalMessage.content.attachments.first;
      setState(() {
        _pendingImageData = imageAttachment.data;
        _pendingImageMime = imageAttachment.mimeType;
      });
    }

    // Create a branch by inserting new messages after the selected message
    setState(() {
      _currentConversation.messages.insert(index, Message(
        content: MessageContent(
          text: '--- Alternative prompt ---',
        ),
        isUser: true,
      ));
    });
  }

  Future<void> _retryResponse(int index) async {
    // Find the user message that triggered this response
    final userMessage = _currentConversation.messages[index + 1];
    
    // Create a branch marker
    setState(() {
      _currentConversation.messages.insert(index, Message(
        content: MessageContent(
          text: '--- Alternative response ---',
        ),
        isUser: true,
      ));
    });

    // Send the message again
    try {
      final assistantMessage = Message(
        content: MessageContent(text: ''),
        isUser: false,
        metadata: null,
      );

      setState(() {
        _currentConversation.messages.insert(index, assistantMessage);
        _isLoading = true;
      });

      String fullResponse = '';
      await for (final chunk in _llmService.streamMessage(
        userMessage.content.text,
        base64Image: userMessage.content.attachments.isNotEmpty 
            ? userMessage.content.attachments.first.data 
            : null,
        mimeType: userMessage.content.attachments.isNotEmpty 
            ? userMessage.content.attachments.first.mimeType 
            : null,
      )) {
        if (!mounted) break;
        
        setState(() {
          fullResponse += chunk;
          assistantMessage.content = MessageContent(text: fullResponse);
        });
      }

      final response = await _llmService.sendMessage(
        userMessage.content.text,
        base64Image: userMessage.content.attachments.isNotEmpty 
            ? userMessage.content.attachments.first.data 
            : null,
        mimeType: userMessage.content.attachments.isNotEmpty 
            ? userMessage.content.attachments.first.mimeType 
            : null,
      );
      if (!mounted) return;

      setState(() {
        assistantMessage.content = MessageContent(text: response.content);
        assistantMessage.metadata = response;
      });
      
      await _saveConversations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        leading: IconButton(
          icon: const Icon(Icons.history),
          onPressed: _showHistory,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: _currentConversation.messages.length,
              itemBuilder: (context, index) {
                final message = _currentConversation.messages[index];
                return _MessageBubble(
                  message: message,
                  onLongPress: () => _showMessageOptions(message, index),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_pendingImageData != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(
                        base64Decode(_pendingImageData!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _pendingImageData = null;
                        _pendingImageMime = null;
                      }),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                  tooltip: 'Add image',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    this.onLongPress,
  });

  void _showFullScreenImage(BuildContext context, MessageAttachment attachment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(attachment: attachment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final backgroundColor = isUser 
        ? colorScheme.primary 
        : colorScheme.surface.withAlpha(255);
    final textColor = isUser 
        ? colorScheme.onPrimary 
        : colorScheme.onSurface;
    final borderColor = colorScheme.primary.withAlpha(100);

    final hasImage = message.content.attachments.any((a) => a.type == 'image');
    final hasMetadata = !isUser && message.metadata != null;
    final isStatusMessage = !isUser && message.metadata?.usedFallbackModel == true && 
                          message.content.text.startsWith('🔄');

    return GestureDetector(
      onLongPress: !isStatusMessage ? onLongPress : null,
      onTap: isStatusMessage ? onLongPress : null,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (hasImage) 
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, message.content.attachments.first),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Hero(
                    tag: 'image_${message.timestamp.millisecondsSinceEpoch}',
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: _buildImagePreview(message.content.attachments.first),
                    ),
                  ),
                ),
              ),
            ),
          if (message.content.text.isNotEmpty)
            Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isStatusMessage 
                      ? colorScheme.tertiaryContainer 
                      : backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: !isUser ? Border.all(
                    color: borderColor,
                    width: 1.5,
                  ) : null,
                  boxShadow: !isUser ? [
                    BoxShadow(
                      color: borderColor.withAlpha(50),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUser || isStatusMessage)
                      Text(
                        message.content.text,
                        style: TextStyle(
                          color: isStatusMessage 
                              ? colorScheme.onTertiaryContainer
                              : textColor,
                        ),
                      )
                    else
                      MarkdownBody(
                        data: message.content.text,
                        shrinkWrap: true,
                        selectable: false,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: textColor),
                          h1: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                          h2: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                          h3: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                          h4: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          h5: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                          h6: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                          em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                          strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          code: TextStyle(
                            color: textColor,
                            backgroundColor: isUser 
                                ? colorScheme.primary.withAlpha(100)
                                : colorScheme.surfaceContainerHighest,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: isUser 
                                ? colorScheme.primary.withAlpha(100)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outline.withAlpha(30),
                              width: 1,
                            ),
                          ),
                          blockquote: TextStyle(
                            color: textColor.withAlpha(200),
                            fontStyle: FontStyle.italic,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: colorScheme.outline.withAlpha(50),
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (hasMetadata && !isStatusMessage) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Long press for details',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withAlpha(179),
                        ),
                      ),
                    ],
                    if (isStatusMessage) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onTertiaryContainer.withAlpha(179),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(MessageAttachment attachment) {
    try {
      final imageData = base64Decode(attachment.data);
      return Image.memory(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Icon(Icons.broken_image),
      );
    }
  }
}

class _FullScreenImageView extends StatelessWidget {
  final MessageAttachment attachment;

  const _FullScreenImageView({
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: 'image_${attachment.hashCode}',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              base64Decode(attachment.data),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 48,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final TextStyle? style;

  const _DetailRow(
    this.label,
    this.value,
    {
      this.color,
      this.style,
    }
  );

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? const TextStyle();
    final finalStyle = color != null 
        ? textStyle.copyWith(color: color)
        : textStyle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: finalStyle,
            ),
          ),
        ],
      ),
    );
  }
} 