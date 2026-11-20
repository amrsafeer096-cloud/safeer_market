import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// System / Dark / Light as three cards, each with a small mock-up of the
/// app in that mode and a radio dot for the active one. Saves the choice.
class ThemeSelectorWidget extends ConsumerWidget {
  const ThemeSelectorWidget({super.key});

  /// The cards never get wider than this, however wide the screen.
  static const maxWidth = 440.0;

  /// From this screen width the cards use their compact size.
  static const compactBreakpoint = 700.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(themeModeProvider);
    void select(ThemeMode mode) =>
        ref.read(themeModeProvider.notifier).state = mode;

    // Desktop web: a narrow, compact trio instead of three huge cards.
    final compact = MediaQuery.sizeOf(context).width >= compactBreakpoint;

    final options = Row(
      children: [
        for (final (mode, label) in [
          (ThemeMode.system, l10n.themeSystem),
          (ThemeMode.dark, l10n.themeDark),
          (ThemeMode.light, l10n.themeLight),
        ]) ...[
          if (mode != ThemeMode.system) SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: _ThemeOption(
              mode: mode,
              label: label,
              selected: current == mode,
              compact: compact,
              onTap: () => select(mode),
            ),
          ),
        ],
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: options,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final mockup = switch (mode) {
      ThemeMode.light => const _MockScreen(palette: _MockPalette.light),
      ThemeMode.dark => const _MockScreen(palette: _MockPalette.dark),
      ThemeMode.system => const Stack(
          fit: StackFit.expand,
          children: [
            _MockScreen(palette: _MockPalette.light),
            ClipPath(
              clipper: _DiagonalClipper(),
              child: _MockScreen(palette: _MockPalette.dark),
            ),
          ],
        ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(compact ? 4 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            border: Border.all(
              color: selected
                  ? accent
                  : context.palette.muted.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: compact ? 1.15 : 0.78,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 9 : 12),
                  child: mockup,
                ),
              ),
              SizedBox(height: compact ? 5 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RadioDot(
                    selected: selected,
                    color: accent,
                    size: compact ? 15 : 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 0 : 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({
    required this.selected,
    required this.color,
    required this.size,
  });

  final bool selected;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              selected ? color : context.palette.muted.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: selected ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _MockPalette {
  const _MockPalette({
    required this.background,
    required this.bar,
    required this.block,
    required this.line,
  });

  static const light = _MockPalette(
    background: Color(0xFFFFFFFF),
    bar: AppColors.primary,
    block: Color(0xFFEEF1F5),
    line: Color(0xFFD9DEE6),
  );

  static const dark = _MockPalette(
    background: Color(0xFF1A1C20),
    bar: Color(0xFF2C3036),
    block: Color(0xFF2A2D33),
    line: Color(0xFF3A3E46),
  );

  final Color background;
  final Color bar;
  final Color block;
  final Color line;
}

/// A tiny phone screen: app bar, a profile row, then two content cards.
class _MockScreen extends StatelessWidget {
  const _MockScreen({required this.palette});

  final _MockPalette palette;

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, {double height = 6}) => FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: palette.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );

    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: palette.bar,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: palette.line,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(child: bar(0.8)),
              ],
            ),
            const SizedBox(height: 7),
            for (final widthFactor in [0.9, 0.6]) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: palette.block,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [bar(widthFactor, height: 4)],
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ],
        ),
      ),
    );
  }
}

/// The lower-right half, below the top-right to bottom-left diagonal.
class _DiagonalClipper extends CustomClipper<Path> {
  const _DiagonalClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) => false;
}
