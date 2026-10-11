class TopCategoryInsight {
  final String name;
  final String insight;
  final double amount;
  final double percentage;

  const TopCategoryInsight({
    required this.name,
    required this.insight,
    this.amount = 9450.0,
    this.percentage = 26.0,
  });

  factory TopCategoryInsight.fromJson(Map<String, dynamic> json) {
    return TopCategoryInsight(
      name: json['name'] ?? 'Food',
      insight: json['insight'] ?? 'Food is your top category (26%).',
      amount: (json['amount'] ?? 9450.0).toDouble(),
      percentage: (json['percentage'] ?? 26.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'insight': insight,
    'amount': amount,
    'percentage': percentage,
  };
}

class AnomalyInsight {
  final bool isDetected;
  final String message;
  final String? category;
  final double? amount;
  final String? date;

  const AnomalyInsight({
    required this.isDetected,
    required this.message,
    this.category,
    this.amount,
    this.date,
  });

  factory AnomalyInsight.fromJson(Map<String, dynamic> json) {
    return AnomalyInsight(
      isDetected: json['isDetected'] ?? false,
      message: json['message'] ?? 'No unusual spending detected.',
      category: json['category'],
      amount: json['amount'] != null ? (json['amount']).toDouble() : null,
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() => {
    'isDetected': isDetected,
    'message': message,
    'category': category,
    'amount': amount,
    'date': date,
  };
}

class AiInsightsData {
  final TopCategoryInsight topCategory;
  final String trendAlert;
  final String savingSuggestion;
  final AnomalyInsight anomalyDetected;
  final String coachHeadline;
  final String coachSubtext;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlySaved;
  final String progressStatus;
  final String lastUpdatedText;

  const AiInsightsData({
    required this.topCategory,
    required this.trendAlert,
    required this.savingSuggestion,
    required this.anomalyDetected,
    this.coachHeadline = 'Your finances are looking strong',
    this.coachSubtext = 'Here are the patterns and opportunities I found in your spending.',
    this.monthlyIncome = 120000.0,
    this.monthlyExpenses = 35750.0,
    this.monthlySaved = 84250.0,
    this.progressStatus = 'Excellent progress',
    this.lastUpdatedText = 'Updated just now',
  });

  factory AiInsightsData.fromJson(Map<String, dynamic> json) {
    return AiInsightsData(
      topCategory: json['topCategory'] != null
          ? TopCategoryInsight.fromJson(json['topCategory'])
          : const TopCategoryInsight(
              name: 'Food',
              insight: 'Food is your top category (26%).',
            ),
      trendAlert: json['trendAlert'] ?? 'Weekend spending is up 18% vs last month.',
      savingSuggestion: json['savingSuggestion'] ??
          'Try a PKR 800 weekly dining limit to save PKR 3,200.',
      anomalyDetected: json['anomalyDetected'] != null
          ? AnomalyInsight.fromJson(json['anomalyDetected'])
          : const AnomalyInsight(
              isDetected: true,
              message: 'Higher-than-usual purchase detected: Shopping PKR 4,800 on Mar 9.',
            ),
      coachHeadline: json['coachHeadline'] ?? 'Your finances are looking strong',
      coachSubtext: json['coachSubtext'] ??
          'Here are the patterns and opportunities I found in your spending.',
      monthlyIncome: (json['monthlyIncome'] ?? 120000.0).toDouble(),
      monthlyExpenses: (json['monthlyExpenses'] ?? 35750.0).toDouble(),
      monthlySaved: (json['monthlySaved'] ?? 84250.0).toDouble(),
      progressStatus: json['progressStatus'] ?? 'Excellent progress',
      lastUpdatedText: json['lastUpdatedText'] ?? 'Updated just now',
    );
  }

  Map<String, dynamic> toJson() => {
    'topCategory': topCategory.toJson(),
    'trendAlert': trendAlert,
    'savingSuggestion': savingSuggestion,
    'anomalyDetected': anomalyDetected.toJson(),
    'coachHeadline': coachHeadline,
    'coachSubtext': coachSubtext,
    'monthlyIncome': monthlyIncome,
    'monthlyExpenses': monthlyExpenses,
    'monthlySaved': monthlySaved,
    'progressStatus': progressStatus,
    'lastUpdatedText': lastUpdatedText,
  };
}

class AiInsightsResponse {
  final bool success;
  final String? message;
  final AiInsightsData data;

  const AiInsightsResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory AiInsightsResponse.fromJson(Map<String, dynamic> json) {
    return AiInsightsResponse(
      success: json['success'] ?? true,
      message: json['message'],
      data: AiInsightsData.fromJson(json['data'] ?? {}),
    );
  }
}
