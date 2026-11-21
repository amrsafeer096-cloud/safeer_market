import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:safeer_market/core/network/resilient_realtime_stream.dart';

void main() {
  test('loads over HTTP first and resubscribes after a stream error', () async {
    var creations = 0;
    var fetches = 0;
    final controllers = <StreamController<List<int>>>[];

    final stream = resilientRealtimeStream<List<int>>(
      fetch: () async {
        fetches++;
        return [fetches];
      },
      create: () {
        creations++;
        final controller = StreamController<List<int>>();
        controllers.add(controller);
        return controller.stream;
      },
      backoff: const [
        Duration(milliseconds: 20),
        Duration(milliseconds: 20),
        Duration(milliseconds: 20),
      ],
      disconnectedPollInterval: const Duration(days: 1),
      onReconnect: () async {},
    );

    final values = <List<int>>[];
    final sub = stream.listen(values.add);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();

    expect(fetches, greaterThanOrEqualTo(1));
    expect(values.first, [1]);
    expect(creations, 1);

    controllers.last.add([9, 9]);
    await pumpEventQueue();
    expect(values.last, [9, 9]);

    controllers.last.addError(
      Exception('WebSocketChannelException: WebSocket connection failed.'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await pumpEventQueue();

    expect(creations, greaterThanOrEqualTo(2));
    // Last good list (or a fresh HTTP snapshot) stays on the stream —
    // never an error event.
    expect(values, isNotEmpty);

    await sub.cancel();
  });
}
