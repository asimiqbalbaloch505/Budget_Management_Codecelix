import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  static const String _model = 'gemini-3.5-flash';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final String apiKey;

  AiService({
    required this.apiKey,
  });

  // ============================================================
  // AI INSIGHTS
  // ============================================================

  Future<Map<String, dynamic>> generateInsights(
      Map<String, dynamic> financialSummary,
      ) async {
    final prompt = _buildInsightsPrompt(financialSummary);

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$_model:generateContent',
      ),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              },
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'OBJECT',
            'properties': {
              'topCategory': {
                'type': 'OBJECT',
                'properties': {
                  'name': {
                    'type': 'STRING',
                  },
                  'insight': {
                    'type': 'STRING',
                  },
                },
                'required': [
                  'name',
                  'insight',
                ],
              },
              'trendAlert': {
                'type': 'STRING',
              },
              'savingSuggestion': {
                'type': 'STRING',
              },
              'anomalyDetected': {
                'type': 'OBJECT',
                'properties': {
                  'isDetected': {
                    'type': 'BOOLEAN',
                  },
                  'message': {
                    'type': 'STRING',
                  },
                },
                'required': [
                  'isDetected',
                  'message',
                ],
              },
            },
            'required': [
              'topCategory',
              'trendAlert',
              'savingSuggestion',
              'anomalyDetected',
            ],
          },
        },
      }),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Gemini insights request failed.\n'
            'Status code: ${response.statusCode}\n'
            'Response: ${response.body}',
      );
    }

    final responseData = _decodeResponse(response.body);

    final generatedText = _extractGeminiText(responseData);

    final decodedData = jsonDecode(generatedText);

    if (decodedData is! Map<String, dynamic>) {
      throw Exception(
        'Gemini returned an invalid insights format.',
      );
    }

    // Return the same data structure used by the architecture
    // document's AI insights contract.
    return {
      'success': true,
      'message': 'AI insights generated successfully.',
      'data': decodedData,
    };
  }

  // ============================================================
  // ASK AI
  // ============================================================

  Future<Map<String, dynamic>> askQuestion(
      String question,
      Map<String, dynamic> financialSummary,
      ) async {
    final prompt = _buildQuestionPrompt(
      question,
      financialSummary,
    );

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$_model:generateContent',
      ),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              },
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'OBJECT',
            'properties': {
              'answer': {
                'type': 'STRING',
              },
            },
            'required': [
              'answer',
            ],
          },
        },
      }),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Gemini question request failed.\n'
            'Status code: ${response.statusCode}\n'
            'Response: ${response.body}',
      );
    }

    final responseData = _decodeResponse(response.body);

    final generatedText = _extractGeminiText(responseData);

    final decodedData = jsonDecode(generatedText);

    if (decodedData is! Map<String, dynamic>) {
      throw Exception(
        'Gemini returned an invalid answer format.',
      );
    }

    final answer = decodedData['answer'];

    if (answer == null) {
      throw Exception(
        'Gemini response does not contain an answer.',
      );
    }

    // Return the same structure documented for POST /api/ai/ask.
    return {
      'success': true,
      'message': 'AI answer generated successfully.',
      'data': {
        'answer': answer.toString(),
      },
    };
  }

  // ============================================================
  // INSIGHTS PROMPT
  // ============================================================

  String _buildInsightsPrompt(
      Map<String, dynamic> financialSummary,
      ) {
    return '''
You are a personal finance assistant for a Smart Expense & Budget Manager.

Analyze ONLY the financial information provided below.

Financial summary:
${jsonEncode(financialSummary)}

Generate four useful insights:

1. topCategory:
   Identify the category with the highest spending.
   Provide its name and a short insight about that spending.

2. trendAlert:
   Identify an important spending trend or observation.
   If the provided data is not sufficient to determine a trend,
   say "Not enough data available."

3. savingSuggestion:
   Give one realistic saving suggestion based only on the
   provided financial information.
   Do not invent income, expenses, or transactions.

4. anomalyDetected:
   Determine whether the provided data contains an unusually
   high or potentially abnormal expense.
   Set isDetected to false if there is not enough evidence.
   Do not invent an anomaly.

Return ONLY the requested JSON structure.
''';
  }

  // ============================================================
  // QUESTION PROMPT
  // ============================================================

  String _buildQuestionPrompt(
      String question,
      Map<String, dynamic> financialSummary,
      ) {
    return '''
You are the personal financial assistant inside a Smart Expense & Budget Manager app.

Your job is to answer the user's question using the financial data provided by the app.

IMPORTANT RULES:

1. USE ONLY THE PROVIDED FINANCIAL DATA
- Do not invent transactions, amounts, categories, budgets, dates, income, expenses, percentages, or trends.
- Do not assume financial information that is not present.
- If the required information is missing, clearly say that the available data is not sufficient to give a precise answer.

2. PERSONALIZE EVERY ANSWER
- Base your response on the user's actual financial summary.
- Refer to relevant spending categories, amounts, budgets, or transactions when available.
- Avoid generic financial advice when the provided data allows you to give more specific advice.

3. UNDERSTAND THE USER'S INTENT
Determine what the user is actually asking before answering.

Examples:
- "Where am I spending most?" → identify the highest spending category.
- "How much did I spend on food?" → give the food spending amount if available.
- "Am I overspending?" → compare spending with the available budget or other relevant data.
- "How can I save money?" → identify realistic saving opportunities from the user's spending.
- "What did I spend the most on?" → identify the largest category or transaction depending on the available data.
- "Why are my expenses high?" → identify the categories or transactions contributing most to expenses.
- "Can I afford this?" → only answer if sufficient income, balance, budget, and/or expense information is available. Do not assume affordability from incomplete data.

4. USE NUMBERS WHEN THEY ARE AVAILABLE
- Include relevant amounts in the answer.
- Use percentages only when they are provided or can be reliably calculated from the provided data.
- When making a comparison, clearly state what is being compared.

5. GIVE ACTIONABLE HELP
When the user asks for advice, provide a practical suggestion based on their financial data.
For example, instead of:
"Try to reduce your spending."

Prefer something like:
"Food is currently your largest expense at Rs 9,450. Reducing dining expenses by Rs 800 per month could help lower your overall spending."

Only give such specific recommendations when the provided data supports them.

6. BE CAREFUL WITH COMPARISONS
- Only compare periods, categories, or transactions when the necessary data is available.
- Do not claim that spending increased or decreased unless the provided data supports that comparison.

7. HANDLE MISSING INFORMATION
If the question cannot be answered accurately:
- Do not guess.
- State what information is available.
- Explain briefly what additional information would be needed.

8. RESPONSE STYLE
- Answer the question directly first.
- Be concise but useful.
- Use simple, friendly language suitable for a mobile finance app.
- Avoid unnecessary technical terminology.
- Do not overwhelm the user with unrelated financial advice.
- If the question asks for advice, provide a clear practical next step.

FINANCIAL DATA FROM THE APP:
${jsonEncode(financialSummary)}

USER'S QUESTION:
$question

Return ONLY valid JSON in exactly this format:

{
  "answer": "your personalized answer here"
}
''';
  }

  // ============================================================
  // DECODE GEMINI HTTP RESPONSE
  // ============================================================

  Map<String, dynamic> _decodeResponse(
      String responseBody,
      ) {
    final decoded = jsonDecode(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Gemini returned an invalid response.',
      );
    }

    return decoded;
  }

  // ============================================================
  // EXTRACT TEXT FROM GEMINI RESPONSE
  // ============================================================

  String _extractGeminiText(
      Map<String, dynamic> responseData,
      ) {
    final candidates = responseData['candidates'];

    if (candidates == null ||
        candidates is! List ||
        candidates.isEmpty) {
      throw Exception(
        'Gemini returned no candidates.',
      );
    }

    final firstCandidate = candidates[0];

    if (firstCandidate is! Map<String, dynamic>) {
      throw Exception(
        'Gemini returned an invalid candidate.',
      );
    }

    final content = firstCandidate['content'];

    if (content is! Map<String, dynamic>) {
      throw Exception(
        'Gemini response does not contain content.',
      );
    }

    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      throw Exception(
        'Gemini response does not contain parts.',
      );
    }

    final firstPart = parts[0];

    if (firstPart is! Map<String, dynamic>) {
      throw Exception(
        'Gemini returned an invalid response part.',
      );
    }

    final text = firstPart['text'];

    if (text == null) {
      throw Exception(
        'Gemini response does not contain generated text.',
      );
    }

    return text.toString();
  }
}