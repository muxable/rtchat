import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("AudioModel json roundtrip", () {
    final model = AudioModel.fromJson({});
    final want = model.toJson();
    final got = AudioModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });
}
