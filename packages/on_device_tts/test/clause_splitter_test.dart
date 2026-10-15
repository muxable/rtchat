import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  List<String> split(String text) => const ClauseSplitter().split(text);

  test('splits after clause punctuation followed by a space', () {
    expect(
        split('Muxfd said: hello chat, thanks for the follow! How are you?'), [
      'Muxfd said:',
      'hello chat,',
      'thanks for the follow!',
      'How are you?'
    ]);
    expect(split('Daisy said POGGERS that clutch was insane'),
        ['Daisy said POGGERS that clutch was insane']);
    expect(split('   '), isEmpty);
  });

  test('keeps runs of punctuation and closing quotes with their clause', () {
    expect(split('Are you serious?! I cannot believe it...  maybe tomorrow'),
        ['Are you serious?!', 'I cannot believe it...', 'maybe tomorrow']);
    expect(split('She yelled "watch out!" and then it exploded'),
        ['She yelled "watch out!"', 'and then it exploded']);
  });

  test('does not split numbers, hosts or emoticons', () {
    expect(split('we hit 1,000 followers at 10:30, patch 3.5 is out'),
        ['we hit 1,000 followers at 10:30,', 'patch 3.5 is out']);
    expect(split('check out clips.twitch.tv later :) see you next time'),
        ['check out clips.twitch.tv later :) see you next time']);
  });

  test('does not split after abbreviations or initials', () {
    expect(split('I talked to Dr. Smith, e.g. about J. R. R. Tolkien'),
        ['I talked to Dr. Smith,', 'e.g. about J. R. R. Tolkien']);
  });

  test('joins tiny fragments to a neighbour', () {
    expect(split('Hi, how is everyone doing today?'),
        ['Hi, how is everyone doing today?']);
    expect(split('That was such a clean clutch, GG!'),
        ['That was such a clean clutch, GG!']);
    expect(split('GG!'), ['GG!']);
    expect(const ClauseSplitter(minLetters: 0).split('Hi, there.'),
        ['Hi,', 'there.']);
  });

  test('splits CJK, Arabic and Hindi punctuation without spaces', () {
    expect(split('こんにちは皆さん、今日の配信へようこそ。楽しんでいってください！'),
        ['こんにちは皆さん、', '今日の配信へようこそ。', '楽しんでいってください！']);
    expect(split('مرحبا بالجميع، شكرا على المتابعة'),
        ['مرحبا بالجميع،', 'شكرا على المتابعة']);
    expect(split('सभी को नमस्कार। आज का स्ट्रीम शुरू'),
        ['सभी को नमस्कार।', 'आज का स्ट्रीम शुरू']);
  });

  group('length limit', () {
    test('splits at whitespace, else at the limit', () {
      final words = List.generate(200, (i) => 'word$i').join(' ');
      final segments = split(words);
      expect(segments.every((s) => s.length <= 300), isTrue);
      expect(segments.join(' '), words);
      expect(split('A' * 700), ['A' * 300, 'A' * 300, 'A' * 100]);
    });

    test('does not split a surrogate pair', () {
      final segments =
          const ClauseSplitter(maxLength: 5, minLetters: 0).split('abcd😀😀');
      expect(segments, ['abcd', '😀😀']);
    });

    test('does not merge tiny fragments past the limit', () {
      expect(
          const ClauseSplitter(maxLength: 20)
              .split('Hi, this clause is long enough.'),
          ['Hi,', 'this clause is long', 'enough.']);
    });
  });
}
