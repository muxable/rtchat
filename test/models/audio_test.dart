import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'com.rtirl.chat/audio',
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (call) async => true,
      );
    }
  });

  test("AudioModel json roundtrip", () {
    final model = AudioModel.fromJson({});
    final want = model.toJson();
    final got = AudioModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });

  test("signed out users only hear sources from settings", () {
    final model = AudioModel.fromJson({"isAlwaysEnabled": true});
    expect(model.hostChannel, isNull);
    expect(model.enabled, isFalse);

    model.isSettingsVisible = true;
    expect(model.enabled, isTrue);
  });

  test("a refused audio service start is retried on resume", () async {
    final binding = TestWidgetsFlutterBinding.instance;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('com.rtirl.chat/audio');
    var refuse = true;
    final sets = <List<Object?>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'set') {
        return true;
      }
      sets.add((call.arguments as Map)['urls']);
      return !refuse;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(channel, (call) async => true),
    );

    final model = AudioModel.fromJson({
      "sources": [
        {"name": "a", "url": "https://example.com/a", "muted": false},
      ],
    });
    model.isSettingsVisible = true;
    await pumpEventQueue();
    expect(sets, [
      ["https://example.com/a"],
    ]);

    refuse = false;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await pumpEventQueue();
    expect(sets, hasLength(2));
    expect(sets.last, ["https://example.com/a"]);

    // a successful sync isn't repeated on the next resume.
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await pumpEventQueue();
    expect(sets, hasLength(2));
  });

  test("refreshAllSources reloads once and counts active sources", () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('com.rtirl.chat/audio');
    final reloads = <Object?>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'reload') {
        reloads.add(call.arguments);
      }
      return true;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(channel, (call) async => true),
    );

    final model = AudioModel.fromJson({
      "sources": [
        {"name": "a", "url": "https://example.com/a", "muted": false},
        {"name": "b", "url": "https://example.com/b", "muted": false},
        {"name": "c", "url": "https://example.com/c", "muted": true},
      ],
    });

    expect(await model.refreshAllSources(), 0);
    expect(reloads, isEmpty);

    model.isSettingsVisible = true;
    expect(await model.refreshAllSources(), 2);
    expect(reloads, [null]);
  });
}
