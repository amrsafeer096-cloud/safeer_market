import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';

const homeTabIndex = 0;
const searchTabIndex = 1;
const cartTabIndex = 2;
const walletTabIndex = 3;
const moreTabIndex = 4;

final homeTabIndexProvider = StateProvider<int>((ref) => homeTabIndex);

/// Returns to the home route with the الرئيسية tab selected.
void goToHomeTab(BuildContext context, WidgetRef ref) {
  ref.read(homeTabIndexProvider.notifier).state = homeTabIndex;
  context.go(AppRoutes.home);
}
