import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/order_rating.dart';
import '../providers/admin_providers.dart';

/// «تقييم العميل» on Order Status — shown only when the order was rated.
class CustomerOrderRatingCard extends ConsumerWidget {
  const CustomerOrderRatingCard({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(adminOrderRatingProvider(orderId));
    return ratingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rating) {
        if (rating == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _RatingCard(rating: rating),
        );
      },
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final OrderRating rating;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final comment = rating.comment;

    return Container(
      key: const Key('customer-order-rating-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 8),
              const Text(
                'تقييم العميل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StarsRow(
            label: 'خدمة التوصيل',
            score: rating.deliveryRating,
          ),
          const SizedBox(height: 10),
          _StarsRow(
            label: 'جودة المنتجات',
            score: rating.productRating,
          ),
          if (comment != null) ...[
            const SizedBox(height: 14),
            Text(
              'تعليق العميل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              comment,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.muted,
            ),
          ),
        ),
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= score ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 20,
            color: i <= score ? Colors.amber.shade700 : palette.muted,
          ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ],
    );
  }
}
