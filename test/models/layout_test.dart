import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/layout.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = [];

  tearDown(() {
    log.clear();
  });

  testWidgets("LayoutModel json roundtrip", (tester) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) {
      log.add(methodCall);
      return null;
    });

    final model = LayoutModel.fromJson({});

    final want = model.toJson();
    final got = LayoutModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });

  testWidgets("setting orientation propagates to system", (tester) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) {
      log.add(methodCall);
      return null;
    });

    final model = LayoutModel.fromJson({});

    expect(log, hasLength(0));

    model.preferredOrientation = PreferredOrientation.portrait;

    expect(log, hasLength(1));
    expect(
        log.last,
        isMethodCall(
          'SystemChrome.setPreferredOrientations',
          arguments: [
            "DeviceOrientation.portraitUp",
            "DeviceOrientation.portraitDown"
          ],
        ));

    model.preferredOrientation = PreferredOrientation.landscape;

    expect(log, hasLength(2));
    expect(
        log.last,
        isMethodCall(
          'SystemChrome.setPreferredOrientations',
          arguments: [
            "DeviceOrientation.landscapeLeft",
            "DeviceOrientation.landscapeRight"
          ],
        ));

    model.preferredOrientation = PreferredOrientation.system;

    expect(log, hasLength(3));
    expect(
        log.last,
        isMethodCall(
          'SystemChrome.setPreferredOrientations',
          arguments: [],
        ));
  });
}
