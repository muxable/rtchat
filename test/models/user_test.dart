import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/user.dart';

void main() {
  group("normalizeLanguageCode", () {
    test("supported codes map to themselves", () {
      for (final code in ["en", "es", "fr", "de", "ja", "ko", "zh", "uk"]) {
        expect(UserModel.normalizeLanguageCode(code), code);
      }
    });

    test("zh-Hant maps to zh", () {
      expect(UserModel.normalizeLanguageCode("zh-Hant"), "zh");
    });

    test("unknown, null and differently-cased codes fall back to en", () {
      expect(UserModel.normalizeLanguageCode("xx"), "en");
      expect(UserModel.normalizeLanguageCode(null), "en");
      expect(UserModel.normalizeLanguageCode("FR"), "en");
      expect(UserModel.normalizeLanguageCode("other"), "en");
    });
  });
}
