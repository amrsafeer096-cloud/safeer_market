import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/magazine.dart';

/// Reads [magazine]'s PDF inside the app one page at a time: swipe
/// sideways like a gallery, or use the arrows on either side.
class MagazineReaderScreen extends StatefulWidget {
  const MagazineReaderScreen({super.key, required this.magazine});

  final Magazine magazine;

  static Future<void> open(BuildContext context, Magazine magazine) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MagazineReaderScreen(magazine: magazine),
      ),
    );
  }

  @override
  State<MagazineReaderScreen> createState() => _MagazineReaderScreenState();
}

class _MagazineReaderScreenState extends State<MagazineReaderScreen>
    with SingleTickerProviderStateMixin {
  /// How far (as a fraction of the width) a page slides while turning.
  static const _slide = 0.25;

  final _controller = PdfViewerController();

  /// Drives an arrow-tap page turn: the current page slides out towards the
  /// tapped side's opposite and fades, the viewer jumps at the midpoint,
  /// then the new page slides in from the tapped side. The viewer's own
  /// `nextPage()` / `previousPage()` jump without any animation.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  )..addListener(_jumpAtMidpoint);

  int _page = 1;
  int _pageCount = 0;
  bool _loadFailed = false;

  /// +1 for next, -1 for previous.
  int _turnDelta = 1;
  int _turnTarget = 1;
  bool _jumped = true;

  bool get _loaded => _pageCount > 0;
  bool get _canGoBack => _loaded && _page > 1;
  bool get _canGoForward => _loaded && _page < _pageCount;

  @override
  void dispose() {
    _turn.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _turnPage(int delta) {
    final target = _page + delta;
    if (_turn.isAnimating || target < 1 || target > _pageCount) return;
    _turnDelta = delta;
    _turnTarget = target;
    _jumped = false;
    _turn.forward(from: 0);
  }

  void _jumpAtMidpoint() {
    if (_jumped || _turn.value < 0.5) return;
    _jumped = true;
    _controller.jumpToPage(_turnTarget);
  }

  Widget _animatedTurn(BuildContext context, Widget? child) {
    final value = _turn.value;
    final leaving = value < 0.5;
    final t = Curves.easeInOut.transform(
      leaving ? value * 2 : (value - 0.5) * 2,
    );
    // Next (right arrow): out to the left, in from the right; previous is
    // the mirror image.
    final dx =
        leaving ? -_turnDelta * _slide * t : _turnDelta * _slide * (1 - t);
    return FractionalTranslation(
      translation: Offset(dx, 0),
      child: Opacity(opacity: leaving ? 1 - t : t, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.magazine.pdfUrl.trim();
    final l10n = AppLocalizations.of(context)!;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        appBar: AppBar(
          title: Text(
            widget.magazine.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
        body: url.isEmpty || _loadFailed
            ? _ReaderMessage(
                message:
                    _loadFailed ? l10n.magazineOpenFailed : l10n.magazineNoPdf,
              )
            // Left-to-right in every locale so the right arrow is always
            // "next", the left arrow "previous", and a swipe to the left
            // brings in the next page from the right, matching the arrows.
            : Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRect(
                        child: AnimatedBuilder(
                          animation: _turn,
                          builder: _animatedTurn,
                          child: SfPdfViewer.network(
                            url,
                            controller: _controller,
                            scrollDirection: PdfScrollDirection.horizontal,
                            pageLayoutMode: PdfPageLayoutMode.single,
                            canShowScrollHead: false,
                            canShowPaginationDialog: false,
                            onDocumentLoaded: (details) => setState(() {
                              _pageCount = details.document.pages.count;
                              _page =
                                  _controller.pageNumber.clamp(1, _pageCount);
                            }),
                            onPageChanged: (details) =>
                                setState(() => _page = details.newPageNumber),
                            onDocumentLoadFailed: (details) => setState(
                              () => _loadFailed = true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!_loaded)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PageArrow(
                        tooltip: l10n.magazinePreviousPage,
                        icon: Icons.chevron_left_rounded,
                        onPressed: _canGoBack ? () => _turnPage(-1) : null,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _PageArrow(
                        tooltip: l10n.magazineNextPage,
                        icon: Icons.chevron_right_rounded,
                        onPressed: _canGoForward ? () => _turnPage(1) : null,
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: _loaded && !_loadFailed
            ? SafeArea(
                child: Container(
                  height: 48,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Text(
                    l10n.magazinePageOf('$_page', '$_pageCount'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 28,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.2),
          disabledForegroundColor: Colors.white38,
          minimumSize: const Size.square(44),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: Colors.white54,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
