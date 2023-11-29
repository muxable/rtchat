import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rtchat/tts_plugin.dart';

class MockMethodChannel extends Mock implements MethodChannel {}

class MockTTSQueue extends Mock implements TTSQueue {
  @override
  Future<void> speak(String? id, String? text) =>
      super.noSuchMethod(Invocation.method(#speak, [id, text]),
          returnValue: Future.value());
}

void main() {
  final mockedTTSQueue = MockTTSQueue();

  group('TTSQueue', () {
    late TTSQueue ttsQueue;
    late MockMethodChannel mockChannel;

    setUp(() {
      mockChannel = MockMethodChannel();
      ttsQueue = TTSQueue(mockChannel);
    });

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
    });

    test('Delete removes the element by id', () async {
      ttsQueue.speak('1', 'First message');
      ttsQueue.speak('2', 'Second message');
      ttsQueue.delete('1');
      expect(ttsQueue.length, equals(1));
      expect(ttsQueue.peek(), equals({'id': '2', 'text': 'Second message'}));
    });

    test('Resolving speak from the mocked channel lines up the next message',
        () async {
      ttsQueue.speak('1', 'First message');
      ttsQueue.speak('2', 'Second message');

      when(mockedTTSQueue.speak(any, any)).thenAnswer((_) async {});

      await ttsQueue.speakNext();
      expect(ttsQueue.length, equals(1));
      expect(ttsQueue.peek(), equals({'id': '2', 'text': 'Second message'}));

      await ttsQueue.speakNext();
      expect(ttsQueue.isEmpty, isTrue);
    });
  });
}
