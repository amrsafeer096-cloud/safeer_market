import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import 'whatsapp_icon.dart';

/// Far bottom-right circular support speed dial (WhatsApp + live chat).
class HomeSupportSpeedDial extends StatefulWidget {
  const HomeSupportSpeedDial({super.key});

  static const closedColor = Color(0xFF0D3B66);
  static const openColor = Color(0xFFE53935);
  static final whatsAppUri = Uri.parse('https://wa.me/201066208383');

  @override
  State<HomeSupportSpeedDial> createState() => _HomeSupportSpeedDialState();
}

class _HomeSupportSpeedDialState extends State<HomeSupportSpeedDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _expand = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isAnimating) return;
    if (_controller.value > 0.01) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  Future<void> _openWhatsApp() async {
    await _controller.reverse();
    final uri = HomeSupportSpeedDial.whatsAppUri;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _openLiveChat() {
    _controller.reverse();
    context.push(AppRoutes.supportChat);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizeTransition(
            sizeFactor: _expand,
            axis: Axis.vertical,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _expand,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleAction(
                      tooltip: l10n.supportWhatsApp,
                      color: const Color(0xFF25D366),
                      onTap: _openWhatsApp,
                      child: const WhatsAppIcon(size: 26),
                    ),
                    const SizedBox(height: 10),
                    _CircleAction(
                      tooltip: l10n.supportLiveChat,
                      color: HomeSupportSpeedDial.closedColor,
                      onTap: _openLiveChat,
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Tooltip(
            message: l10n.talkToUs,
            child: AnimatedBuilder(
              animation: _expand,
              builder: (context, _) {
                final open = _expand.value > 0.5;
                final color = Color.lerp(
                  HomeSupportSpeedDial.closedColor,
                  HomeSupportSpeedDial.openColor,
                  _expand.value,
                )!;
                return Material(
                  color: color,
                  elevation: 8,
                  shadowColor: color.withValues(alpha: 0.4),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggle,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        // Never rotate into a “+” — swap to a real close icon.
                        open
                            ? Icons.close_rounded
                            : Icons.headset_mic_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        elevation: 5,
        shadowColor: color.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
