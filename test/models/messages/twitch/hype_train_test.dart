import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';

TwitchHypeTrainEventModel createHypeTrainModel(
    {required DateTime timestamp,
    required String messageId,
    required int level,
    required int progress,
    required int goal,
    required int total,
    bool isSuccessful = false,
    bool hasEnded = false}) {
  return TwitchHypeTrainEventModel(
      timestamp: timestamp,
      messageId: "channel.hype_train-$messageId",
      level: level,
      progress: progress,
      goal: goal,
      total: total,
      isSuccessful: isSuccessful,
      hasEnded: hasEnded);
}

Map<String, dynamic> createData(
    String id, int level, int progress, int goal, int total) {
  return {
    'event': {
      'id': id,
      'level': level,
      'progress': progress,
      'goal': goal,
      'total': total,
    }
  };
}

Map<String, dynamic> createEndData(int level, int total) {
  return {
    'event': {
      'level': level,
      'total': total,
    }
  };
}

void main() {
  group("parse progress events", () {
    test('progress event should return new event', () {
      final initialModel = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 2,
          progress: 123,
          goal: 200,
          total: 123);
      final expectedModel = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 2,
          progress: 126,
          goal: 200,
          total: 126);
      final data = createData('123', 2, 126, 200, 126);

      expect(initialModel.withProgress(data), expectedModel);
    });

    test('duplicate progress event should match initial event', () {
      final model = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 2,
          progress: 123,
          goal: 200,
          total: 123);
      final data = createData('123', 2, 123, 200, 123);

      expect(model.withProgress(data), model);
    });

    test('out of order progress event should match initial event', () {
      final model = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 2,
          progress: 123,
          goal: 200,
          total: 123);
      final data = createData('123', 2, 100, 200, 100);

      expect(model.withProgress(data), model);
    });
  });

  group("parse end events", () {
    test('unsuccessful lvl 5 end event should finalize as lvl 4 event', () {
      final model = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 5,
          progress: 123,
          goal: 200,
          total: 123);
      final expectedModel = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 4,
          progress: 123,
          goal: 200,
          total: 123,
          isSuccessful: true,
          hasEnded: true);
      final data = createEndData(5, 123);

      var withEnd = model.withEnd(data);
      expect(withEnd, expectedModel);
    });

    test('successful lvl 5 end event should finalize as lvl 5 event', () {
      final model = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 5,
          progress: 200,
          goal: 200,
          total: 200);
      final expectedModel = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 5,
          progress: 200,
          goal: 200,
          total: 200,
          isSuccessful: true,
          hasEnded: true);
      final data = createEndData(5, 200);

      var withEnd = model.withEnd(data);
      expect(withEnd, expectedModel);
    });

    test(
        'unsuccessful lvl 1 end event should finalize as unsuccesful lvl 1 event',
        () {
      final model = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 1,
          progress: 100,
          goal: 200,
          total: 100);
      final expectedModel = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 1,
          progress: 100,
          goal: 200,
          total: 100,
          isSuccessful: false,
          hasEnded: true);
      final data = createEndData(1, 100);

      var withEnd = model.withEnd(data);
      expect(withEnd, expectedModel);
    });

    test(
        'unsuccessful lvl 2 end event should finalize as successful lvl 2 event',
        () {
      final model = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 2,
          progress: 100,
          goal: 200,
          total: 100);
      final expectedModel = createHypeTrainModel(
          timestamp: DateTime.now(),
          messageId: '123',
          level: 1,
          progress: 100,
          goal: 200,
          total: 100,
          isSuccessful: true,
          hasEnded: true);
      final data = createEndData(2, 100);

      var withEnd = model.withEnd(data);
      expect(withEnd, expectedModel);
    });
  });
}
