import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/tts_audio_handler.dart';
import 'package:rtchat/models/tts.dart';

void main() {
  testWidgets("TtsModel json roundtrip", (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (methodCall) {
      return null;
    });
    final handler = TtsAudioHandler();
    final model = TtsModel.fromJson(handler, {});
    final want = model.toJson();
    final got = TtsModel.fromJson(handler, model.toJson()).toJson();

    expect(got, equals(want));
  });
}
