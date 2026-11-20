import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only notification toggles until preferences are stored remotely.
final notificationPrefsProvider =
    StateProvider<({bool app, bool sms})>((ref) => (app: true, sms: false));
