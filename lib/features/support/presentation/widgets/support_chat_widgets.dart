import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/support_chat.dart';
import '../../domain/repositories/support_repository.dart';
import '../providers/support_providers.dart';

/// Bright cyan double-checks — readable on the navy outgoing bubble.
const _readReceiptBlue = Color(0xFF38BDF8);

/// Outgoing bubble fill (navy) so white/cyan ticks stay visible.
const _outgoingBubble = Color(0xFF0D3B66);

/// Today's messages show the time, older ones the date too.
String supportTimeLabel(DateTime time) {
  final now = DateTime.now();
  final today = time.year == now.year &&
      time.month == now.month &&
      time.day == now.day;
  return DateFormat(today ? 'h:mm a' : 'd MMM • h:mm a', L10n.localeName)
      .format(time);
}

String supportDurationLabel(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// A conversation, newest message at the bottom. [viewer]'s own messages sit
/// at the end side in the accent colour.
class SupportMessageList extends StatelessWidget {
  const SupportMessageList({
    super.key,
    required this.messages,
    required this.viewer,
    required this.emptyText,
    this.onOrderTap,
  });

  final List<SupportMessage> messages;
  final SupportSenderRole viewer;
  final String emptyText;
  final ValueChanged<String>? onOrderTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 56, color: palette.muted),
              const SizedBox(height: 12),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _MessageBubble(
          message: message,
          mine: message.senderRole == viewer,
          onOrderTap: onOrderTap,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    this.onOrderTap,
  });

  final SupportMessage message;
  final bool mine;
  final ValueChanged<String>? onOrderTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = mine ? Colors.white : palette.onSurface;
    return Align(
      alignment:
          mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          key: Key('support-message-${message.id}'),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: mine ? _outgoingBubble : palette.card,
            border: mine ? null : Border.all(color: palette.border),
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(18),
              topEnd: const Radius.circular(18),
              bottomStart: Radius.circular(mine ? 18 : 4),
              bottomEnd: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.hasImage) ...[
                _ImageAttachment(
                  url: message.attachmentUrl!,
                  onTap: () => _showZoom(context, message.attachmentUrl!),
                ),
                if (message.message.trim().isNotEmpty &&
                    message.message != SupportAttachmentType.image.previewLabel)
                  const SizedBox(height: 8),
              ],
              if (message.hasVoice) ...[
                _VoicePlayer(
                  url: message.attachmentUrl!,
                  durationSeconds: message.voiceDuration ?? 0,
                  light: mine,
                ),
                const SizedBox(height: 4),
              ],
              if (message.hasOrder) ...[
                _OrderCard(
                  message: message,
                  light: mine,
                  onTap: onOrderTap == null
                      ? null
                      : () => onOrderTap!(message.orderId!),
                ),
                const SizedBox(height: 4),
              ],
              if (message.message.trim().isNotEmpty &&
                  !message.hasVoice &&
                  !(message.hasImage &&
                      message.message ==
                          SupportAttachmentType.image.previewLabel) &&
                  !(message.hasOrder &&
                      message.message.startsWith('استفسار بخصوص')))
                SelectableText(
                  message.message,
                  style:
                      TextStyle(fontSize: 15, height: 1.5, color: foreground),
                ),
              if (message.hasOrder)
                SelectableText(
                  message.message,
                  style:
                      TextStyle(fontSize: 14, height: 1.4, color: foreground),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    supportTimeLabel(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: foreground.withValues(alpha: 0.7),
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    _ReceiptTicks(
                      status: message.status,
                      isRead: message.isRead,
                      light: mine,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showZoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _ReceiptTicks extends StatelessWidget {
  const _ReceiptTicks({
    required this.status,
    required this.isRead,
    required this.light,
  });

  final SupportMessageStatus status;
  final bool isRead;
  final bool light;

  @override
  Widget build(BuildContext context) {
    if (isRead || status == SupportMessageStatus.read) {
      return const Icon(Icons.done_all, size: 16, color: _readReceiptBlue);
    }
    if (status == SupportMessageStatus.delivered) {
      return const Icon(Icons.done_all, size: 16, color: Colors.white70);
    }
    return const Icon(Icons.check, size: 15, color: Colors.white70);
  }
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, maxHeight: 220),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => const SizedBox(
              height: 80,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.message,
    required this.light,
    this.onTap,
  });

  final SupportMessage message;
  final bool light;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final id = message.orderId ?? '';
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return Material(
      color: light ? Colors.white.withValues(alpha: 0.15) : Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('support-order-card-$id'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: light ? Colors.white : Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'طلب #$short',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: light ? Colors.white : Colors.orange.shade900,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: light ? Colors.white70 : Colors.orange.shade700,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({
    required this.url,
    required this.durationSeconds,
    required this.light,
  });

  final String url;
  final int durationSeconds;
  final bool light;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _pos;
  StreamSubscription<void>? _complete;
  var _playing = false;
  var _position = Duration.zero;
  late Duration _duration = Duration(seconds: widget.durationSeconds);

  @override
  void initState() {
    super.initState();
    _pos = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _complete = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
    _player.onDurationChanged.listen((d) {
      if (mounted && d.inMilliseconds > 0) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _pos?.cancel();
    _complete?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    await _player.play(UrlSource(widget.url));
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _duration.inMilliseconds <= 0
        ? (widget.durationSeconds * 1000).clamp(1, 1 << 30)
        : _duration.inMilliseconds;
    final value = (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final fg = widget.light ? Colors.white : context.palette.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _toggle,
          icon: Icon(
            _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: fg,
            size: 32,
          ),
        ),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              onChanged: (v) => _player.seek(
                Duration(milliseconds: (v * totalMs).round()),
              ),
              activeColor: fg,
              inactiveColor: fg.withValues(alpha: 0.3),
            ),
          ),
        ),
        Text(
          supportDurationLabel(
            _playing || _position.inSeconds > 0
                ? _position.inSeconds
                : widget.durationSeconds,
          ),
          style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.85)),
        ),
      ],
    );
  }
}

/// Text field, attachment menu, mic, and send.
class SupportComposer extends ConsumerStatefulWidget {
  const SupportComposer({
    super.key,
    required this.hint,
    required this.chatId,
    required this.senderRole,
    this.customerUserId,
    this.onOrderAttached,
  });

  static const maxLength = 2000;

  final String hint;
  final String chatId;
  final SupportSenderRole senderRole;

  /// Required for the customer-order picker (admin side).
  final String? customerUserId;
  final ValueChanged<String>? onOrderAttached;

  @override
  ConsumerState<SupportComposer> createState() => _SupportComposerState();
}

class _SupportComposerState extends ConsumerState<SupportComposer> {
  final _controller = TextEditingController();
  late final AudioRecorder _recorder;
  bool _sending = false;
  bool _recording = false;
  bool _startingRecord = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    await _runSend(() async {
      await ref.read(supportRepositoryProvider).sendMessage(
            chatId: widget.chatId,
            message: text,
            senderRole: widget.senderRole,
          );
      _controller.clear();
    });
  }

  Future<void> _runSend(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await action();
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(error.toString()),
        ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImageBytes({
    required Uint8List bytes,
    required String name,
    required String contentType,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null || bytes.isEmpty) return;
    await _runSend(() async {
      final repo = ref.read(supportRepositoryProvider);
      final url = await repo.uploadMedia(
        userId: userId,
        bytes: bytes,
        fileName: name,
        contentType: contentType,
      );
      await repo.sendMessage(
        chatId: widget.chatId,
        message: SupportAttachmentType.image.previewLabel,
        senderRole: widget.senderRole,
        attachmentType: SupportAttachmentType.image,
        attachmentUrl: url,
      );
    });
  }

  Future<void> _pickImage({required ImageSource source}) async {
    try {
      // Camera on web/desktop may fall back to a file chooser with capture.
      final picked = await ImagePicker().pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await _sendImageBytes(
          bytes: bytes,
          name: picked.name.isEmpty ? 'photo.jpg' : picked.name,
          contentType: picked.mimeType ?? _mimeFromName(picked.name, 'image/jpeg'),
        );
        return;
      }
    } catch (error) {
      debugPrint('Support image picker ($source): $error');
      if (source == ImageSource.camera && kIsWeb) {
        // Last resort on web: image file input (browser may offer camera).
        final files = await FilePicker.pickFiles(type: FileType.image);
        final file = files.singleOrNull;
        if (file == null) return;
        final bytes = await file.xFile.readAsBytes();
        await _sendImageBytes(
          bytes: bytes,
          name: file.name,
          contentType: _mimeFromName(file.name, 'image/jpeg'),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.secondary,
        content: Text('تعذر فتح ${source == ImageSource.camera ? 'الكاميرا' : 'المعرض'}'),
      ));
      return;
    }

    // Gallery cancelled on web: try FilePicker as an alternate gallery.
    if (source == ImageSource.gallery && kIsWeb) {
      final files = await FilePicker.pickFiles(type: FileType.image);
      final file = files.singleOrNull;
      if (file == null) return;
      final bytes = await file.xFile.readAsBytes();
      await _sendImageBytes(
        bytes: bytes,
        name: file.name,
        contentType: _mimeFromName(file.name, 'image/jpeg'),
      );
    }
  }

  Future<void> _attachOrder() async {
    final userId = widget.customerUserId;
    if (userId == null) return;
    final orders =
        await ref.read(supportRepositoryProvider).fetchCustomerOrders(userId);
    if (!mounted) return;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد طلبات لهذا العميل')),
      );
      return;
    }
    final selected = await showModalBottomSheet<SupportOrderRef>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'الاستفسار بخصوص طلب محدد',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            for (final order in orders)
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text('#${order.shortId}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  '${AppCurrency.of(order.totalAmount)} • '
                  '${DateFormat('d MMM yyyy', 'ar').format(order.createdAt)} • '
                  '${order.status}',
                ),
                onTap: () => Navigator.pop(ctx, order),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _runSend(() async {
      await ref.read(supportRepositoryProvider).sendMessage(
            chatId: widget.chatId,
            message: 'استفسار بخصوص الطلب #${selected.shortId}',
            senderRole: widget.senderRole,
            attachmentType: SupportAttachmentType.order,
            orderId: selected.id,
          );
      widget.onOrderAttached?.call(selected.id);
    });
  }

  Future<void> _showAttachMenu() async {
    final isAdmin = widget.senderRole == SupportSenderRole.admin;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('إرفاق صورة (فاتورة / منتج)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(source: ImageSource.gallery);
              },
            ),
            if (isAdmin && widget.customerUserId != null)
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('الاستفسار بخصوص طلب محدد'),
                onTap: () {
                  Navigator.pop(ctx);
                  _attachOrder();
                },
              ),
            if (!isAdmin)
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('الاستفسار بخصوص طلب محدد'),
                onTap: () {
                  Navigator.pop(ctx);
                  final uid = ref.read(currentUserProvider)?.id;
                  if (uid == null) return;
                  _attachOrderFor(uid);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _attachOrderFor(String userId) async {
    // Reuse picker with an override of customerUserId for this call.
    final orders =
        await ref.read(supportRepositoryProvider).fetchCustomerOrders(userId);
    if (!mounted) return;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد طلبات بعد')),
      );
      return;
    }
    final selected = await showModalBottomSheet<SupportOrderRef>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'الاستفسار بخصوص طلب محدد',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            for (final order in orders)
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text('#${order.shortId}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  '${AppCurrency.of(order.totalAmount)} • '
                  '${DateFormat('d MMM yyyy', 'ar').format(order.createdAt)}',
                ),
                onTap: () => Navigator.pop(ctx, order),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _runSend(() async {
      await ref.read(supportRepositoryProvider).sendMessage(
            chatId: widget.chatId,
            message: 'استفسار بخصوص الطلب #${selected.shortId}',
            senderRole: widget.senderRole,
            attachmentType: SupportAttachmentType.order,
            orderId: selected.id,
          );
    });
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await _stopRecord(send: true);
      return;
    }
    if (_startingRecord) return;
    setState(() => _startingRecord = true);
    try {
      final allowed = await _recorder.hasPermission();
      if (!allowed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يلزم السماح بالوصول إلى الميكروفون')),
        );
        return;
      }

      // Start immediately after Allow — don't wait for a second tap.
      late final String path;
      late final RecordConfig config;
      if (kIsWeb) {
        // Web ignores path and returns a blob URL from stop().
        path = '';
        config = const RecordConfig(
          encoder: AudioEncoder.opus,
          numChannels: 1,
        );
      } else {
        final dir = await getTemporaryDirectory();
        path =
            '${dir.path}/support_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        config = const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
        );
      }

      await _recorder.start(config, path: path);
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordSeconds = 0;
        _recordPath = path;
      });
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    } catch (error) {
      debugPrint('Support voice start failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.secondary,
        content: Text('تعذر بدء التسجيل: $error'),
      ));
    } finally {
      if (mounted) setState(() => _startingRecord = false);
    }
  }

  Future<void> _cancelRecord() async {
    await _stopRecord(send: false);
  }

  Future<void> _stopRecord({required bool send}) async {
    _recordTimer?.cancel();
    _recordTimer = null;
    String? stoppedPath;
    try {
      stoppedPath = await _recorder.stop();
    } catch (error) {
      debugPrint('Support voice stop failed: $error');
    }
    final path = stoppedPath ?? _recordPath;
    if (mounted) {
      setState(() {
        _recording = false;
        _recordPath = null;
      });
    } else {
      _recording = false;
      _recordPath = null;
    }
    if (!send || path == null || path.isEmpty) {
      if (!kIsWeb && path != null && path.isNotEmpty) {
        try {
          await _recorder.cancel();
        } catch (_) {}
      }
      return;
    }

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    late final Uint8List bytes;
    late final String fileName;
    late final String contentType;
    try {
      if (kIsWeb) {
        // Blob URL from record on web (opus/webm).
        final response = await http.get(Uri.parse(path));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw StateError('blob HTTP ${response.statusCode}');
        }
        bytes = response.bodyBytes;
        fileName = 'voice.webm';
        contentType = 'audio/webm';
      } else {
        bytes = await XFile(path).readAsBytes();
        fileName = 'voice.m4a';
        contentType = 'audio/mp4';
      }
    } catch (error) {
      debugPrint('Support voice read failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.secondary,
        content: Text('تعذر قراءة التسجيل: $error'),
      ));
      return;
    }
    if (bytes.isEmpty) return;

    final duration = _recordSeconds.clamp(1, 3600);
    await _runSend(() async {
      final repo = ref.read(supportRepositoryProvider);
      final url = await repo.uploadMedia(
        userId: userId,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      await repo.sendMessage(
        chatId: widget.chatId,
        message: SupportAttachmentType.voice.previewLabel,
        senderRole: widget.senderRole,
        attachmentType: SupportAttachmentType.voice,
        attachmentUrl: url,
        voiceDuration: duration,
      );
    });
  }

  String _mimeFromName(String name, String fallback) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.webm')) return 'audio/webm';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (_recording) {
      return Material(
        color: palette.card,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${supportDurationLabel(_recordSeconds)}  🔴 جاري التسجيل...',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: _cancelRecord,
                  child: const Text('حذف'),
                ),
                FilledButton.icon(
                  onPressed: () => _stopRecord(send: true),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('إرسال التسجيل'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: palette.card,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                key: const Key('support-attach'),
                tooltip: 'إرفاق',
                onPressed: _sending ? null : _showAttachMenu,
                icon: const Icon(Icons.attach_file_rounded),
              ),
              Expanded(
                child: TextField(
                  key: const Key('support-message-field'),
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: SupportComposer.maxLength,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendText(),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    counterText: '',
                    filled: true,
                    fillColor: palette.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('support-mic'),
                tooltip: 'تسجيل رسالة صوتية',
                onPressed: (_sending || _startingRecord) ? null : _toggleRecord,
                icon: const Icon(Icons.mic_rounded),
              ),
              IconButton.filled(
                key: const Key('support-send'),
                onPressed: _sending ? null : _sendText,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
