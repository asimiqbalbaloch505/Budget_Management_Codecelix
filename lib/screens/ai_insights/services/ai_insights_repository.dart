import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_insight_model.dart';

abstract class AiInsightsRepository {
  Future<AiInsightsData> getInsights();
  Future<String> askQuestion(String question);
}

/// Concrete implementation connecting to Sahar Fatima's AI backend endpoint
class HttpAiInsightsRepository implements AiInsightsRepository {
  final String baseUrl;
  final String? authToken;
  final http.Client _client;

  HttpAiInsightsRepository({
    this.baseUrl = 'http://localhost:3000/api',
    this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  @override
  Future<AiInsightsData> getInsights() async {
    final uri = Uri.parse('$baseUrl/ai/insights');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final responseWrapper = AiInsightsResponse.fromJson(json);
      return responseWrapper.data;
    } else {
      throw Exception('Failed to fetch AI insights (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<String> askQuestion(String question) async {
    final uri = Uri.parse('$baseUrl/ai/ask');
    final body = jsonEncode({'question': question});
    final response = await _client.post(uri, headers: _headers, body: body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as Map<String, dynamic>? ?? {};
      return data['answer'] ?? 'No answer provided.';
    } else {
      throw Exception('Failed to get answer from AI (${response.statusCode}): ${response.body}');
    }
  }
}

/// Standalone fallback implementation matching the approved Pennywise UI screenshots
class MockAiInsightsRepository implements AiInsightsRepository {
  @override
  Future<AiInsightsData> getInsights() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const AiInsightsData(
      coachHeadline: 'Your finances are looking strong',
      coachSubtext: 'Here are the patterns and opportunities I found in your spending.',
      topCategory: TopCategoryInsight(
        name: 'Food',
        insight: 'Food is your top category (26%).',
        amount: 9450.0,
        percentage: 26.0,
      ),
      trendAlert: 'Weekend spending is up 18% vs last month.',
      savingSuggestion: 'Try a PKR 800 weekly dining limit to save PKR 3,200.',
      anomalyDetected: AnomalyInsight(
        isDetected: true,
        message: 'Higher-than-usual purchase detected: Shopping PKR 4,800 on Mar 9.',
        category: 'Shopping',
        amount: 4800.0,
        date: 'Mar 9',
      ),
      monthlyIncome: 120000.0,
      monthlyExpenses: 35750.0,
      monthlySaved: 84250.0,
      progressStatus: 'Excellent progress',
      lastUpdatedText: 'Updated just now',
    );
  }

  @override
  Future<String> askQuestion(String question) async {
    await Future.delayed(const Duration(milliseconds: 850));
    final q = question.toLowerCase();

    if (q.contains('where') && q.contains('spending') || q.contains('most') || q.contains('highest')) {
      return 'You are spending the most on Food, totaling PKR 9,450 this month, which is 26% of your overall expenses. Bills come second at PKR 8,700 (24%).';
    } else if (q.contains('save') || q.contains('saving') || q.contains('tip')) {
      return 'Based on your patterns, you can save roughly PKR 3,200 by keeping weekend dining below PKR 800 per outing. You can also reallocate PKR 1,000 from Shopping.';
    } else if (q.contains('compare') || q.contains('february')) {
      return 'Compared to February, your total spending is 6.2% lower, but weekend dining increased by 18%. Your savings rate increased from 64% to 70.2%.';
    } else if (q.contains('summarize') || q.contains('summary')) {
      return 'This month you earned PKR 1,20,000 and spent PKR 35,750 across 7 categories. Your total remaining budget is PKR 14,250 with net savings of PKR 84,250. Excellent discipline!';
    } else if (q.contains('overspend') || q.contains('limit')) {
      return 'You have used 71.5% of your total budget. Watch out for Bills which is currently at 87% of its limit with PKR 1,300 remaining.';
    } else {
      return 'I analyzed your March expenses: You have spent PKR 35,750 out of PKR 50,000. Your top expense is Food (PKR 9,450). Would you like specific tips to lower dining or shopping expenses?';
    }
  }
}
