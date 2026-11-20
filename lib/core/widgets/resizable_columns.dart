import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_palette.dart';

/// One column of [ResizableColumns]: starts at [flex] parts of the width and
/// can't be dragged narrower than [minWidth].
class ResizableColumn {
  const ResizableColumn({
    required this.child,
    this.flex = 1,
    this.minWidth = 180,
  });

  final Widget child;
  final double flex;
  final double minWidth;
}

/// Each layout's column widths, as fractions of the space they share, so a
/// width the user dragged survives rebuilds and switching orders. Null until
/// first dragged.
final resizableColumnFractionsProvider =
    StateProvider.family<List<double>?, String>((ref, layoutId) => null);

/// Columns side by side with a drag handle between each pair: dragging a
/// handle widens one neighbour and narrows the other.
class ResizableColumns extends ConsumerWidget {
  const ResizableColumns({
    super.key,
    required this.layoutId,
    required this.columns,
  });

  static const handleWidth = 8.0;

  /// Columns with the same [layoutId] share their dragged widths.
  final String layoutId;
  final List<ResizableColumn> columns;

  List<double> _initialFractions() {
    final total = columns.fold<double>(0, (sum, column) => sum + column.flex);
    return [for (final column in columns) column.flex / total];
  }

  List<double> _fractions(List<double>? stored) =>
      stored != null && stored.length == columns.length
          ? stored
          : _initialFractions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fractions =
        _fractions(ref.watch(resizableColumnFractionsProvider(layoutId)));
    // A drag to the right moves the handle right: in RTL that is towards the
    // earlier column.
    final direction =
        Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

    return LayoutBuilder(builder: (context, constraints) {
      final available =
          constraints.maxWidth - handleWidth * (columns.length - 1);
      if (available <= 0) return const SizedBox.shrink();

      void drag(int index, double dx) {
        // Several pointer moves can arrive before the next build: start from
        // the latest widths, not the ones this build was laid out with.
        final provider = resizableColumnFractionsProvider(layoutId);
        final current = [..._fractions(ref.read(provider))];
        final delta = dx * direction / available;
        final minA = columns[index].minWidth / available;
        final minB = columns[index + 1].minWidth / available;
        final low = minA - current[index];
        final high = current[index + 1] - minB;
        if (low > high) return;
        final applied = delta.clamp(low, high);
        current[index] += applied;
        current[index + 1] -= applied;
        ref.read(provider.notifier).state = current;
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            SizedBox(
              width: fractions[i] * available,
              child: columns[i].child,
            ),
            if (i < columns.length - 1)
              _ColumnHandle(
                key: Key('$layoutId-handle-$i'),
                onDrag: (dx) => drag(i, dx),
              ),
          ],
        ],
      );
    });
  }
}

class _ColumnHandle extends StatefulWidget {
  const _ColumnHandle({super.key, required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  State<_ColumnHandle> createState() => _ColumnHandleState();
}

class _ColumnHandleState extends State<_ColumnHandle> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The handle follows the pointer from the first pixel, touch slop
        // included.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (_) => setState(() => _active = true),
        onHorizontalDragUpdate: (details) => widget.onDrag(details.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _active = false),
        child: SizedBox(
          width: ResizableColumns.handleWidth,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _active ? 4 : 1,
              decoration: BoxDecoration(
                color: _active ? palette.accent : palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
