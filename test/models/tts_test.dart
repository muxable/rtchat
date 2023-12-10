import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/tts_plugin.dart';

void main() {
  final ttsQueue = TTSQueue();

  test('Queue starts empty', () {
    expect(ttsQueue.isEmpty, isTrue);
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TextToSpeechPlugin.channel,
            (MethodCall method) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TextToSpeechPlugin.channel, null);
  });

  test('Speak adds elements to the queue', () async {
    final future1 = ttsQueue.speak('1', 'First message');
    expect(ttsQueue.isEmpty, isFalse);
    expect(ttsQueue.length, equals(1));
    await future1;

    final future2 = ttsQueue.speak('2', 'Second message');
    expect(ttsQueue.isEmpty, isFalse);
    expect(ttsQueue.length, equals(1));
    await future2;

    expect(ttsQueue.isEmpty, isTrue);
    expect(ttsQueue.length, equals(0));
  });

  test('Speak and clear empties the queue', () async {
    var calls = 0;
    final future1 = ttsQueue.speak('1', 'First message').catchError((e) {
      fail(
          'Should not have errored, can\'t clear the first element already in progress');
    });
    final future2 = ttsQueue.speak('2', 'Second message').catchError((e) {
      expect(e.toString(), equals("Exception: Message was deleted"));
      calls++;
    });
    await ttsQueue.clear();
    expect(ttsQueue.isEmpty, isTrue);
    await future1;
    await future2;
    expect(calls, equals(1));
  });

  test('Delete doesn\'t delete oof the front of the queue', () async {
    final future1 = ttsQueue.speak('1', 'First message');
    final future2 = ttsQueue.speak('2', 'Second message');

    ttsQueue.delete('1');

    expect(ttsQueue.length, equals(1));
    expect(ttsQueue.peek()!.id, equals('2'));
    await future1;
    await future2;
  });

  test('Delete deletes the second element', () async {
    var calls = 0;
    final future1 = ttsQueue.speak('1', 'First message');
    final future2 = ttsQueue.speak('2', 'Second message').catchError((e) {
      expect(e.toString(), equals("Exception: Message was deleted"));
      calls++;
    });

    ttsQueue.delete('2');

    expect(ttsQueue.length, equals(1));
    await future1;
    await future2;
    expect(calls, equals(1));
  });
}
