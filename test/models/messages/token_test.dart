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

      expect(
          tokens.compacted,
          orderedEquals([
            CompactedToken([
              EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
              const TextToken("raid"),
            ], 4),
          ]));
    });

    test('space separators are ignored', () {
      List<MessageToken> tokens = [
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken(" "),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken(" "),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken(" "),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
      ];

      expect(
          tokens.compacted,
          orderedEquals([
            CompactedToken([
              EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
            ], 4),
          ]));
    });

    test('text separators are not ignored', () {
      List<MessageToken> tokens = [
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken(" RAID "),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken(" RAID "),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
        const TextToken(" RAID "),
        EmoteToken(url: Uri.parse("https://mugit.lol"), code: "moo"),
      ];

      expect(tokens.compacted, orderedEquals(tokens));
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

      expect(tokens.compacted, orderedEquals(tokens));
    });

    test('repeated text doesn\'t tokenize', () {
      List<MessageToken> tokens = [
        const TextToken("raid raid raid"),
      ];

      expect(tokens.compacted, orderedEquals(tokens));
    });
  });
}
