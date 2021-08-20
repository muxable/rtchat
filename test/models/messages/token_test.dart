import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/tokens.dart';

void main() {
  group("compact", () {
    test('repeats should compact', () {
      List<MessageToken> tokens = [
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken("raid"),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken("raid"),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken("raid"),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken("raid"),
      ];

      final compacted = tokens.compacted;

      expect(compacted.multiplicity, equals(4));
      expect(
          compacted.tokens,
          orderedEquals([
            EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
            const TextToken("raid"),
          ]));
    });

    test('late non-repeat doesn\'t tokenize', () {
      List<MessageToken> tokens = [
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken("raid"),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken("raid"),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken("raid2"),
      ];

      final compacted = tokens.compacted;

      expect(compacted.multiplicity, equals(1));
      expect(compacted.tokens, orderedEquals(tokens));
    });

    test('repeated text doesn\'t tokenize', () {
      List<MessageToken> tokens = [
        const TextToken("raid raid raid"),
      ];

      final compacted = tokens.compacted;

      expect(compacted.multiplicity, equals(1));
      expect(compacted.tokens, orderedEquals(tokens));
    });
  });
}
