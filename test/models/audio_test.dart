import 'package:flutter/services.dart';
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
          MethodChannel(channel), (call) async => true);
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
}
