class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final bool isError;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
  });

  AiChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
    bool? isError,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }

  factory AiChatMessage.user(String message) {
    return AiChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory AiChatMessage.ai(String message) {
    return AiChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  factory AiChatMessage.loading() {
    return AiChatMessage(
      id: 'loading-${DateTime.now().microsecondsSinceEpoch}',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }
}

class AiAskResponse {
  final bool success;
  final String answer;

  const AiAskResponse({
    required this.success,
    required this.answer,
  });

  factory AiAskResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return AiAskResponse(
      success: json['success'] ?? true,
      answer: data['answer'] ?? json['answer'] ?? 'No answer received.',
    );
  }
}
