import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/tts_plugin.dart';

void main() {
  const channel = MethodChannel('tts_plugin');
  final ttsQueue = TTSQueue();

  test('Queue starts empty', () {
    expect(ttsQueue.isEmpty, isTrue);
  });

  test('Speak adds elements to the queue', () async {
    ttsQueue.speak('1', 'First message');
    ttsQueue.speak('2', 'Second message');
    await ttsQueue.speakNext();
    expect(ttsQueue.isEmpty, isFalse);
    expect(ttsQueue.length, equals(1));
  });

  test('Speak and clear empties the queue', () async {
    ttsQueue.speak('1', 'First message');
    ttsQueue.speak('2', 'Second message');
    await ttsQueue.clear();
    expect(ttsQueue.isEmpty, isTrue);
  });

  test('SpeakNext removes the first element from the queue', () async {
    ttsQueue.speak('1', 'First message');
    ttsQueue.speak('2', 'Second message');
    await ttsQueue.speakNext();
    expect(ttsQueue.length, equals(1));
    expect(ttsQueue.peek(), equals({'id': '2', 'text': 'Second message'}));
    ttsQueue.clear();
  });

  test('Delete removes the element by id', () async {
    ttsQueue.speak('1', 'First message');
    ttsQueue.speak('2', 'Second message');
    await ttsQueue.delete('1');
    expect(ttsQueue.length, equals(1));
    expect(ttsQueue.peek(), equals({'id': '2', 'text': 'Second message'}));
    ttsQueue.clear();
  });

  test('Resolving speak from the mocked channel lines up the next message',
      () async {
    var callCount = 0;
    handler(MethodCall methodCall) async {
      if (methodCall.method == 'speak') {
        callCount++;
        return null;
      }
      return null;
    }

    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);

    expect(callCount, 0);

    ttsQueue.speak('1', 'First message');
    ttsQueue.speak('2', 'Second message');
    await ttsQueue.speakNext();
    expect(ttsQueue.length, equals(1));
    expect(callCount, 1);
    expect(ttsQueue.length, equals(1));
    await ttsQueue.speakNext();
    expect(callCount, 2);
    expect(ttsQueue.length, equals(0));
  });
}
