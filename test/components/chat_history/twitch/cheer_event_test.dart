import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/chat_history/twitch/cheer_event.dart';

void main() {
  final bit_10 =
      Uri.parse("https://cdn.twitchalerts.com/twitch-bits/images/hd/10.gif");
  final bit_100 =
      Uri.parse("https://cdn.twitchalerts.com/twitch-bits/images/hd/100.gif");
  final bit_1000 =
      Uri.parse("https://cdn.twitchalerts.com/twitch-bits/images/hd/1000.gif");
  final bit_5000 =
      Uri.parse("https://cdn.twitchalerts.com/twitch-bits/images/hd/5000.gif");
  final bit_10000 =
      Uri.parse("https://cdn.twitchalerts.com/twitch-bits/images/hd/10000.gif");
  final bit_100000 = Uri.parse(
      "https://cdn.twitchalerts.com/twitch-bits/images/hd/100000.gif");
  group('bits_10', () {
    test('cheer 1 bits', () {
      final actual = getCorrespondingImageUrl(1);
      expect(actual, bit_10);
    });
    test('cheer 10 bits', () {
      final actual = getCorrespondingImageUrl(10);
      expect(actual, bit_10);
    });
    test('cheer 50 bits', () {
      final actual = getCorrespondingImageUrl(50);
      expect(actual, bit_10);
    });
    test('cheer 78 bits', () {
      final actual = getCorrespondingImageUrl(78);
      expect(actual, bit_10);
    });
  });

  group("bits_100", () {
    test('cheer 100 bits', () {
      final actual = getCorrespondingImageUrl(100);
      expect(actual, bit_100);
    });

    test('cheer 300 bits', () {
      final actual = getCorrespondingImageUrl(300);
      expect(actual, bit_100);
    });

    test('cheer 488 bits', () {
      final actual = getCorrespondingImageUrl(488);
      expect(actual, bit_100);
    });
    test('cheer 999 bits', () {
      final actual = getCorrespondingImageUrl(999);
      expect(actual, bit_100);
    });
  });

  group("bits_1000", () {
    test('cheer 1000 bits', () {
      final actual = getCorrespondingImageUrl(1000);
      expect(actual, bit_1000);
    });
    test('cheer 1234 bits', () {
      final actual = getCorrespondingImageUrl(1234);
      expect(actual, bit_1000);
    });
    test('cheer 3333 bits', () {
      final actual = getCorrespondingImageUrl(3333);
      expect(actual, bit_1000);
    });
    test('cheer 4999 bits', () {
      final actual = getCorrespondingImageUrl(4999);
      expect(actual, bit_1000);
    });
  });

  group("bits_5000", () {
    test('cheer 5000 bits', () {
      final actual = getCorrespondingImageUrl(5000);
      expect(actual, bit_5000);
    });
    test('cheer 5001 bits', () {
      final actual = getCorrespondingImageUrl(5001);
      expect(actual, bit_5000);
    });
    test('cheer 7133 bits', () {
      final actual = getCorrespondingImageUrl(7133);
      expect(actual, bit_5000);
    });
    test('cheer 9999 bits', () {
      final actual = getCorrespondingImageUrl(9999);
      expect(actual, bit_5000);
    });
  });

  group("bits_10000", () {
    test('cheer 10000 bits', () {
      final actual = getCorrespondingImageUrl(10000);
      expect(actual, bit_10000);
    });

    test('cheer 32134 bits', () {
      final actual = getCorrespondingImageUrl(32134);
      expect(actual, bit_10000);
    });
    test('cheer 59999 bits', () {
      final actual = getCorrespondingImageUrl(59999);
      expect(actual, bit_10000);
    });
    test('cheer 99999 bits', () {
      final actual = getCorrespondingImageUrl(99999);
      expect(actual, bit_10000);
    });
  });

  group("bits_100000", () {
    test('cheer 100000 bits', () {
      final actual = getCorrespondingImageUrl(100000);
      expect(actual, bit_100000);
    });
    test('cheer 100001 bits', () {
      final actual = getCorrespondingImageUrl(100001);
      expect(actual, bit_100000);
    });
    test('cheer 999999 bits', () {
      final actual = getCorrespondingImageUrl(999999);
      expect(actual, bit_100000);
    });
    test('cheer 314123432 bits', () {
      final actual = getCorrespondingImageUrl(314123432);
      expect(actual, bit_100000);
    });
  });
}
