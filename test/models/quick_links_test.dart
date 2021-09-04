import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/quick_links.dart';

void main() {
  test("QuickLinksModel json roundtrip", () {
    final model = QuickLinksModel.fromJson({});
    final want = model.toJson();
    final got = QuickLinksModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });
}
