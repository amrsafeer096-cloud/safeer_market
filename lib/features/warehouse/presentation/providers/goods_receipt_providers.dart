import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_goods_receipts_repository.dart';
import '../../domain/entities/receipt_line.dart';
import '../../domain/entities/receipt_type.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/goods_receipts_repository.dart';

final goodsReceiptsRepositoryProvider = Provider<GoodsReceiptsRepository>((
  ref,
) {
  return SupabaseGoodsReceiptsRepository(ref.watch(supabaseClientProvider));
});

final goodsReceiptActionsProvider = Provider(GoodsReceiptActions.new);

class GoodsReceiptActions {
  const GoodsReceiptActions(this._ref);

  final Ref _ref;

  Future<String> submit({
    required ReceiptType type,
    required Supplier supplier,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required List<ReceiptLine> items,
  }) {
    if (_ref.read(currentUserProvider) == null) {
      throw GoodsReceiptFailure(
        _ref.read(appLocalizationsProvider).pleaseSignInFirst,
      );
    }
    return _ref.read(goodsReceiptsRepositoryProvider).submit(
          type: type,
          supplier: supplier,
          invoiceNumber: invoiceNumber,
          invoiceDate: invoiceDate,
          items: items,
        );
  }
}
