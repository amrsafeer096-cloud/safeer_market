import '../../../../l10n/app_localizations.dart';

/// Whether a warehouse document brings goods in or sends them back.
enum ReceiptType {
  receive('استلام'),
  supplierReturn('استرجاع');

  const ReceiptType(this.label);

  /// Stored as-is in `app_receipts.doc_type`; use [displayLabel] in the UI.
  final String label;

  String displayLabel(AppLocalizations l10n) => switch (this) {
        ReceiptType.receive => l10n.receiptTypeReceive,
        ReceiptType.supplierReturn => l10n.receiptTypeSupplierReturn,
      };
}
