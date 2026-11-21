import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:safeer_market/core/network/resilient_realtime_stream.dart';

void main() {
  test('keeps the last value and resubscribes after a stream error', () async {
    var creations = 0;
    final controllers = <StreamController<List<int>>>[];

    final stream = resilientRealtimeStream<List<int>>(
      create: () {
        creations++;
        final controller = StreamController<List<int>>();
        controllers.add(controller);
        return controller.stream;
      },
      backoff: const Duration(milliseconds: 20),
      pollInterval: const Duration(days: 1),
      onReconnect: () async {},
    );

    final values = <List<int>>[];
    final sub = stream.listen(values.add);

    await pumpEventQueue();
    expect(creations, 1);
    controllers.last.add([1, 2]);
    await pumpEventQueue();
    expect(values, [
      [1, 2]
    ]);

    controllers.last.addError(Exception('Token has expired 0 seconds ago'));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await pumpEventQueue();

    expect(creations, greaterThanOrEqualTo(2));
    // Last good list is re-emitted while the new socket connects.
    expect(values.last, [1, 2]);

    controllers.last.add([1, 2, 3]);
    await pumpEventQueue();
    expect(values.last, [1, 2, 3]);

    await sub.cancel();
  });
}
