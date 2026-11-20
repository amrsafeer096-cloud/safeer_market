import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/rewards_providers.dart';

/// Dark-blue «رصيدك الحالي» card. Pulses and counts up when points rise.
class LoyaltyPointsBanner extends ConsumerStatefulWidget {
  const LoyaltyPointsBanner({
    super.key,
    required this.signedIn,
    this.points,
    this.loading = false,
    this.error = false,
    this.onRetry,
    this.pulseListenable,
  });

  final bool signedIn;

  /// Optional override (e.g. mid-flight count-up). Defaults to provider.
  final int? points;
  final bool loading;
  final bool error;
  final VoidCallback? onRetry;

  /// External pulse (1.0 → 1.12 → 1.0) driven by flying-coin arrivals.
  final Animation<double>? pulseListenable;

  @override
  ConsumerState<LoyaltyPointsBanner> createState() =>
      _LoyaltyPointsBannerState();
}

class _LoyaltyPointsBannerState extends ConsumerState<LoyaltyPointsBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _autoPulse;
  int? _displayPoints;
  int? _fromPoints;

  @override
  void initState() {
    super.initState();
    _autoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _displayPoints = widget.points;
  }

  @override
  void didUpdateWidget(covariant LoyaltyPointsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.points;
    final prev = oldWidget.points;
    if (next != null && prev != null && next > prev) {
      _fromPoints = prev;
      _displayPoints = next;
      if (widget.pulseListenable == null) {
        _autoPulse.forward(from: 0);
      }
    } else if (next != null) {
      _displayPoints = next;
      _fromPoints = null;
    }
  }

  @override
  void dispose() {
    _autoPulse.dispose();
    super.dispose();
  }

  void _onProviderPoints(int next) {
    final previous = _displayPoints;
    if (previous != null && next > previous) {
      setState(() {
        _fromPoints = previous;
        _displayPoints = next;
      });
      if (widget.pulseListenable == null) {
        _autoPulse.forward(from: 0);
      }
    } else if (_displayPoints != next) {
      setState(() {
        _displayPoints = next;
        _fromPoints = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(loyaltyPointsProvider);

    ref.listen<AsyncValue<int>>(loyaltyPointsProvider, (previous, next) {
      if (widget.points != null) return;
      final value = next.valueOrNull;
      if (value == null) return;
      _onProviderPoints(value);
    });

    final resolvedPoints = widget.points ?? async.valueOrNull ?? _displayPoints;
    final loading = widget.loading ||
        (widget.signedIn &&
            resolvedPoints == null &&
            async.isLoading);
    final error = widget.error ||
        (widget.signedIn && resolvedPoints == null && async.hasError);
    final onRetry = widget.onRetry ??
        () => ref.read(loyaltyPointsProvider.notifier).refresh();

    final pulse = widget.pulseListenable ??
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 1.12)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 45,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 1.12, end: 1.0)
                .chain(CurveTween(curve: Curves.easeIn)),
            weight: 55,
          ),
        ]).animate(_autoPulse);

    return ScaleTransition(
      scale: pulse,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loyaltyCurrentBalance,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (!widget.signedIn)
              Text(
                l10n.loyaltySignInToSeePoints,
                style: TextStyle(
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              )
            else if (loading)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimary,
                ),
              )
            else if (error || resolvedPoints == null)
              TextButton(
                onPressed: onRetry,
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.onPrimary),
                child: Text(l10n.loyaltyLoadFailedRetry),
              )
            else
              _PointsCounter(
                from: _fromPoints ?? resolvedPoints,
                to: _displayPoints ?? resolvedPoints,
                animate: _fromPoints != null &&
                    (_displayPoints ?? 0) > (_fromPoints ?? 0),
              ),
          ],
        ),
      ),
    );
  }
}

class _PointsCounter extends StatelessWidget {
  const _PointsCounter({
    required this.from,
    required this.to,
    required this.animate,
  });

  final int from;
  final int to;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!animate || from == to) {
      return Text(
        l10n.rewardsPointsCount(to),
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('points-$from-$to'),
      tween: Tween(begin: from.toDouble(), end: to.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          l10n.rewardsPointsCount(value.round()),
          style: const TextStyle(
            color: AppColors.onPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }
}
