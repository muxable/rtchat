import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/layout.dart';

void main() {
  test("LayoutModel json roundtrip", () {
    final model = LayoutModel.fromJson({});
    final want = model.toJson();
    final got = LayoutModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });
}
