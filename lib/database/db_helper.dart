import 'package:supabase_flutter/supabase_flutter.dart';

class DbHelper {
  DbHelper._();

  static const String _supabaseUrl = 'https://qoiidyctbfyccuogdgdz.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_7tLBb-DjAVsO4zClIiEp8g_CXAWi8AD';

  static final SupabaseClient client = SupabaseClient(
    _supabaseUrl,
    _supabaseAnonKey,
  );

  /// Basic connection check. This reads one category row, if permitted by RLS.
  /// Throws a PostgrestException if the table/policies/credentials are incorrect.
  static Future<bool> testConnection() async {
    final result = await client
        .from('categories')
        .select('id, name, type')
        .limit(1);

    // An empty table still means the request reached Supabase successfully.
    return result is List;
  }

  /// Fetch categories for dropdowns and transaction forms.
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final result = await client
        .from('categories')
        .select('id, user_id, name, type')
        .order('name');

    return List<Map<String, dynamic>>.from(result);
  }

  /// Fetch transactions for the currently authenticated user.
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Please sign in before loading transactions.');
    }

    final result = await client
        .from('transactions')
        .select(
          'id, user_id, category_id, type, amount, transaction_date, note, created_at',
        )
        .eq('user_id', userId)
        .order('transaction_date', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Fetch the current user's profile row.
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final result = await client
        .from('users')
        .select('id, full_name, email, currency, dark_mode, created_at')
        .eq('id', userId)
        .maybeSingle();

    return result;
  }
}
