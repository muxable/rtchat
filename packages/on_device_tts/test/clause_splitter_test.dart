import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  const splitter = ClauseSplitter();
  List<String> split(String text) => splitter.split(text);

  group('clause boundaries', () {
    test('splits on clause punctuation followed by a space', () {
      expect(split('Hello chat, thanks for the follow! How is everyone?'), [
        'Hello chat,',
        'thanks for the follow!',
        'How is everyone?',
      ]);
      expect(split('first part; second part: third part. fourth part'), [
        'first part;',
        'second part:',
        'third part.',
        'fourth part',
      ]);
    });

    test('keeps text without punctuation whole', () {
      expect(split('Daisy said POGGERS that clutch was insane'),
          ['Daisy said POGGERS that clutch was insane']);
      expect(split('KEKW KEKW KEKW OMEGALUL'), ['KEKW KEKW KEKW OMEGALUL']);
    });

    test('splits the author prelude off a message', () {
      expect(split('Muxfd said: that was the cleanest clutch all week'),
          ['Muxfd said:', 'that was the cleanest clutch all week']);
    });

    test('returns nothing for empty or blank text', () {
      expect(split(''), isEmpty);
      expect(split('   \n\t '), isEmpty);
    });

    test('trims and keeps inner whitespace', () {
      expect(split('  hello   there,  general  kenobi  '),
          ['hello   there,', 'general  kenobi']);
    });

    test('does not split numbers', () {
      expect(split('the patch is 3.5 now, up from 3.4'),
          ['the patch is 3.5 now,', 'up from 3.4']);
      expect(split('we hit 1,000 followers at 10:30 tonight'),
          ['we hit 1,000 followers at 10:30 tonight']);
      expect(split(r'it costs $4.99 or 4,99 euros'),
          [r'it costs $4.99 or 4,99 euros']);
    });

    test('does not split hosts left from links', () {
      expect(split('check out example.com and clips.twitch.tv later'),
          ['check out example.com and clips.twitch.tv later']);
      expect(split('see https://example.com now'),
          ['see https://example.com now']);
    });

    test('keeps runs of punctuation together', () {
      expect(split('Oh my god!!! That was insane!!! What a play'),
          ['Oh my god!!!', 'That was insane!!!', 'What a play']);
      expect(split('Are you serious?! I cannot believe it'),
          ['Are you serious?!', 'I cannot believe it']);
    });

    test('treats ellipses as a pause', () {
      expect(split('I was thinking... maybe we should go back'),
          ['I was thinking...', 'maybe we should go back']);
      expect(split('I was thinking… maybe we should go back'),
          ['I was thinking…', 'maybe we should go back']);
      expect(
          split('wait...what happened there'), ['wait...what happened there']);
    });

    test('keeps closing quotes and brackets with their clause', () {
      expect(split('She yelled "watch out!" and then it exploded'),
          ['She yelled "watch out!"', 'and then it exploded']);
      expect(split('That boss (the second one.) was brutal'),
          ['That boss (the second one.)', 'was brutal']);
    });

    test('does not split after abbreviations or initials', () {
      expect(split('I talked to Dr. Smith about it yesterday'),
          ['I talked to Dr. Smith about it yesterday']);
      expect(split('bring snacks, e.g. chips and dip'),
          ['bring snacks,', 'e.g. chips and dip']);
      expect(split('J. R. R. Tolkien wrote that book'),
          ['J. R. R. Tolkien wrote that book']);
      expect(split('Team A vs. Team B starts soon'),
          ['Team A vs. Team B starts soon']);
    });

    test('does not split emoticons', () {
      expect(split('thanks for the raid :) see you next time'),
          ['thanks for the raid :) see you next time']);
      expect(split('so good ;] really'), ['so good ;] really']);
    });
  });

  group('tiny fragments', () {
    test('join the next clause', () {
      expect(split('Hi, how is everyone doing today?'),
          ['Hi, how is everyone doing today?']);
      expect(split('lol, ok, that was actually pretty funny'),
          ['lol, ok, that was actually pretty funny']);
    });

    test('join the previous clause at the end', () {
      expect(split('That was such a clean clutch, GG!'),
          ['That was such a clean clutch, GG!']);
      expect(split('I cannot believe that happened. lol'),
          ['I cannot believe that happened. lol']);
    });

    test('stay alone when they are the whole text', () {
      expect(split('GG!'), ['GG!']);
      expect(split('!!!'), ['!!!']);
      expect(split('LUL'), ['LUL']);
    });

    test('count letters and digits, not punctuation', () {
      expect(split('Thanks! Welcome in everyone'),
          ['Thanks!', 'Welcome in everyone']);
      expect(split('Oh!!!!!!!! Welcome in everyone'),
          ['Oh!!!!!!!! Welcome in everyone']);
    });

    test('respect minLetters', () {
      expect(const ClauseSplitter(minLetters: 0).split('Hi, there.'),
          ['Hi,', 'there.']);
      expect(
          const ClauseSplitter(minLetters: 100)
              .split('Hello chat, how are you?'),
          ['Hello chat, how are you?']);
    });
  });

  group('length limit', () {
    test('splits a long clause at whitespace', () {
      final words = List.generate(200, (i) => 'word$i').join(' ');
      final segments = split(words);
      expect(segments.length, greaterThan(1));
      for (final segment in segments) {
        expect(segment.length, lessThanOrEqualTo(300));
      }
      expect(segments.join(' '), words);
    });

    test('splits text without whitespace at the limit', () {
      final spam = 'A' * 700;
      expect(split(spam), ['A' * 300, 'A' * 300, 'A' * 100]);
    });

    test('does not split a surrogate pair', () {
      const splitter = ClauseSplitter(maxLength: 5, minLetters: 0);
      final segments = splitter.split('abcd😀😀');
      expect(segments.join(), 'abcd😀😀');
      for (final segment in segments) {
        expect(segment.length, lessThanOrEqualTo(5));
        expect(segment.runes.every((r) => r < 0xD800 || r > 0xDFFF), isTrue);
      }
    });

    test('does not merge past the limit', () {
      const splitter = ClauseSplitter(maxLength: 20, minLetters: 6);
      expect(splitter.split('Hi, this clause is long enough.'),
          ['Hi,', 'this clause is long', 'enough.']);
    });

    test('keeps every clause of a long multi-clause message', () {
      final text =
          List.generate(40, (i) => 'this is clause number $i,').join(' ');
      final segments = split(text);
      expect(segments, hasLength(40));
      expect(segments.join(' '), text);
    });
  });

  group('CJK and other scripts', () {
    test('splits Japanese without spaces and joins without adding any', () {
      expect(split('こんにちは皆さん、今日の配信へようこそ。楽しんでいってください！'),
          ['こんにちは皆さん、', '今日の配信へようこそ。', '楽しんでいってください！']);
    });

    test('merges short CJK clauses without adding spaces', () {
      expect(split('はい、今日もよろしくお願いします。'), ['はい、今日もよろしくお願いします。']);
    });

    test('splits Korean and Chinese', () {
      expect(split('안녕하세요 여러분, 오늘 방송에 오신 것을 환영합니다!'),
          ['안녕하세요 여러분,', '오늘 방송에 오신 것을 환영합니다!']);
      expect(split('大家好，欢迎来到今天的直播！谢谢大家的关注哦'), ['大家好，欢迎来到今天的直播！', '谢谢大家的关注哦']);
    });

    test('splits Arabic and Hindi punctuation', () {
      expect(split('مرحبا بالجميع، شكرا على المتابعة'),
          ['مرحبا بالجميع،', 'شكرا على المتابعة']);
      expect(split('सभी को नमस्कार। आज का स्ट्रीम शुरू'),
          ['सभी को नमस्कार।', 'आज का स्ट्रीम शुरू']);
    });

    test('keeps CJK segments within a smaller limit', () {
      const splitter = ClauseSplitter(maxLength: 120);
      final text = 'あ' * 250;
      final segments = splitter.split(text);
      expect(segments.map((s) => s.length), [120, 120, 10]);
    });
  });

  test('emoji and emote-only messages stay whole', () {
    expect(split('PogChamp 🔥🔥🔥 PogChamp'), ['PogChamp 🔥🔥🔥 PogChamp']);
  });
}
