import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';

/// Opens the InstaPay / transfer receipt viewer (view, copy, share).
void showAdminTransferReceiptDialog(BuildContext context, String receiptUrl) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _TransferReceiptDialog(receiptUrl: receiptUrl),
  );
}

class _TransferReceiptDialog extends StatefulWidget {
  const _TransferReceiptDialog({required this.receiptUrl});

  final String receiptUrl;

  @override
  State<_TransferReceiptDialog> createState() => _TransferReceiptDialogState();
}

class _TransferReceiptDialogState extends State<_TransferReceiptDialog> {
  Uint8List? _bytes;
  String? _mimeType;
  String _fileName = 'instapay_receipt.jpg';
  var _loadingBytes = true;
  var _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReceiptBytes();
  }

  Future<void> _loadReceiptBytes() async {
    setState(() {
      _loadingBytes = true;
      _loadError = null;
    });
    try {
      final uri = Uri.parse(widget.receiptUrl);
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final path = uri.path.toLowerCase();
      final contentType =
          response.headers['content-type']?.split(';').first.trim();
      final mime = switch (null) {
        _ when contentType != null && contentType.startsWith('image/') =>
          contentType,
        _ when path.endsWith('.png') => 'image/png',
        _ when path.endsWith('.webp') => 'image/webp',
        _ when path.endsWith('.gif') => 'image/gif',
        _ => 'image/jpeg',
      };
      final ext = switch (mime) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/gif' => 'gif',
        _ => 'jpg',
      };
      if (!mounted) return;
      setState(() {
        _bytes = response.bodyBytes;
        _mimeType = mime;
        _fileName = 'instapay_receipt.$ext';
        _loadingBytes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingBytes = false;
        _loadError = AppLocalizations.of(context)!.failedToLoadProducts;
      });
    }
  }

  Future<void> _copyImage() async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      _toast(l10n.adminReceiptActionFailed);
      return;
    }
    setState(() => _busy = true);
    try {
      await Pasteboard.writeImage(bytes);
      if (!mounted) return;
      _toast(l10n.adminReceiptImageCopied);
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.adminReceiptActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      _toast(l10n.adminReceiptActionFailed);
      return;
    }
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: _mimeType ?? 'image/jpeg',
              name: _fileName,
            ),
          ],
          fileNameOverrides: [_fileName],
          text: l10n.adminViewTransferReceipt,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.adminReceiptActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = Color(0xFF5A2D82);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.adminViewTransferReceipt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _bytes != null
                      ? Image.memory(
                          _bytes!,
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          widget.receiptUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (_, __, ___) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _loadError ?? l10n.failedToLoadProducts,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                children: [
                  if (_loadingBytes)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              (_busy || _bytes == null) ? null : _copyImage,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(l10n.adminCopyReceiptImage),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(
                              color: accent.withValues(alpha: 0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              (_busy || _bytes == null) ? null : _shareImage,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(l10n.adminShareReceipt),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                accent.withValues(alpha: 0.45),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
