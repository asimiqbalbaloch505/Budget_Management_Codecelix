import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'models/ai_insight_model.dart';
import 'services/ai_insights_repository.dart';
import 'widgets/ai_summary_card.dart';
import 'widgets/top_category_card.dart';
import 'widgets/trend_alert_card.dart';
import 'widgets/saving_suggestion_card.dart';
import 'widgets/anomaly_card.dart';
import 'widgets/suggested_question_chip.dart';
import 'ai_chat_screen.dart';

class AiInsightsScreen extends StatefulWidget {
  final AiInsightsRepository? repository;
  final VoidCallback? onNavigateToBudget;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const AiInsightsScreen({
    super.key,
    this.repository,
    this.onNavigateToBudget,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  late final AiInsightsRepository _aiRepo;
  final TextEditingController _questionController = TextEditingController();

  AiInsightsData? _insightsData;
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _suggestedQuestions = [
    'How can I save more?',
    'Compare with February',
    'Summarize my month',
    'Where am I spending most?',
    'Am I overspending?',
  ];

  @override
  void initState() {
    super.initState();
    _aiRepo = widget.repository ?? MockAiInsightsRepository();
    _loadInsights();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _aiRepo.getInsights();
      if (mounted) {
        setState(() {
          _insightsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load AI insights. Please check connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _openChatWithQuestion([String? initialQuestion]) {
    final query = (initialQuestion ?? _questionController.text).trim();
    _questionController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiChatScreen(
          repository: _aiRepo,
          initialQuestion: query.isNotEmpty ? query : null,
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return 'PKR ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary,
              child: const Text(
                'AS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            tooltip: 'Open AI Financial Chat',
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            onPressed: () => _openChatWithQuestion(),
          ),
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: 'Toggle Theme',
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
              ),
              onPressed: widget.onToggleTheme,
            ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your March AI Financial summary is ready'),
                    ),
                  );
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadInsights,
          child: _buildBody(isDark),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final data = _insightsData!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Money Coach Top Banner (Screen 10)
          AiSummaryCard(
            headline: data.coachHeadline,
            subtext: data.coachSubtext,
            coachTitle: 'Your March money coach',
          ),
          const SizedBox(height: 20),

          // Section Title: "Your insights" with sparkle icon
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Your insights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Top Category Card
          TopCategoryCard(
            insight: data.topCategory,
            onTap: widget.onNavigateToBudget,
          ),
          const SizedBox(height: 10),

          // 2. Trend Alert Card
          TrendAlertCard(
            trendAlert: data.trendAlert,
            onTap: () => _openChatWithQuestion('Tell me more about my weekend spending trend'),
          ),
          const SizedBox(height: 10),

          // 3. Saving Suggestion Card
          SavingSuggestionCard(
            savingSuggestion: data.savingSuggestion,
            onActionTap: widget.onNavigateToBudget,
          ),
          const SizedBox(height: 10),

          // 4. Anomaly / Unusual Spending Card (conditional!)
          if (data.anomalyDetected.isDetected) ...[
            AnomalyCard(
              anomaly: data.anomalyDetected,
              onReview: () {
                _openChatWithQuestion('Tell me about the higher-than-usual purchase on March 9');
              },
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 10),

          // Section Title: "Ask AI"
          Text(
            'Ask AI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 10),

          // Ask AI Input Field (Screen 10)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    onSubmitted: (val) => _openChatWithQuestion(val),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Where am I spending most?',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMutedLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () => _openChatWithQuestion(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Suggested Questions Chips (Screen 10)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _suggestedQuestions.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SuggestedQuestionChip(
                    label: q,
                    onTap: () => _openChatWithQuestion(q),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // March Summary Card (Screen 10)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'March summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Icon(
                      Icons.bar_chart_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryColumn('Income', _formatAmount(data.monthlyIncome), isDark),
                    _buildSummaryColumn('Expenses', _formatAmount(data.monthlyExpenses), isDark),
                    _buildSummaryColumn('Saved', _formatAmount(data.monthlySaved), isDark, isHighlight: true),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Excellent progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      data.lastUpdatedText,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isHighlight
                ? AppColors.primary
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Unable to load insights',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadInsights,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
