import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/core/widgets/resizable_columns.dart';

Future<void> _pump(WidgetTester tester, TextDirection direction) async {
  tester.view.physicalSize = const Size(1016, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: direction,
        child: const Scaffold(
          body: ResizableColumns(
            layoutId: 'test',
            columns: [
              ResizableColumn(flex: 1, minWidth: 200, child: Text('A')),
              ResizableColumn(flex: 1, minWidth: 200, child: Text('B')),
              ResizableColumn(flex: 2, minWidth: 200, child: Text('C')),
            ],
          ),
        ),
      ),
    ),
  ));
}

double _width(WidgetTester tester, String label) => tester
    .getSize(find
        .ancestor(of: find.text(label), matching: find.byType(SizedBox))
        .first)
    .width;

void main() {
  testWidgets('columns start at their flex share of the width', (
    tester,
  ) async {
    await _pump(tester, TextDirection.ltr);
    // 1016 - 2 handles × 8 = 1000 shared 1 : 1 : 2.
    expect(_width(tester, 'A'), 250);
    expect(_width(tester, 'B'), 250);
    expect(_width(tester, 'C'), 500);
  });

  testWidgets('dragging a handle moves width between its two neighbours', (
    tester,
  ) async {
    await _pump(tester, TextDirection.ltr);

    await tester.drag(
        find.byKey(const Key('test-handle-0')), const Offset(30, 0));
    await tester.pump();
    expect(_width(tester, 'A'), closeTo(280, 1));
    expect(_width(tester, 'B'), closeTo(220, 1));
    expect(_width(tester, 'C'), 500, reason: 'other columns keep theirs');
  });

  testWidgets('in RTL, dragging right widens the column to the right', (
    tester,
  ) async {
    await _pump(tester, TextDirection.rtl);
    // A is the rightmost column; its handle sits on its left.
    await tester.drag(
        find.byKey(const Key('test-handle-0')), const Offset(-30, 0));
    await tester.pump();
    expect(_width(tester, 'A'), closeTo(280, 1));
    expect(_width(tester, 'B'), closeTo(220, 1));
  });

  testWidgets('no column goes below its minimum width', (tester) async {
    await _pump(tester, TextDirection.ltr);

    await tester.drag(
        find.byKey(const Key('test-handle-0')), const Offset(400, 0));
    await tester.pump();
    expect(_width(tester, 'B'), closeTo(200, 1));
    expect(_width(tester, 'A'), closeTo(300, 1));
  });
}
