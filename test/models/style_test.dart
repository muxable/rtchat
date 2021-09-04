import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/style.dart';

void main() {
  test("StyleModel json roundtrip", () {
    final model = StyleModel.fromJson({});
    final want = model.toJson();
    final got = StyleModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });
}
