import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/tts_audio_handler.dart';
import 'package:rtchat/models/tts.dart';

void main() {
  test("TtsModel json roundtrip", () {
    final handler = TtsAudioHandler();
    final model = TtsModel.fromJson(handler, {});
    final want = model.toJson();
    final got = TtsModel.fromJson(handler, model.toJson()).toJson();

    expect(got, equals(want));
  });
}
