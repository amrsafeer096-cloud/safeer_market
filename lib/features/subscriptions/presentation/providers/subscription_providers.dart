import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/paymob_service.dart';
import '../../domain/subscription.dart';

final paymobServiceProvider = Provider<PaymobService>((ref) {
  return PaymobService(ref.watch(supabaseClientProvider));
});

/// The signed-in user's plan, from `profiles`; free for guests. Kept alive at
/// the app root ([subscriptionAutoRefreshProvider]), so it is read on start,
/// on every sign-in, and again whenever the app comes back to the foreground.
final subscriptionProvider = FutureProvider<Subscription>((ref) async {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return Subscription.free;
  return ref.watch(paymobServiceProvider).fetchSubscription(userId);
});

/// Whether the plan in memory is an active paid one (Prime or Pro/VIP).
/// False while it loads, for guests, and when it can't be read.
final hasPaidPlanProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).valueOrNull?.isFree() == false;
});

/// Re-reads the plan when the app returns to the foreground — e.g. from the
/// Paymob browser tab, after the webhook may have changed it. Watch once at
/// the app root.
final subscriptionAutoRefreshProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () => ref.invalidate(subscriptionProvider),
  );
  ref.onDispose(listener.dispose);
});

/// Reads the plan again from `profiles` (and the profile with it), e.g.
/// right after a payment.
Future<Subscription> refreshSubscription(WidgetRef ref) {
  ref.invalidate(userProfileProvider);
  return ref.refresh(subscriptionProvider.future);
}

/// Whether the signed-in user has an active paid plan. When the plan in
/// memory is free it is read once more first, so a plan the payment webhook
/// set since the last read still counts. False when it can't be read.
Future<bool> hasActivePaidPlan(WidgetRef ref) async {
  try {
    final cached = await ref.read(subscriptionProvider.future);
    if (!cached.isFree()) return true;
    if (!ref.read(isSignedInProvider)) return false;
    return !(await refreshSubscription(ref)).isFree();
  } catch (error) {
    debugPrint('Reading the subscription failed: $error');
    return false;
  }
}

/// Host of the deep link the paymob-webhook function sends the customer back
/// to: io.supabase.safeermarket://payment-result?status=…&transaction_id=….
/// Must match the intent filter in AndroidManifest.xml.
const paymentReturnHost = 'payment-result';

/// Deep links back from Paymob checkout.
final paymentReturnLinksProvider = StreamProvider<Uri>((ref) {
  return AppLinks().uriLinkStream.where((uri) => uri.host == paymentReturnHost);
});

final paymentPageProvider = Provider<PaymentPage>((ref) => const PaymentPage());

/// Paymob checkout in an in-app browser tab (Custom Tabs on Android, Safari
/// View Controller on iOS). Only `http`/`https` URLs are opened in-app.
class PaymentPage {
  const PaymentPage();

  Future<bool> open(Uri url) {
    final scheme = url.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return Future<bool>.value(false);
    }
    return launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  /// iOS keeps the Safari sheet over the app after the return deep link;
  /// Android's tab is closed by the deep link itself (singleTask activity).
  Future<void> close() async {
    try {
      await closeInAppWebView();
    } catch (_) {
      // Nothing open, or the platform can't close it.
    }
  }
}
