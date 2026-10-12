import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/chat_history/separator.dart';

void main() {
  group('SeparatorWidget.formatDuration', () {
    test('seconds only', () {
      expect(SeparatorWidget.formatDuration(const Duration(seconds: 0)), '0s');
      expect(
          SeparatorWidget.formatDuration(const Duration(seconds: 42)), '42s');
    });

    test('minutes and seconds', () {
      expect(
          SeparatorWidget.formatDuration(const Duration(minutes: 3)), '3m0s');
      expect(
          SeparatorWidget.formatDuration(
              const Duration(minutes: 3, seconds: 7)),
          '3m7s');
    });

    test('hours always include minutes', () {
      expect(
          SeparatorWidget.formatDuration(const Duration(hours: 2, seconds: 5)),
          '2h0m5s');
    });

    test('days always include hours and minutes', () {
      expect(
          SeparatorWidget.formatDuration(const Duration(days: 1, minutes: 1)),
          '1d0h1m0s');
    });
  });
}
