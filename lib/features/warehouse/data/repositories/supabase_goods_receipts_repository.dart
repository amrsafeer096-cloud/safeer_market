import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/receipt_line.dart';
import '../../domain/entities/receipt_product.dart';
import '../../domain/entities/receipt_type.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/goods_receipts_repository.dart';

class SupabaseGoodsReceiptsRepository implements GoodsReceiptsRepository {
  SupabaseGoodsReceiptsRepository(this._client);

  static const _draft = 'مبدئي';

  // Public bucket holding one <barcode>.jpg per product.
  static const _imagesBucket = 'product_images';

  // PostgREST caps each response (1000 rows by default), so suppliers are paged.
  static const _supplierPageSize = 1000;

  static final _sqlDate = DateFormat('yyyy-MM-dd', 'en_US');

  final SupabaseClient _client;

  @override
  Future<List<Supplier>> fetchSuppliers() async {
    try {
      final suppliers = <Supplier>[];
      for (var from = 0;; from += _supplierPageSize) {
        final rows = await _client
            .from('app_suppliers')
            .select('id, name')
            .order('id', ascending: true)
            .range(from, from + _supplierPageSize - 1);
        suppliers.addAll([
          for (final row in rows)
            Supplier(
              number: (row['id'] as num).toInt(),
              name: (row['name'] as String? ?? '').trim(),
            ),
        ]);
        if (rows.length < _supplierPageSize) break;
      }
      return suppliers;
    } on PostgrestException catch (error) {
      throw GoodsReceiptFailure(
        L10n.current.warehouseSuppliersLoadFailed(error.message),
      );
    } catch (_) {
      throw GoodsReceiptFailure(L10n.current.serverConnectionError);
    }
  }

  @override
  Future<ReceiptProduct> lookupProduct(String barcode) async {
    final imageUrl = _client.storage
        .from(_imagesBucket)
        .getPublicUrl('${Uri.encodeComponent(barcode)}.jpg');
    try {
      final row = await _client
          .from('products')
          .select('name, category')
          .eq('barcode', barcode)
          .maybeSingle();
      final name = (row?['name'] as String?)?.trim();
      return ReceiptProduct(
        name: name == null || name.isEmpty ? null : name,
        category: row?['category'] as String?,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return ReceiptProduct(imageUrl: imageUrl);
    }
  }

  @override
  Future<String> submit({
    required ReceiptType type,
    required Supplier supplier,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required List<ReceiptLine> items,
  }) async {
    final invoiceNo = invoiceNumber.trim();
    if (invoiceNo.isEmpty) {
      throw GoodsReceiptFailure(L10n.current.invoiceNumberRequired);
    }
    if (items.isEmpty) {
      throw GoodsReceiptFailure(L10n.current.addAtLeastOneItem);
    }

    try {
      final receipt = await _client
          .from('app_receipts')
          .insert({
            'doc_type': type.label,
            'supplier_id': supplier.number,
            'supplier_name': supplier.name,
            'invoice_no': invoiceNo,
            'invoice_date': _sqlDate.format(invoiceDate),
            'document_date': _sqlDate.format(DateTime.now()),
            'status': _draft,
          })
          .select('id')
          .single();
      final Object receiptId = receipt['id'];

      try {
        await _client.from('app_receipt_items').insert([
          for (final item in items)
            {
              'receipt_id': receiptId,
              'barcode': item.barcode,
              'quantity': item.quantity,
            },
        ]);
      } catch (_) {
        await _deleteReceipt(receiptId);
        rethrow;
      }

      return receiptId.toString();
    } on PostgrestException catch (error) {
      throw GoodsReceiptFailure(
        L10n.current.warehouseDocumentSaveFailed(error.message),
      );
    } on GoodsReceiptFailure {
      rethrow;
    } catch (_) {
      throw GoodsReceiptFailure(L10n.current.serverConnectionError);
    }
  }

  Future<void> _deleteReceipt(Object receiptId) async {
    try {
      await _client.from('app_receipts').delete().eq('id', receiptId);
    } catch (_) {}
  }
}
