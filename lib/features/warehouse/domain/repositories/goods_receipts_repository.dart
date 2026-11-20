import '../entities/receipt_line.dart';
import '../entities/receipt_product.dart';
import '../entities/receipt_type.dart';
import '../entities/supplier.dart';

abstract interface class GoodsReceiptsRepository {
  /// Registered suppliers, ordered by supplier number.
  Future<List<Supplier>> fetchSuppliers();

  /// Name and image for a scanned barcode. Never throws: an unknown barcode
  /// or a failed lookup comes back with a null name.
  Future<ReceiptProduct> lookupProduct(String barcode);

  /// Inserts a draft `app_receipts` row and its `app_receipt_items`.
  /// `document_date` is always the day of saving.
  /// The ERP assigns the document number. Returns the new receipt id.
  Future<String> submit({
    required ReceiptType type,
    required Supplier supplier,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required List<ReceiptLine> items,
  });
}

class GoodsReceiptFailure implements Exception {
  const GoodsReceiptFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
