import 'package:supabase_flutter/supabase_flutter.dart';

/// Creates rows in `loyalty_campaigns` (admin «نقاط الولاء» broadcasts).
class LoyaltyCampaignsService {
  const LoyaltyCampaignsService(this._client);

  final SupabaseClient _client;

  Future<String> createCampaign({
    required String title,
    required String body,
    required int pointsReward,
    required int requiredOrders,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (pointsReward <= 0 || requiredOrders <= 0) {
      throw const LoyaltyCampaignFailure(
        'أدخل عدد نقاط وعدد أوردرات أكبر من صفر',
      );
    }
    if (!endDate.isAfter(startDate)) {
      throw const LoyaltyCampaignFailure(
        'تاريخ النهاية يجب أن يكون بعد تاريخ البداية',
      );
    }
    try {
      final row = await _client
          .from('loyalty_campaigns')
          .insert({
            'title': title.trim(),
            'body': body.trim(),
            'points_reward': pointsReward,
            'required_orders': requiredOrders,
            'start_date': startDate.toUtc().toIso8601String(),
            'end_date': endDate.toUtc().toIso8601String(),
            'is_active': true,
          })
          .select('id')
          .single();
      return '${row['id']}';
    } on PostgrestException catch (error) {
      throw LoyaltyCampaignFailure(error.message);
    }
  }
}

class LoyaltyCampaignFailure implements Exception {
  const LoyaltyCampaignFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
