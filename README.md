# Safeer Market

Arabic (RTL) grocery delivery app built with Flutter, Clean Architecture, Riverpod, GoRouter, and Supabase.

## Prerequisites

This machine did not have the Flutter SDK or Git on PATH when the project was scaffolded. Install [Flutter](https://docs.flutter.dev/get-started/install) (Git is required by the SDK), then from this folder:

```bash
flutter create . --project-name safeer_market --org com.safeermarket --platforms android,ios,web,windows
flutter pub get
flutter run
```

Configure Supabase in `lib/core/config/app_config.dart` (or via `--dart-define`) before enabling backend calls.

Default locale is Arabic (`ar`) with RTL and the **Cairo** typeface.
