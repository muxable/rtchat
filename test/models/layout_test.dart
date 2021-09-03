import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = [];

  setUp(() {
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });
  });

  tearDown(() {
    SystemChannels.platform.setMockMethodCallHandler(null);
    log.clear();
  });

  test("LayoutModel json roundtrip", () {
    final model = LayoutModel.fromJson({});

    final want = model.toJson();
    final got = LayoutModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });

  test("setting orientation propagates to system", () {
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
