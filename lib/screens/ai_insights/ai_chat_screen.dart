import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'models/ai_chat_message.dart';
import 'services/ai_insights_repository.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/suggested_question_chip.dart';

class AiChatScreen extends StatefulWidget {
  final AiInsightsRepository repository;
  final String? initialQuestion;

  const AiChatScreen({
    super.key,
    required this.repository,
    this.initialQuestion,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isSending = false;

  final List<String> _quickSuggestions = [
    'Where am I spending most?',
    'How can I save money this month?',
    'What is my highest expense category?',
    'Am I overspending?',
    'Give me a summary of my spending.',
  ];

  @override
  void initState() {
    super.initState();
    _initChatHistory();
  }

  void _initChatHistory() {
    // Welcome message from financial assistant
    _messages.add(
      AiChatMessage.ai(
        'Hello Aarav! I am your Pennywise AI money coach. Ask me anything about your March expenses, category budgets, or saving strategies.',
      ),
    );

    if (widget.initialQuestion != null && widget.initialQuestion!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialQuestion!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? query]) async {
    final text = (query ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();

    final userMsg = AiChatMessage.user(text);
    final loadingMsg = AiChatMessage.loading();

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final answer = await widget.repository.askQuestion(text);
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == loadingMsg.id);
          _messages.add(AiChatMessage.ai(answer));
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == loadingMsg.id);
          _messages.add(
            AiChatMessage(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              text: 'Unable to reach financial AI service. Please check your network.',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pennywise AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online · Money Coach',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              setState(() {
                _messages.clear();
                _initChatHistory();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Suggested Prompts Horizontal Bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _quickSuggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: SuggestedQuestionChip(
                        label: _quickSuggestions[index],
                        onTap: () => _handleSendMessage(_quickSuggestions[index]),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Message Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return ChatMessageBubble(
                    message: msg,
                    onRetry: () {
                      final lastUserMsg = _messages.lastWhere((m) => m.isUser, orElse: () => msg);
                      _handleSendMessage(lastUserMsg.text);
                    },
                  );
                },
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: const Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _handleSendMessage(),
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ask about budget, spending...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMutedLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isSending ? null : () => _handleSendMessage(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _isSending ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
