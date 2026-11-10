import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/qr_code.dart';

void main() {
  test("defaults to the first gradient", () {
    final model = QRModel.fromJson({});
    expect(model.currentGradient, gradientMap.values.first);
    expect(model.toJson(), {"currentGradient": 0});
  });

  test("changeGradient cycles and wraps around", () {
    final model = QRModel.fromJson({});
    var count = 0;
    model.addListener(() => count++);
    final keys = gradientMap.keys.toList();
    for (var i = 1; i < keys.length; i++) {
      model.changeGradient();
      expect(model.currentGradient, gradientMap[keys[i]]);
    }
    model.changeGradient();
    expect(model.currentGradient, gradientMap[keys.first]);
    expect(count, keys.length);
  });

  test("json round trip", () {
    final model =
        QRModel.fromJson({})
          ..changeGradient()
          ..changeGradient();
    final decoded = QRModel.fromJson(model.toJson());
    expect(decoded.toJson(), {"currentGradient": 2});
    expect(decoded.currentGradient, model.currentGradient);
  });
}
