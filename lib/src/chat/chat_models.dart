import '../services/llm_service.dart';

enum MessageType {
  text,
  image,
}

class MessageContent {
  final String text;
  final List<MessageAttachment> attachments;

  MessageContent({
    required this.text,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      text: json['text'] as String,
      attachments: (json['attachments'] as List?)
          ?.map((a) => MessageAttachment.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class MessageAttachment {
  final String type;
  final String data;
  final String? mimeType;

  MessageAttachment({
    required this.type,
    required this.data,
    this.mimeType,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'mimeType': mimeType,
  };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      type: json['type'] as String,
      data: json['data'] as String,
      mimeType: json['mimeType'] as String?,
    );
  }
}

class Message {
  MessageContent content;
  final bool isUser;
  final DateTime timestamp;
  LLMResponse? metadata;

  Message({
    required this.content,
    required this.isUser,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'content': content.toJson(),
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata != null ? {
      'model': metadata!.model,
      'promptTokens': metadata!.promptTokens,
      'completionTokens': metadata!.completionTokens,
      'cost': metadata!.cost,
    } : null,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    final metadataJson = json['metadata'] as Map<String, dynamic>?;
    return Message(
      content: MessageContent.fromJson(json['content'] as Map<String, dynamic>),
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: metadataJson != null ? LLMResponse(
        content: json['content']['text'] as String,
        model: metadataJson['model'] as String,
        promptTokens: metadataJson['promptTokens'] as int,
        completionTokens: metadataJson['completionTokens'] as int,
        cost: (metadataJson['cost'] as num).toDouble(),
      ) : null,
    );
  }
}

class Conversation {
  final String id;
  final List<Message> messages;
  final DateTime lastUpdated;

  Conversation({
    required this.id,
    required this.messages,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'messages': messages.map((m) => m.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  String get preview {
    if (messages.isEmpty) return 'Empty conversation';
    return messages.first.content.text;
  }
} 