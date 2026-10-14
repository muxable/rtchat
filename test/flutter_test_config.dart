import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

// Every widget test fails if it leaves an undisposed disposable behind
// (controllers, notifiers, focus nodes, images...).
FutureOr<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
      .withTrackedAll()
      .withIgnored(createdByTestHelpers: true);
  await testMain();
}
