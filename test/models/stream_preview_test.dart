import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/stream_preview.dart';

void main() {
  test("defaults", () {
    final model = StreamPreviewModel.fromJson({});
    expect(model.isHighDefinition, isFalse);
    expect(model.volume, 0);
    expect(model.showBatteryPrompt, isTrue);
  });

  test("json round trip", () {
    final model = StreamPreviewModel.fromJson({})
      ..isHighDefinition = true
      ..volume = 42
      ..showBatteryPrompt = false;
    final decoded = StreamPreviewModel.fromJson(model.toJson());
    expect(decoded.isHighDefinition, isTrue);
    expect(decoded.volume, 42);
    expect(decoded.showBatteryPrompt, isFalse);
  });

  test("setters notify listeners", () {
    final model = StreamPreviewModel.fromJson({});
    var count = 0;
    model.addListener(() => count++);
    model.isHighDefinition = true;
    model.volume = 10;
    model.showBatteryPrompt = false;
    expect(count, 3);
  });
}
